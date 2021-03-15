`timescale 1ns / 1ps

//This verilog code creates an UP/DOWN counter that can be used for center-aligned PWM
//
//     /\    /\    /\    /\    /\
//    /  \  /  \  /  \  /  \  /  \
//   /    \/    \/    \/    \/    \
//
//The WIDTH parameter sets the width of the counter (e.g. the value 10 creates a 10-bit-wide counter)
//The code uses the MSB of the counter as a flag to determine if the count direction is UP or DOWN
//In case the count direction is UP, the counter increments like a normal UP counter.
//In case the count direction is DOWN (when the MSB==1), the output value is inverted.
//When RESET (rst_n) is 0, the output value of the counter is reset to 0

module center_aligned_PWM #(parameter WIDTH = 10)   //Change the WIDTH parameter to set the counter width
(
  input wire i_clk,
  input wire rst_n,
  output reg [WIDTH-1:0] value
);

  reg [WIDTH:0] counter;

  always @(posedge i_clk) 
  begin
    if (rst_n == 0)
        counter <= 'b0;
    else
        counter = counter + 1'b1;
        
    if (counter[WIDTH] == 1)        //If the MSB direction flag bit is 1, the count direction is DOWN so we invert the output value
      value = ~counter[WIDTH-1:0];
    else
      value =  counter[WIDTH-1:0];
  end
  
endmodule
