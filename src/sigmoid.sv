module sigmoid(
  input shortreal     x,
  output logic [31:0] y
);

  // Коэффициенты сигмоидной функции
  parameter real a = 1.0;
  parameter real b = 0.0;
  
  // Преобразование входного числа в тип shortreal
  shortreal num_real = x;
  
  // Вычисление сигмоидной функции
  shortreal sigmoid_real = 1.0 / (1.0 + exp(-(a*num_real + b)));
  
  // Преобразование результата в тип logic
  y = sigmoid_real;

endmodule