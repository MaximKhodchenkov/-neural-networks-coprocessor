/*
 * Module: NN_layer_core
 * Author: Khodchenkov Maxim
 * Date: April 1, 2023
 *
 * Description: 
 *
*/
module  NN_layer_core#(
  parameter DATA_WIDTH = 32,
  // Width of address bus in bits
  parameter ADDR_WIDTH = 32,
  // Width of wstrb (width of data bus in words)
  parameter STRB_WIDTH = (DATA_WIDTH/8),
  parameter NUMBER_NEURON = 10  

) (  
  input clk,
  input rst,

  // -- Control Path ------------------------------------------
  input                     flag_of_last_layer,  
  input                     load_settings_and_weights,
  input    [ADDR_WIDTH-1:0] base_addr_W,
  input       byte unsigned number_of_inputs,
  output              logic all_load_W_complite = 0,
  // ---------------------------------------------------------- 

  
  // -- Data Patch --------------------------------------------
  // -- Pipeline NN: input - neurons of the previous layer
  //                 output - calculated neurons to the next layer
  // input simplified AXIS
  input  logic [DATA_WIDTH - 1:0] rx_tdata, 
  input  logic                    rx_tvalid, 
  input  logic                    rx_tlast, 
  output logic                    rx_tready,
  // output simplified AXIS
  output logic [DATA_WIDTH - 1:0] tx_tdata, 
  output logic                    tx_tvalid, 
  output logic                    tx_tlast, 
  input  logic                    tx_tready,
  // ----------------------------------------------------------  


  // AXI lite master interfaces for memory with W ----------   
  output logic [ADDR_WIDTH-1:0]      to_RAM_axi_awaddr  ,
  output logic [7:0]                 to_RAM_axi_awlen   ,
  output logic [2:0]                 to_RAM_axi_awsize  ,
  output logic [1:0]                 to_RAM_axi_awburst ,
  output logic [2:0]                 to_RAM_axi_awprot  ,
  output logic                       to_RAM_axi_awvalid ,
  input  logic                       to_RAM_axi_awready ,
  output logic [DATA_WIDTH-1:0]      to_RAM_axi_wdata   ,
  output logic [STRB_WIDTH-1:0]      to_RAM_axi_wstrb   ,
  output logic                       to_RAM_axi_wvalid  ,
  input  logic                       to_RAM_axi_wready  ,
  input  logic [1:0]                 to_RAM_axi_bresp   ,
  input  logic                       to_RAM_axi_bvalid  ,
  output logic                       to_RAM_axi_bready  ,
  output logic [ADDR_WIDTH-1:0]      to_RAM_axi_araddr  ,
  output logic [7:0]                 to_RAM_axi_arlen   ,
  output logic [2:0]                 to_RAM_axi_arsize  ,
  output logic [1:0]                 to_RAM_axi_arburst ,
  output logic [2:0]                 to_RAM_axi_arprot  ,
  output logic                       to_RAM_axi_arvalid ,
  input  logic                       to_RAM_axi_arready ,
  input  logic [DATA_WIDTH-1:0]      to_RAM_axi_rdata   ,
  input  logic [1:0]                 to_RAM_axi_rresp   ,
  input  logic                       to_RAM_axi_rvalid  ,
  output logic                       to_RAM_axi_rready   
// ----------------------------------------------------------  
);

byte unsigned number_of_inputs_reg;

logic [ADDR_WIDTH - 1:0]                    base_addr_W_for_layer;
logic [ADDR_WIDTH * NUMBER_NEURON - 1 : 0]  base_addr_W_for_neuron;
logic load_weights = 0;
logic [NUMBER_NEURON - 1 : 0] all_W_load;
logic [NUMBER_NEURON - 1 : 0] rx_tready_from_neuron;
logic [NUMBER_NEURON - 1 : 0] outputs_neurons_caclulated;
logic                         ready_to_receive_calculated_neurons = 0;
// Core ready to get new word from last layer when all neuron ready
assign rx_tready = &rx_tready_from_neuron;

