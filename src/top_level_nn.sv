/*
 * Module: top_level_nn
 * Author: Khodchenkov Maxim
 * Date: April 1, 2023
 *
 * Description: 
 *
*/
module top_level_nn  #(
  parameter DATA_WIDTH = 32,
  // Width of address bus in bits
  parameter ADDR_WIDTH = 32,
  // Width of wstrb (width of data bus in words)
  parameter STRB_WIDTH = (DATA_WIDTH/8),
  parameter NUMBERS_NEURONS = {10, 3},
  parameter NUMBER_LAYER  = 2, 
  parameter NUMBER_OF_INPUTS = 49
  )(
  input clk,
  input rst,
    // input simplified AXIS
  input [DATA_WIDTH - 1:0]        rx_tdata, 
  input                           rx_tvalid, 
  input                           rx_tlast, 
  output logic                    rx_tready,

    // output simplified AXIS
  output logic [DATA_WIDTH - 1:0] tx_tdata, 
  output logic                    tx_tvalid, 
  output logic                    tx_tlast, 
  input                           tx_tready,

  input                           start_Load_W,
  output logic                    nn_ready = 0
);
  
localparam MAX_NEURON_IN_LAYER = 256; // do not change!!
localparam N_BIT_IN_BYTE = 8;

logic [NUMBER_CORE * ADDR_WIDTH-1:0]      from_cores_axi_awaddr   ; 
logic [NUMBER_CORE * 8 - 1:0]             from_cores_axi_awlen    ;
logic [NUMBER_CORE * 3 - 1:0]             from_cores_axi_awsize   ;
logic [NUMBER_CORE * 2 - 1:0]             from_cores_axi_awburst  ;
logic [NUMBER_CORE * 3 - 1:0]             from_cores_axi_awprot   ;  
logic [NUMBER_CORE - 1:0]                 from_cores_axi_awvalid  ;   
logic [NUMBER_CORE - 1:0]                 from_cores_axi_awready  ;
logic [NUMBER_CORE * DATA_WIDTH-1:0]      from_cores_axi_wdata    ;
logic [NUMBER_CORE * STRB_WIDTH-1:0]      from_cores_axi_wstrb    ;
logic [NUMBER_CORE - 1:0]                 from_cores_axi_wvalid   ;
logic [NUMBER_CORE - 1:0]                 from_cores_axi_wready   ;
logic [NUMBER_CORE * 2 - 1:0]             from_cores_axi_bresp    ;
logic [NUMBER_CORE - 1:0]                 from_cores_axi_bvalid   ;
logic [NUMBER_CORE - 1:0]                 from_cores_axi_bready   ;
logic [NUMBER_CORE * ADDR_WIDTH-1:0]      from_cores_axi_araddr   ;  
logic [NUMBER_CORE * 8 - 1:0]             from_cores_axi_arlen    ;
logic [NUMBER_CORE * 3 - 1:0]             from_cores_axi_arsize   ;
logic [NUMBER_CORE * 2 - 1:0]             from_cores_axi_arburst  ;
logic [NUMBER_CORE * 3 - 1:0]             from_cores_axi_arprot   ;
logic [NUMBER_CORE - 1:0]                 from_cores_axi_arvalid  ;
logic [NUMBER_CORE - 1:0]                 from_cores_axi_arready  ;
logic [NUMBER_CORE * DATA_WIDTH-1:0]      from_cores_axi_rdata    ;
logic [NUMBER_CORE * 2 - 1:0]             from_cores_axi_rresp    ;
logic [NUMBER_CORE - 1:0]                 from_cores_axi_rvalid   ;
logic [NUMBER_CORE - 1:0]                 from_cores_axi_rready   ;

logic [NUMBER_LAYER * DATA_WIDTH - 1:0]   tdata_hid_core          ;
logic [NUMBER_LAYER - 1:0]                tvalid_hid_core         ;
logic [NUMBER_LAYER - 1:0]                tlast_hid_core          ;
logic [NUMBER_LAYER - 1:0]                tready_hid_core         ;


