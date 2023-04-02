`timescale 1ns/1ps

module top_level_nn_tb();
  // Parameters
  localparam DATA_WIDTH = 32;
  localparam ADDR_WIDTH = 32;
  localparam STRB_WIDTH = DATA_WIDTH/8;
  localparam NUMBERS_NEURONS = {10, 3};
  localparam NUMBER_LAYER = 2;
  localparam NUMBER_OF_INPUTS = 49;

  logic clk, rst;

  logic [DATA_WIDTH-1:0] rx_tdata;
  logic rx_tvalid;
  logic rx_tlast;
  logic rx_tready;
  logic [DATA_WIDTH-1:0] tx_tdata;
  logic tx_tvalid;
  logic tx_tlast;
  logic tx_tready;
  logic start_Load_W;
  logic nn_ready;

  always begin
    #5 clk = ~clk;
  end

  top_level_nn #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .STRB_WIDTH(STRB_WIDTH),
    .NUMBERS_NEURONS(NUMBERS_NEURONS),
    .NUMBER_LAYER(NUMBER_LAYER),
    .NUMBER_OF_INPUTS(NUMBER_OF_INPUTS)
  ) dut (
    .clk              (clk),
    .rst              (rst),
    .rx_tdata         (rx_tdata),
    .rx_tvalid        (rx_tvalid),
    .rx_tlast         (rx_tlast),
    .rx_tready        (rx_tready),
    .tx_tdata         (tx_tdata),
    .tx_tvalid        (tx_tvalid),
    .tx_tlast         (tx_tlast),
    .tx_tready        (tx_tready),
    .start_Load_W     (start_Load_W),
    .nn_ready         (nn_ready)
  );

  
  initial begin
    clk = 0;
    rst = 1;
    rx_tdata = 0;
    rx_tvalid = 0;
    rx_tlast = 0;
    start_Load_W = 0;

    // Apply reset
    #10;
    rst = 0;
    $finish;
  end
endmodule