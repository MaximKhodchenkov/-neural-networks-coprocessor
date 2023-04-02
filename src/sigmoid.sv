module sigmoid (
  input signed [31:0] x,
  output reg signed [31:0] y
);

  parameter EXPONENT = 17; // Параметр для определения экспоненты

  // Рассчитываем экспоненту
  wire signed [31:0] exp = $exp(x >> EXPONENT);

  // Рассчитываем значение сигмоидальной функции
  always @ (*) begin
    y = (exp << EXPONENT) / (exp << EXPONENT + (1 << EXPONENT));
  end

endmodule