logic [NUMBER_LAYER - 1:0] load_weights;
logic [NUMBER_LAYER - 1:0] all_load_W_complite;
logic [NUMBER_LAYER * ADDR_WIDTH - 1:0] base_addr_W;
logic [NUMBER_LAYER * 8 - 1:0] number_of_inputs;
generate
  genvar n;
  for (n = 0; n < NUMBER_LAYER; n = n + 1) begin

    if (n == 0) begin 

      NN_layer_core #(
        .DATA_WIDTH     (DATA_WIDTH),
        .ADDR_WIDTH     (ADDR_WIDTH),
        .NUMBER_NEURON  (NUMBERS_NEURONS[n])
      ) 
      NN_layer_core(
        .clk                        (clk),
        .rst                        (rst),

        // -- Control Path -----------------------------------------------------------------
        .flag_of_last_layer         (1'b0),  
        .load_settings_and_weights  (load_weights[n]),
        .base_addr_W                (base_addr_W[n * ADDR_WIDTH +: ADDR_WIDTH]),
        .number_of_inputs           (number_of_inputs[n * 8 +: 8]),
        .all_load_W_complite        (all_load_W_complite[n]),
        // --------------------------------------------------------------------------------- 

        // -- Data Patch -------------------------------------------------------------------
        // -- Pipeline NN: input - neurons of the previous layer
        //                 output - calculated neurons to the next layer
        // input simplified AXIS
        .rx_tdata                   (rx_tdata), 
        .rx_tvalid                  (tx_tvalid), 
        .rx_tlast                   (tx_tlast), 
        .rx_tready                  (tx_tready),
        // output simplified AXIS
        .tx_tdata                   (tdata_hid_core [DATA_WIDTH - 1 : 0]), 
        .tx_tvalid                  (tvalid_hid_core[0]), 
        .tx_tlast                   (tlast_hid_core [0]), 
        .tx_tready                  (tready_hid_core[0]),
        // ---------------------------------------------------------------------------------  


        // AXI lite master interfaces for memory with W ----------------------------------------   
        .to_RAM_axi_awaddr          (from_cores_axi_awaddr  [n * ADDR_WIDTH +: ADDR_WIDTH]),    
        .to_RAM_axi_awlen           (from_cores_axi_awlen   [n * 8 +: 8]),    
        .to_RAM_axi_awsize          (from_cores_axi_awsize  [n * 3 +: 3]),    
        .to_RAM_axi_awburst         (from_cores_axi_awburst [n * 2 +: 2]),    
        .to_RAM_axi_awprot          (from_cores_axi_awprot  [n * 3 +: 3]),    
        .to_RAM_axi_awvalid         (from_cores_axi_awvalid [n]),    
        .to_RAM_axi_awready         (from_cores_axi_awready [n]),    
        .to_RAM_axi_wdata           (from_cores_axi_wdata   [n * DATA_WIDTH +: DATA_WIDTH]),    
        .to_RAM_axi_wstrb           (from_cores_axi_wstrb   [n * STRB_WIDTH +: STRB_WIDTH]),    
        .to_RAM_axi_wvalid          (from_cores_axi_wvalid  [n]),    
        .to_RAM_axi_wready          (from_cores_axi_wready  [n]),    
        .to_RAM_axi_bresp           (from_cores_axi_bresp   [n * 2 +: 2]),    
        .to_RAM_axi_bvalid          (from_cores_axi_bvalid  [n]),    
        .to_RAM_axi_bready          (from_cores_axi_bready  [n]),

        .to_RAM_axi_araddr          (from_cores_axi_araddr  [n * ADDR_WIDTH +: ADDR_WIDTH]),      
        .to_RAM_axi_arlen           (from_cores_axi_arlen   [n * 8 +: 8]),    
        .to_RAM_axi_arsize          (from_cores_axi_arsize  [n * 3 +: 3]),    
        .to_RAM_axi_arburst         (from_cores_axi_arburst [n * 2 +: 2]),    
        .to_RAM_axi_arprot          (from_cores_axi_arprot  [n * 3 +: 3]),    
        .to_RAM_axi_arvalid         (from_cores_axi_arvalid [n]),    
        .to_RAM_axi_arready         (from_cores_axi_arready [n]),    
        .to_RAM_axi_rdata           (from_cores_axi_rdata   [n * DATA_WIDTH +: DATA_WIDTH]),    
        .to_RAM_axi_rresp           (from_cores_axi_rresp   [n * 2 +: 2]),    
        .to_RAM_axi_rvalid          (from_cores_axi_rvalid  [n]),    
        .to_RAM_axi_rready          (from_cores_axi_rready  [n])
      // ---------------------------------------------------------------------------------------  
      );
    end else if (n == NUMBER_CORE - 1) begin
      NN_layer_core #(
        .DATA_WIDTH     (DATA_WIDTH),
        .ADDR_WIDTH     (ADDR_WIDTH),
        .NUMBER_NEURON  (NUMBERS_NEURONS[n])
      ) 
      NN_layer_core(
        .clk                        (clk),
        .rst                        (rst),

        // -- Control Path -----------------------------------------------------------------
        .flag_of_last_layer         (1'b1),
        .load_settings_and_weights  (load_weights[n]),
        .base_addr_W                (base_addr_W[n * ADDR_WIDTH +: ADDR_WIDTH]),
        .number_of_inputs           (number_of_inputs[n * 8 +: 8]),
        .all_load_W_complite        (all_load_W_complite[n]),
        // --------------------------------------------------------------------------------- 

        // -- Data Patch -------------------------------------------------------------------
        // -- Pipeline NN: input - neurons of the previous layer
        //                 output - calculated neurons to the next layer
        // input simplified AXIS
       .rx_tdata                    (tdata_hid_core [(n - 1) * DATA_WIDTH +: DATA_WIDTH]]), 
        .rx_tvalid                  (tvalid_hid_core [n - 1]),                              
        .rx_tlast                   (tlast_hid_core  [n - 1]),                               
        .rx_tready                  (tready_hid_core [n - 1]),                              
        // output simplified AXIS
        .tx_tdata                   (tx_tdata  ), 
        .tx_tvalid                  (tx_tvalid ),                              
        .tx_tlast                   (tx_tlast  ),                              
        .tx_tready                  (tx_tready ),                             
        // ---------------------------------------------------------------------------------  


        // AXI lite master interfaces for memory with W ----------------------------------------   
        .to_RAM_axi_awaddr          (from_cores_axi_awaddr  [n * ADDR_WIDTH +: ADDR_WIDTH]),    
        .to_RAM_axi_awlen           (from_cores_axi_awlen   [n * 8 +: 8]),    
        .to_RAM_axi_awsize          (from_cores_axi_awsize  [n * 3 +: 3]),    
        .to_RAM_axi_awburst         (from_cores_axi_awburst [n * 2 +: 2]),    
        .to_RAM_axi_awprot          (from_cores_axi_awprot  [n * 3 +: 3]),    
        .to_RAM_axi_awvalid         (from_cores_axi_awvalid [n]),    
        .to_RAM_axi_awready         (from_cores_axi_awready [n]),    
        .to_RAM_axi_wdata           (from_cores_axi_wdata   [n * DATA_WIDTH +: DATA_WIDTH]),    
        .to_RAM_axi_wstrb           (from_cores_axi_wstrb   [n * STRB_WIDTH +: STRB_WIDTH]),    
        .to_RAM_axi_wvalid          (from_cores_axi_wvalid  [n]),    
        .to_RAM_axi_wready          (from_cores_axi_wready  [n]),    
        .to_RAM_axi_bresp           (from_cores_axi_bresp   [n * 2 +: 2]),    
        .to_RAM_axi_bvalid          (from_cores_axi_bvalid  [n]),    
        .to_RAM_axi_bready          (from_cores_axi_bready  [n]),

        .to_RAM_axi_araddr          (from_cores_axi_araddr  [n * ADDR_WIDTH +: ADDR_WIDTH]),      
        .to_RAM_axi_arlen           (from_cores_axi_arlen   [n * 8 +: 8]),    
        .to_RAM_axi_arsize          (from_cores_axi_arsize  [n * 3 +: 3]),    
        .to_RAM_axi_arburst         (from_cores_axi_arburst [n * 2 +: 2]),    
        .to_RAM_axi_arprot          (from_cores_axi_arprot  [n * 3 +: 3]),    
        .to_RAM_axi_arvalid         (from_cores_axi_arvalid [n]),    
        .to_RAM_axi_arready         (from_cores_axi_arready [n]),    
        .to_RAM_axi_rdata           (from_cores_axi_rdata   [n * DATA_WIDTH +: DATA_WIDTH]),    
        .to_RAM_axi_rresp           (from_cores_axi_rresp   [n * 2 +: 2]),    
        .to_RAM_axi_rvalid          (from_cores_axi_rvalid  [n]),    
        .to_RAM_axi_rready          (from_cores_axi_rready  [n])
      // ---------------------------------------------------------------------------------------  
      );      
    end else begin
      NN_layer_core #(
        .DATA_WIDTH     (DATA_WIDTH),
        .ADDR_WIDTH     (ADDR_WIDTH),
        .NUMBER_NEURON  (NUMBERS_NEURONS[n])
      ) 
      NN_layer_core(
        .clk                        (clk),
        .rst                        (rst),

        // -- Control Path -----------------------------------------------------------------
        .flag_of_last_layer         (1'b0),  
        .load_settings_and_weights  (load_weights[n]),
        .base_addr_W                (base_addr_W[n * ADDR_WIDTH +: ADDR_WIDTH),
        .number_of_inputs           (number_of_inputs[n * 8 +: 8]),
        .all_load_W_complite        (all_load_W_complite[n]),
        // --------------------------------------------------------------------------------- 

        // -- Data Patch -------------------------------------------------------------------
        // -- Pipeline NN: input - neurons of the previous layer
        //                 output - calculated neurons to the next layer
        // input simplified AXIS
        .rx_tdata                   (tdata_hid_core [[n - 1] * DATA_WIDTH +: DATA_WIDTH]]), 
        .rx_tvalid                  (tvalid_hid_core [n - 1]),                              
        .rx_tlast                   (tlast_hid_core  [n - 1]),                               
        .rx_tready                  (tready_hid_core [n - 1]),                              
        // output simplified AXIS
        .tx_tdata                   (tdata_hid_core  [n * DATA_WIDTH +: DATA_WIDTH]]), 
        .tx_tvalid                  (tvalid_hid_core [n]),                              
        .tx_tlast                   (tlast_hid_core  [n]),                              
        .tx_tready                  (tready_hid_core [n]),                                        
        // ---------------------------------------------------------------------------------  


        // AXI lite master interfaces for memory with W ----------------------------------------   
        .to_RAM_axi_awaddr          (from_cores_axi_awaddr  [n * ADDR_WIDTH +: ADDR_WIDTH]),    
        .to_RAM_axi_awlen           (from_cores_axi_awlen   [n * 8 +: 8]),    
        .to_RAM_axi_awsize          (from_cores_axi_awsize  [n * 3 +: 3]),    
        .to_RAM_axi_awburst         (from_cores_axi_awburst [n * 2 +: 2]),    
        .to_RAM_axi_awprot          (from_cores_axi_awprot  [n * 3 +: 3]),    
        .to_RAM_axi_awvalid         (from_cores_axi_awvalid [n]),    
        .to_RAM_axi_awready         (from_cores_axi_awready [n]),    
        .to_RAM_axi_wdata           (from_cores_axi_wdata   [n * DATA_WIDTH +: DATA_WIDTH]),    
        .to_RAM_axi_wstrb           (from_cores_axi_wstrb   [n * STRB_WIDTH +: STRB_WIDTH]),    
        .to_RAM_axi_wvalid          (from_cores_axi_wvalid  [n]),    
        .to_RAM_axi_wready          (from_cores_axi_wready  [n]),    
        .to_RAM_axi_bresp           (from_cores_axi_bresp   [n * 2 +: 2]),    
        .to_RAM_axi_bvalid          (from_cores_axi_bvalid  [n]),    
        .to_RAM_axi_bready          (from_cores_axi_bready  [n]),

        .to_RAM_axi_araddr          (from_cores_axi_araddr  [n * ADDR_WIDTH +: ADDR_WIDTH]),      
        .to_RAM_axi_arlen           (from_cores_axi_arlen   [n * 8 +: 8]),    
        .to_RAM_axi_arsize          (from_cores_axi_arsize  [n * 3 +: 3]),    
        .to_RAM_axi_arburst         (from_cores_axi_arburst [n * 2 +: 2]),    
        .to_RAM_axi_arprot          (from_cores_axi_arprot  [n * 3 +: 3]),    
        .to_RAM_axi_arvalid         (from_cores_axi_arvalid [n]),    
        .to_RAM_axi_arready         (from_cores_axi_arready [n]),    
        .to_RAM_axi_rdata           (from_cores_axi_rdata   [n * DATA_WIDTH +: DATA_WIDTH]),    
        .to_RAM_axi_rresp           (from_cores_axi_rresp   [n * 2 +: 2]),    
        .to_RAM_axi_rvalid          (from_cores_axi_rvalid  [n]),    
        .to_RAM_axi_rready          (from_cores_axi_rready  [n])
      // ---------------------------------------------------------------------------------------  
      );      
    end
  end
