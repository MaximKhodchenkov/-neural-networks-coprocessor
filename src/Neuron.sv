/*
 * Module: Neuron
 * Author: Khodchenkov Maxim
 * Date: April 1, 2023
 *
 * Description: 
 *
*/
module  Neuron #(
  parameter DATA_WIDTH = 32,
  // Width of address bus in bits
  parameter ADDR_WIDTH = 32,
  // Width of wstrb (width of data bus in words)
  parameter STRB_WIDTH = (DATA_WIDTH/8)


) (  
  input clk,
  input rst,

// Control Path -----------------------------------------
  input                              load_weights       ,                          
  input        [ADDR_WIDTH-1:0]      base_addr_W        ,
  input  byte unsigned               number_of_inputs   ,
  output logic                       load_W_complite = 0,
//-------------------------------------------------------
 
// input neuron from last layer -------------------------
// simplified AXIS
  input        [DATA_WIDTH - 1:0]    rx_tdata           , 
  input                              rx_tvalid          , 
  input                              rx_tlast           , 
  output logic                       rx_tready = 0      ,
//-------------------------------------------------------

// transmitting the calculated data to the kernel -------
  output logic [DATA_WIDTH - 1:0]    data_out           ,
  output logic                       data_out_valid = 0 ,
  input                              ready_in           ,
// ------------------------------------------------------

// AXI lite master interfaces for memory with W ---------
//output logic [ADDR_WIDTH-1:0]      m_axi_awaddr       ,
//output logic [7:0]                 m_axi_awlen        ,
//output logic [2:0]                 m_axi_awsize       ,
//output logic [1:0]                 m_axi_awburst      ,
//output logic [2:0]                 m_axi_awprot       ,
//output logic                       m_axi_awvalid      ,
//input                              m_axi_awready      ,
//output logic [DATA_WIDTH-1:0]      m_axi_wdata        ,
//output logic [STRB_WIDTH-1:0]      m_axi_wstrb        ,
//output logic                       m_axi_wvalid       ,
//input                              m_axi_wready       ,
//input        [1:0]                 m_axi_bresp        ,
//input                              m_axi_bvalid       ,
//output logic                       m_axi_bready       ,
  output logic [ADDR_WIDTH-1:0]      m_axi_araddr       ,
  output logic [7:0]                 m_axi_arlen        ,
  output logic [2:0]                 m_axi_arsize       ,
  output logic [1:0]                 m_axi_arburst      ,
  output logic [2:0]                 m_axi_arprot       ,
  output logic                       m_axi_arvalid = 0  ,
  input                              m_axi_arready      ,
  input        [DATA_WIDTH-1:0]      m_axi_rdata        ,
  input        [1:0]                 m_axi_rresp        ,
  input                              m_axi_rvalid  = 0  ,
  output logic                       m_axi_rready   
//-------------------------------------------------------

);

logic [DATA_WIDTH - 1:0] mem_W [256]; // memory of weights 
logic [DATA_WIDTH - 1:0] data_from_mem_W;
assign data_from_mem_W = mem_W[addr_rd_mem_W];

logic signed [31:0] operand_1, operand_2; 
logic signed [31:0] result_mult;
assign operand_1 = $signed(rx_tdata);
assign operand_2 = $signed(data_from_mem_W);

sig_fract_mult (
  .POINT_POSITION (POINT_POSITION    ) 
)
sig_fract_mult_inst(
  .a              ($signed(operand_1)),
  .b              ($signed(operand_2)),
  .result         (result_mult       )
  )

// FSM Data processing -----------------------------------------------
typedef enum logic [1:0] {IDLe, Processing, Sigmoid, Save_result} FSM_t;
FSM_t current_state = IDLe_state; 
FSM_t next_state = IDLe_state;

always_comb begin
  if (rst) current_state = IDLe_state;
  else     current_state = next_state;
end

logic signed [DATA_WIDTH:0] acc_sum     = 0;
logic signed [DATA_WIDTH:0] reg_acc_sum = 0;

always_ff @(clk) begin
  if (rst) acc_sum <= 0;
  case (current_state)

    IDLe: begin
      data_out_valid  <= 0;
      rx_tready       <= 1;
      acc_sum         <= 0;
      addr_rd_mem_W   <= 0;      
      if (rx_tvalid) begin
        addr_rd_mem_W   <= 1;
        acc_sum         <= result_mult;        
        next_state      <= Processing;
        end
      end
    
    Processing: begin
      if (rx_tvalid) begin
        addr_rd_mem_W   <= addr_rd_mem_W + 1;
        acc_sum         <= result_mult + acc_sum;        
        if (rx_tlast) begin 
          next_state  <= Sigmoid;
          rx_tready   <= 0;
        end
      end
    end      

    Sigmoid: begin
      sigmoid_x   <= acc_sum;
      next_state  <= Save_result;
    end  

    Save_result: begin
      data_out       <= sigmoid_y;
      data_out_valid <= 1;
      if (ready_in) next_state <= IDLe;  
    end
  endcase

end

  sigmoid sigmoid_inst (
    .x(sigmoid_x),
    .y(sigmoid_y)
  );

// ------------------------------------------------------------------------------------------
// -- BEGIN: logic of reading and writing weights to memory ---------------------------------
// -- declaration FSM control path ----------------------------------------------------------
typedef enum logic [1:0] {IDLe, Addr_and_control, Read_data} FSM_t;
FSM_t current_state_rd_AXI_RAM = IDLe;
FSM_t next_state_rd_AXI_RAM    = IDLe;

always_comb begin
  if (rst) current_state_rd_AXI_RAM = IDLe;
  else     current_state_rd_AXI_RAM = next_state_rd_AXI_RAM;
end
// ------------------------------------------------------------------------------------------

// FSM reading and writing weights to memory ------------------------------------------------ 
always_ff @(posedge clk) begin
  case (current_state_rd_AXI_RAM)
    IDLe: begin
      m_axi_rready  <= 0;
      m_axi_arvalid <= 0;
      if (load_weights) begin
        load_W_complite       <= 0;             
        next_state_rd_AXI_RAM <= Addr_and_control;      
        m_axi_arvalid <= 1;
        m_axi_araddr  <= base_addr_W; 
        m_axi_arlen   <= number_of_inputs;
        m_axi_araddr  <= base_addr_W;      
        m_axi_arsize  <= 3'b010; // 32 bits
        m_axi_arprot  <= 3'b000;  
      end
    end

    Addr_and_control: begin
      if (m_axi_arready) begin 
        m_axi_arvalid    <= 0; 
        next_state_rd_AXI_RAM <= Read_data;
      end
      addr_wr_ram <= 0;
    end

    Read_data: begin
      m_axi_rready <= 1;
      if (m_axi_rvalid) begin
        mem_W[addr_wr_ram] <= m_axi_rdata;
        addr_wr_ram        <= addr_wr_ram + 1;
        if (addr_wr_ram == m_axi_arlen - 1) begin
          m_axi_rready          <= 0;
          next_state_rd_AXI_RAM <= IDLe;
          load_W_complite       <= 1;     
        end    
      end
    end
    default:
  endcase
end

// -- END: logic of reading and writing weights to memory -----------------------------------
// ------------------------------------------------------------------------------------------


endmodule