generate
  genvar n;
  for (n = 0; n < NUMBER_NEURON; n = n + 1) begin
    Neuron #(
      .DATA_WIDTH     (DATA_WIDTH),
      .ADDR_WIDTH     (ADDR_WIDTH),
    ) 
    Neuron_inst(
      .clk             (clk),
      .rst             (rst),

      // Control Path -----------------------------------------------------------------
      .load_weights     (load_weights),           //input                     
      .base_addr_W      (base_addr_W_for_neuron [n * ADDR_WIDTH +: ADDR_WIDTH)], //input 
      .number_of_inputs (number_of_inputs_reg),   //input 
      .load_W_complite  (all_W_load[n]),          //output
      // ------------------------------------------------------------------------------

      // input from the previous layer ------------------------------------------------
      .rx_tdata         (rx_tdata ), 
      .rx_tvalid        (rx_tvalid),
      .rx_tlast         (rx_tlast ), 
      .rx_tready        (rx_tready_from_neuron[n]),
      // ------------------------------------------------------------------------------

      // transmitting the calculated data to the kernel
      .data_out         (neurons_current_layer[n * DATA_WIDTH +: DATA_WIDTH]),
      .data_out_valid   (outputs_neurons_caclulated[n]),   
      .ready_in         (ready_to_receive_calculated_neurons), 
      // ------------------------------------------------------------------------------


      // axi ram with "W"
//    .m_axi_awaddr     (from_neuron_axi_awaddr  [n * ADDR_WIDTH +: ADDR_WIDTH]),    
//    .m_axi_awlen      (from_neuron_axi_awlen   [n * 8 +: 8]),    
//    .m_axi_awsize     (from_neuron_axi_awsize  [n * 3 +: 3]),    
//    .m_axi_awburst    (from_neuron_axi_awburst [n * 2 +: 2]),    
//    .m_axi_awprot     (from_neuron_axi_awprot  [n * 3 +: 3]),    
//    .m_axi_awvalid    (from_neuron_axi_awvalid [n]),    
//    .m_axi_awready    (from_neuron_axi_awready [n]),    
//    .m_axi_wdata      (from_neuron_axi_wdata   [n * DATA_WIDTH +: DATA_WIDTH]),    
//    .m_axi_wstrb      (from_neuron_axi_wstrb   [n * STRB_WIDTH +: STRB_WIDTH]),    
//    .m_axi_wvalid     (from_neuron_axi_wvalid  [n]),    
//    .m_axi_wready     (from_neuron_axi_wready  [n]),    
//    .m_axi_bresp      (from_neuron_axi_bresp   [n * 2 +: 2]),    
//    .m_axi_bvalid     (from_neuron_axi_bvalid  [n]),    
//    .m_axi_bready     (from_neuron_axi_bready  [n]),  

      .m_axi_araddr     (from_neuron_axi_araddr  [n * ADDR_WIDTH +: ADDR_WIDTH]),      
      .m_axi_arlen      (from_neuron_axi_arlen   [n * 8 +: 8]),    
      .m_axi_arsize     (from_neuron_axi_arsize  [n * 3 +: 3]),    
      .m_axi_arburst    (from_neuron_axi_arburst [n * 2 +: 2]),    
      .m_axi_arprot     (from_neuron_axi_arprot  [n * 3 +: 3]),    
      .m_axi_arvalid    (from_neuron_axi_arvalid [n]),    
      .m_axi_arready    (from_neuron_axi_arready [n]),    
      .m_axi_rdata      (from_neuron_axi_rdata   [n * DATA_WIDTH +: DATA_WIDTH]),    
      .m_axi_rresp      (from_neuron_axi_rresp   [n * 2 +: 2]),    
      .m_axi_rvalid     (from_neuron_axi_rvalid  [n]),    
      .m_axi_rready     (from_neuron_axi_rready  [n])
    )
  end
endgenerate