endgenerate

axi_interconnect #(
  .S_COUNT                  (NUMBER_CORE               ),
  .M_COUNT                  (1                         ),
  .DATA_WIDTH               (DATA_WIDTH                ),
  .ADDR_WIDTH               (ADDR_WIDTH                ),
  .STRB_WIDTH               (STRB_WIDTH                ),
  .M_REGIONS                (M_REGIONS                 ),
  .M_BASE_ADDR              (M_BASE_ADDR               ),
  .M_ADDR_WIDTH             (M_ADDR_WIDTH              ),

)
axi_interconnect_inst (
  .clk                      (clk                       ),
  .rst                      (rst                       ),
  .s_axi_awaddr             (from_cores_axi_awaddr     ),
  .s_axi_awlen              (from_cores_axi_awlen      ),
  .s_axi_awsize             (from_cores_axi_awsize     ),
  .s_axi_awburst            (from_cores_axi_awburst    ),
  .s_axi_awprot             (from_cores_axi_awprot     ),
  .s_axi_awvalid            (from_cores_axi_awvalid    ),
  .s_axi_awready            (from_cores_axi_awready    ),
  .s_axi_wdata              (from_cores_axi_wdata      ),
  .s_axi_wstrb              (from_cores_axi_wstrb      ),
  .s_axi_wvalid             (from_cores_axi_wvalid     ),
  .s_axi_wready             (from_cores_axi_wready     ),
  .s_axi_bresp              (from_cores_axi_bresp      ),
  .s_axi_bvalid             (from_cores_axi_bvalid     ),
  .s_axi_bready             (from_cores_axi_bready     ),
  .s_axi_araddr             (from_cores_axi_araddr     ),
  .s_axi_arprot             (from_cores_axi_arprot     ),
  .s_axi_arlen              (from_cores_axi_arlen      ),
  .s_axi_arsize             (from_cores_axi_arsize     ),
  .s_axi_arburst            (from_cores_axi_arburst    ),
  .s_axi_arvalid            (from_cores_axi_arvalid    ),
  .s_axi_arready            (from_cores_axi_arready    ),
  .s_axi_rdata              (from_cores_axi_rdata      ),
  .s_axi_rresp              (from_cores_axi_rresp      ),
  .s_axi_rvalid             (from_cores_axi_rvalid     ),
  .s_axi_rready             (from_cores_axi_rready     ),

  .m_axi_awaddr             (to_RAM_axi_awaddr         ),
  .m_axi_awlen              (to_RAM_axi_awlen          ),
  .m_axi_awsize             (to_RAM_axi_awsize         ),
  .m_axi_awburst            (to_RAM_axi_awburst        ),
  .m_axi_awprot             (to_RAM_axi_awprot         ),
  .m_axi_awvalid            (to_RAM_axi_awvalid        ),
  .m_axi_awready            (to_RAM_axi_awready        ),
  .m_axi_wdata              (to_RAM_axi_wdata          ),
  .m_axi_wstrb              (to_RAM_axi_wstrb          ),
  .m_axi_wvalid             (to_RAM_axi_wvalid         ),
  .m_axi_wready             (to_RAM_axi_wready         ),
  .m_axi_bresp              (to_RAM_axi_bresp          ),
  .m_axi_bvalid             (to_RAM_axi_bvalid         ),
  .m_axi_bready             (to_RAM_axi_bready         ),
  .m_axi_araddr             (to_RAM_axi_araddr         ),
  .m_axi_arprot             (to_RAM_axi_arprot         ),
  .m_axi_arlen              (to_RAM_axi_arlen          ),
  .m_axi_arsize             (to_RAM_axi_arsize         ),
  .m_axi_arburst            (to_RAM_axi_arburst        ),
  .m_axi_arvalid            (to_RAM_axi_arvalid        ),
  .m_axi_arready            (to_RAM_axi_arready        ),
  .m_axi_rdata              (to_RAM_axi_rdata          ),
  .m_axi_rresp              (to_RAM_axi_rresp          ),
  .m_axi_rvalid             (to_RAM_axi_rvalid         ),
  .m_axi_rready             (to_RAM_axi_rready         )
);


