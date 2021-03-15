`timescale 1ns / 1ps

//This verilog code creates an UP/DOWN counter that can be used for center-aligned PWM
//
//     /\    /\    /\    /\    /\
//    /  \  /  \  /  \  /  \  /  \
//   /    \/    \/    \/    \/    \
//
//The WIDTH parameter sets the width of the counter e.g. the value 10 creates a 10-bit-wide counter
//The code uses the MSB of the counter as a flag to determine if the count direction is UP or DOWN
//In case the count direction is UP, the counter increments like a normal UP counter.
//In case the count direction is DOWN (when the MSB==1), the output value is inverted.
//When RESET (rst_n) is 0, the output value of the counter is reset to 0

module center_aligned_PWM #(parameter WIDTH = 'd9)   //Change the WIDTH parameter to set the counter width
(
  input wire i_clk,
  input wire i_reset_n,
  input [WIDTH-1:0] pwm_input_value,
  output reg pwm_output_high,
  output reg pwm_output_low
);

localparam COUNTERHIGH  =   (('d2 ** WIDTH)-'d1);
localparam COUNTERLOW   =   'd1;
localparam DEADTIME     =   'd10;     //While upcounting DEADTIME sets the delay in clock cycles(e.g. 10 = 10 clock cycles). While down-counting the delay is 2x DEADTIME (e.g. 10 = 20 clock cycles)    
localparam PWMLOWLIMIT  =   COUNTERLOW  + 'd30;
localparam PWMHIGHLIMIT =   COUNTERHIGH - 'd30;

localparam
//STATE MACHINE VARIABLES BELOW
    RESET       = 2'b00,
    UP          = 2'b01,
    DOWN        = 2'b10,
    
//BOOLEAN DEFINITIONS
    LOW         =  'b0,
    HIGH        =  'b1,
    
//RESET DEFINITIONS
    ACTIVE      =  'b0,
    NOT_ACTIVE  =  'b1;
    
  reg [WIDTH-1:0] counter;
  reg [1:0] counter_state = RESET;
  reg [1:0] previous_reset_state = ACTIVE;
  reg [WIDTH-1:0] pwm_setpoint_value = PWMLOWLIMIT;

always @(posedge i_clk)
begin
    if (i_reset_n == ACTIVE)
        begin
            counter <= 'b0;
            pwm_output_high = LOW;
            pwm_output_low = LOW;
            pwm_setpoint_value = LOW;
            previous_reset_state = ACTIVE;
        end
        
    if (previous_reset_state == ACTIVE && i_reset_n == NOT_ACTIVE)      //if this statement is valid, the reset pin has just been de-asserted and we start UP counting
        begin
            counter_state = UP;
            pwm_output_low = LOW;
            pwm_output_high = LOW;
            previous_reset_state = NOT_ACTIVE;
        end
        
   begin     
       pwm_setpoint_value = pwm_input_value;
    
       if (pwm_setpoint_value >= PWMHIGHLIMIT)
            pwm_setpoint_value = PWMHIGHLIMIT;
        
       if (pwm_setpoint_value <= PWMLOWLIMIT)
            pwm_setpoint_value = PWMLOWLIMIT;
   end

    case(counter_state)   
    UP:
        begin
            counter <= counter + 1;
            
            if (counter > pwm_setpoint_value - DEADTIME)
            begin
                pwm_output_low = LOW;
            end
            
            if (counter > pwm_setpoint_value)
            begin
                pwm_output_high <= HIGH;
            end
            
            if (counter >= COUNTERHIGH)
            begin
                counter_state = DOWN;
                counter <= COUNTERHIGH; //Is this one necessary?
            end
        end
        
    DOWN: //At the start of the down count pwm_output_high is high and pwm_output_low is low
        begin
            counter <= counter - 1;
            
            if (counter < pwm_setpoint_value  + (2 * DEADTIME))
            begin
                pwm_output_high = LOW;
            end
            
            if (counter < pwm_setpoint_value)
            begin
                pwm_output_low <= HIGH;
            end
            
            if (counter <= COUNTERLOW)
            begin
                counter_state = UP;
                counter <= COUNTERLOW;
            end
        end
    
    endcase
end

endmodule