logic [NUMBER_NEURON * ADDR_WIDTH-1:0]   from_neuron_axi_awaddr      ; 
logic [NUMBER_NEURON * 8 - 1:0]          from_neuron_axi_awlen       ;
logic [NUMBER_NEURON * 3 - 1:0]          from_neuron_axi_awsize      ;
logic [NUMBER_NEURON * 2 - 1:0]          from_neuron_axi_awburst     ;
logic [NUMBER_NEURON * 3 - 1:0]          from_neuron_axi_awprot      ;  
logic [NUMBER_NEURON - 1:0]              from_neuron_axi_awvalid     ;
logic [NUMBER_NEURON - 1:0]              from_neuron_axi_awready     ;
logic [NUMBER_NEURON * DATA_WIDTH-1:0]   from_neuron_axi_wdata       ;
logic [NUMBER_NEURON * STRB_WIDTH-1:0]   from_neuron_axi_wstrb       ;
logic [NUMBER_NEURON - 1:0]              from_neuron_axi_wvalid      ;
logic [NUMBER_NEURON - 1:0]              from_neuron_axi_wready      ;
logic [NUMBER_NEURON * 2 - 1:0]          from_neuron_axi_bresp       ;
logic [NUMBER_NEURON - 1:0]              from_neuron_axi_bvalid      ;
logic [NUMBER_NEURON - 1:0]              from_neuron_axi_bready      ;
logic [NUMBER_NEURON * ADDR_WIDTH-1:0]   from_neuron_axi_araddr      ;  
logic [NUMBER_NEURON * 8 - 1:0]          from_neuron_axi_arlen       ;
logic [NUMBER_NEURON * 3 - 1:0]          from_neuron_axi_arsize      ;
logic [NUMBER_NEURON * 2 - 1:0]          from_neuron_axi_arburst     ;
logic [NUMBER_NEURON * 3 - 1:0]          from_neuron_axi_arprot      ;
logic [NUMBER_NEURON - 1:0]              from_neuron_axi_arvalid     ;
logic [NUMBER_NEURON - 1:0]              from_neuron_axi_arready     ;
logic [NUMBER_NEURON * DATA_WIDTH-1:0]   from_neuron_axi_rdata       ;
logic [NUMBER_NEURON * 2 - 1:0]          from_neuron_axi_rresp       ;
logic [NUMBER_NEURON - 1:0]              from_neuron_axi_rvalid      ;
logic [NUMBER_NEURON - 1:0]              from_neuron_axi_rready      ;

axi_interconnect_inst (
  .clk                                  (clk                        ),
  .rst                                  (rst                        ),
  .s_axi_awaddr                         (from_neuron_axi_awaddr     ),
  .s_axi_awlen                          (from_neuron_axi_awlen      ),
  .s_axi_awsize                         (from_neuron_axi_awsize     ),
  .s_axi_awburst                        (from_neuron_axi_awburst    ),
  .s_axi_awprot                         (from_neuron_axi_awprot     ),
  .s_axi_awvalid                        (from_neuron_axi_awvalid    ),
  .s_axi_awready                        (from_neuron_axi_awready    ),
  .s_axi_wdata                          (from_neuron_axi_wdata      ),
  .s_axi_wstrb                          (from_neuron_axi_wstrb      ),
  .s_axi_wvalid                         (from_neuron_axi_wvalid     ),
  .s_axi_wready                         (from_neuron_axi_wready     ),
  .s_axi_bresp                          (from_neuron_axi_bresp      ),
  .s_axi_bvalid                         (from_neuron_axi_bvalid     ),
  .s_axi_bready                         (from_neuron_axi_bready     ),
  .s_axi_araddr                         (from_neuron_axi_araddr     ),
  .s_axi_arprot                         (from_neuron_axi_arprot     ),
  .s_axi_arlen                          (from_neuron_axi_arlen      ),
  .s_axi_arsize                         (from_neuron_axi_arsize     ),
  .s_axi_arburst                        (from_neuron_axi_arburst    ),
  .s_axi_arvalid                        (from_neuron_axi_arvalid    ),
  .s_axi_arready                        (from_neuron_axi_arready    ),
  .s_axi_rdata                          (from_neuron_axi_rdata      ),
  .s_axi_rresp                          (from_neuron_axi_rresp      ),
  .s_axi_rvalid                         (from_neuron_axi_rvalid     ),
  .s_axi_rready                         (from_neuron_axi_rready     ),
  
  .m_axi_awaddr                         (m_axi_awaddr               ),
  .m_axi_awlen                          (m_axi_awlen                ),
  .m_axi_awsize                         (m_axi_awsize               ),
  .m_axi_awburst                        (m_axi_awburst              ),
  .m_axi_awprot                         (m_axi_awprot               ),
  .m_axi_awvalid                        (m_axi_awvalid              ),
  .m_axi_awready                        (m_axi_awready              ),
  .m_axi_wdata                          (m_axi_wdata                ),
  .m_axi_wstrb                          (m_axi_wstrb                ),
  .m_axi_wvalid                         (m_axi_wvalid               ),
  .m_axi_wready                         (m_axi_wready               ),
  .m_axi_bresp                          (m_axi_bresp                ),
  .m_axi_bvalid                         (m_axi_bvalid               ),
  .m_axi_bready                         (m_axi_bready               ),
  .m_axi_araddr                         (m_axi_araddr               ),
  .m_axi_arprot                         (m_axi_arprot               ),
  .m_axi_arlen                          (m_axi_arlen                ),
  .m_axi_arsize                         (m_axi_arsize               ),
  .m_axi_arburst                        (m_axi_arburst              ),
  .m_axi_arvalid                        (m_axi_arvalid              ),
  .m_axi_arready                        (m_axi_arready              ),
  .m_axi_rdata                          (m_axi_rdata                ),
  .m_axi_rresp                          (m_axi_rresp                ),
  .m_axi_rvalid                         (m_axi_rvalid               ),
  .m_axi_rready                         (m_axi_rready               )
);
  