logic [ADDR_WIDTH-1:0]      to_RAM_axi_awaddr   ;
logic [7:0]                 to_RAM_axi_awlen    ;
logic [2:0]                 to_RAM_axi_awsize   ;
logic [1:0]                 to_RAM_axi_awburst  ;
logic [2:0]                 to_RAM_axi_awprot   ;
logic                       to_RAM_axi_awvalid  ;
logic                       to_RAM_axi_awready  ;
logic [DATA_WIDTH-1:0]      to_RAM_axi_wdata    ;
logic [STRB_WIDTH-1:0]      to_RAM_axi_wstrb    ;
logic                       to_RAM_axi_wvalid   ;
logic                       to_RAM_axi_wready   ;
logic [1:0]                 to_RAM_axi_bresp    ;
logic                       to_RAM_axi_bvalid   ;
logic                       to_RAM_axi_bready   ;
logic [ADDR_WIDTH-1:0]      to_RAM_axi_araddr   ;
logic [7:0]                 to_RAM_axi_arlen    ;
logic [2:0]                 to_RAM_axi_arsize   ;
logic [1:0]                 to_RAM_axi_arburst  ;
logic [2:0]                 to_RAM_axi_arprot   ;
logic                       to_RAM_axi_arvalid  ;
logic                       to_RAM_axi_arready  ;
logic [DATA_WIDTH-1:0]      to_RAM_axi_rdata    ;
logic [1:0]                 to_RAM_axi_rresp    ;
logic                       to_RAM_axi_rvalid   ;
logic                       to_RAM_axi_rready   ;       


