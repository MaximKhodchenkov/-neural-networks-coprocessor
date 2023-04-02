module shortreal_multiplier(
  input logic [31:0] a,
  input logic [31:0] b,
  output shortreal result
);

  shortreal num1_real = a;
  shortreal num2_real = b;
  result = num1_real * num2_real;
 

endmodule
