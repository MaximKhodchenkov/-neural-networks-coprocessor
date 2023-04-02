module sig_fract_mult #(
  parameter POINT_POSITION = 15;
  )(
  input signed [31:0] a,
  input signed [31:0] b,
  output reg signed [31:0] result
);

  // Умножаем a и b, результат занимает 64 бита
  wire signed [63:0] mult_result = a * b;

  // Сдвигаем точку на 31 разряд, чтобы получить 32-разрядное число с точкой по середине
  wire signed [31:0] result = mult_result >> POINT_POS;

endmodule