axi_ram #(
  .DATA_WIDTH               (DATA_WIDTH         ),
  .ADDR_WIDTH               (ADDR_WIDTH         ),
  .STRB_WIDTH               (STRB_WIDTH         ),
  .PIPELINE_OUTPUT          (PIPELINE_OUTPUT    )
)
axi_ram_inst (
  .clk                      (clk                ),
  .rst                      (rst                ),
  .s_axi_awaddr             (to_RAM_axi_awaddr  ),
  .s_axi_awlen              (to_RAM_axi_awlen   ),
  .s_axi_awsize             (to_RAM_axi_awsize  ),
  .s_axi_awburst            (to_RAM_axi_awburst ),
  .s_axi_awprot             (to_RAM_axi_awprot  ),
  .s_axi_awvalid            (to_RAM_axi_awvalid ),
  .s_axi_awready            (to_RAM_axi_awready ),
  .s_axi_wdata              (to_RAM_axi_wdata   ),
  .s_axi_wstrb              (to_RAM_axi_wstrb   ),
  .s_axi_wvalid             (to_RAM_axi_wvalid  ),
  .s_axi_wready             (to_RAM_axi_wready  ),
  .s_axi_bresp              (to_RAM_axi_bresp   ),
  .s_axi_bvalid             (to_RAM_axi_bvalid  ),
  .s_axi_bready             (to_RAM_axi_bready  ),
  .s_axi_araddr             (to_RAM_axi_araddr  ),
  .s_axi_arprot             (to_RAM_axi_arprot  ),
  .s_axi_arlen              (to_RAM_axi_arlen   ),
  .s_axi_arsize             (to_RAM_axi_arsize  ),
  .s_axi_arburst            (to_RAM_axi_arburst ),
  .s_axi_arvalid            (to_RAM_axi_arvalid ),
  .s_axi_arready            (to_RAM_axi_arready ),
  .s_axi_rdata              (to_RAM_axi_rdata   ),
  .s_axi_rresp              (to_RAM_axi_rresp   ),
  .s_axi_rvalid             (to_RAM_axi_rvalid  ),
  .s_axi_rready             (to_RAM_axi_rready  )
);