logic                  flag_of_last_layer_reg;                      


// declaration FSM control path -------------------------------------------------------------
typedef enum logic [1:0] {IDLe_state, Calculate_addrs_state, Load_W_state, Active_state} FSM_t;
FSM_t current_state  = IDLe_state;
FSM_t next_state     = IDLe_state;

always_comb begin
  if (rst) current_state = IDLe_state;
  else     current_state = next_state;
end
// -----------------------------------------------------------------------------------------

// declaration FSM transmission data -------------------------------------------------------
typedef enum logic [1:0] {IDLe_state, Calculate_addrs_state, Load_W_state, Active_state} FSM_tx_t;
FSM_tx_t Tx_data_to_next_layer_current_state  = Wait_calc_neurons;
FSM_tx_t Tx_data_to_next_layer_next_state     = Wait_calc_neurons;

always_comb begin
  if (rst) Tx_data_to_next_layer_current_state = Wait_calc_neurons;
  else     Tx_data_to_next_layer_current_state = Tx_data_to_next_layer_next_state;
end
// -----------------------------------------------------------------------------------------


// -----------------------------------------------------------------------------------------
// -- Control path -------------------------------------------------------------------------
always_ff @(posedge clk) begin : Control_path
  case (current_state)
    IDLe_state: begin
      tx_tvalid <= 0;
      ready_to_receive_calculated_neurons <= 0;
      ready_get_command_load_W <= 1;
      if (load_settings_and_weights) begin
          ready_get_command_load_W <= 0;
          base_addr_W_for_layer  <= base_addr_W_in;
          flag_of_last_layer_reg <= flag_of_last_layer;
          number_of_inputs_reg   <= number_of_inputs;
          next_state             <= Calculate_addrs_state; // FSM -->       
        end
      end

    Calculate_addrs_state: begin
      for (int i = 0; i < NUMBER_NEURON; i++) begin
        base_addr_W_for_neuron[i * ADDR_WIDTH:+ ADDR_WIDTH] <= base_addr_W_in + number_of_inputs_reg * (i + 1);        
      end
        load_weights <= 1;
        next_state   <= Load_W_state; // FSM --> 
    end

    Load_W_state: begin 
      if (&all_W_load) begin 
        next_state                        <= Active_state; // FSM --> 
        Tx_data_to_next_layer_next_state  <= Wait_calc_neurons;
        all_load_W_complite <= 1;
      end
    end


    Active_state: begin
      ready_get_command_load_W <= 1;
// ------------------------------------------------------------------------------------
// -- FSM transfer of computed neurons ------------------------------------------------
      case (Tx_data_to_next_layer_current_state)
        Wait_calc_neurons: begin 
          ready_to_receive_calculated_neurons <= 1;
          if (&outputs_neurons_caclulated) begin 
            Tx_data_to_next_layer_next_state <= Tx_neurons;
            neurons_current_layer_reg        <= neurons_current_layer; // save
            tx_tvalid <= 1;
            tx_cnt    <= 0;
          ready_to_receive_calculated_neurons <= 0;            
          end 
        end
        Tx_neurons: begin
          tx_tvalid <= 1;  
          if (tx_tready) begin
            // see line ".." of the code
            // assign tx_data = neurons_current_layer[DATA_WIDTH - 1:0];
            neurons_current_layer <= neurons_current_layer >> DATA_WIDTH;
            tx_cnt <= tx_cnt + 1;
             
            if (tx_cnt == NUMBER_NEURON - 2) tx_tlast <= 1;              
            else if (tx_cnt == NUMBER_NEURON - 1) begin 
              tx_tlast      <= 0;
              tx_tx_tvalid  <= 0;
              Tx_data_to_next_layer_next_state  <= Wait_calc_neurons;
            end 
          end

        end
        default: 
      endcase
// ------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------
      
      all_load_W_complite <= 0;
      if (load_settings_and_weights) begin 
          base_addr_W_for_layer  <= base_addr_W_in;
          flag_of_last_layer_reg <= flag_of_last_layer;
          number_of_inputs_reg   <= number_of_inputs;
          next_state             <= Calculate_addrs_state; // FSM -->       
      end
    end
    
    default: 
  endcase
end

assign tx_data = neurons_current_layer[DATA_WIDTH - 1:0];

endmodule