// =============================================================================================
// END: Main control unit ------------------------------------------------------------------- ==
// ==                                                                                         ==

typedef enum logic [1:0] {IDLe, Load_W, Active_state} FSM_t;
FSM_t current_state = IDLe;
FSM_t next_state    = IDLe;

logic nn_ready_next = 0;

always_comb begin
  if (rst) begin
    current_state = IDLe;
    nn_ready      = 0;
    load_weights  = 0;
  end else begin
    current_state = next_state;
    nn_ready      = nn_ready_next;
    load_weights  = load_weights_next;
  end 
end

byte unsigned cnt = 0;

always_ff @(posedge clk) begin
  case(current_state)
    IDLe: begin
      if (start_Load_W) begin
        next_state <= Load_W;
        load_weights_next[0] <= 1;
        base_addr_W[ADDR_WIDTH - 1: 0] <= BASE_ADDR_W_FOR_LAYERS[0];
        number_of_inputs[MAX_NEURON_IN_LAYER - 1: 0] <= NUMBER_OF_INPUTS % 256; // int => byte
        cnt <= 1;
      end
    end
    Load_W: begin
      if (all_load_W_complite[cnt - 1]) begin
        number_of_inputs[8 * cnt +: 8] <= NUMBERS_NEURONS[cnt - 1] % 256; // int => byte 
        load_weights_next[cnt] <= 1;
        base_addr_W[ADDR_WIDTH * cnt +: ADDR_WIDTH] <= BASE_ADDR_W_FOR_LAYERS[cnt];
        cnt <= cnt + 1;
      end else load_weights_next[cnt] <= 0;
      if (cnt == NUMBER_LAYER - 1) begin
        if (all_load_W_complite[cnt]) begin
          next_state    <= Active_state ;
          nn_ready_next <= 1;
        end
      end 
    end
    Active_state: begin
      // DO NOTHING
    end
    default:

end

// ==                                                                                         ==
// END: Main control unit ------------------------------------------------------------------- ==
// =============================================================================================
endmodule