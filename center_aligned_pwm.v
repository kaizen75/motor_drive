`timescale 1ns / 1ps

//Verilog module for a center-aligned PWM module. The verilog module has undergone basic testing and looks okay, but bugs might remain!
//Use this code at your own risk and only after careful analysis and/or debugging!
//
//About the license: I don't know if I chose the right one. From my standpoint you can do everything with this code as long as it is legal. 
//Commercial re-use, etc is not limited in any way! This code has been written by me and I am the only originator...
//
//WIDTH sets the UP/DOWN counter width. The UP/DOWN counter is used to create the "triangle wave" counting pattern needed for the center-aligned PWM.
//The module support DEADTIME. The deadtime on the falling counter slope is twice the DEADTIME value set. The deadtime on the rising counter slope is once the DEADTIME value.
//The deadtime delays are different to allow for different charging and discharging times of the switching transistors. Change the variables according to the needs of your transistors.
//The module implements clamping of the PWM input values so that minimum and maximum PWM limits are present.

//COMPLIANCE NOTE: SWITCHED-POWER CONVERSION CAN CAUSE SEVERE EMC ISSUES!
//SAFETY NOTE: SWITCHED-POWER CONVERSION CAN RESULT IN ELECTRICAL HAZARDS!

module center_aligned_PWM #(parameter WIDTH = 'd16)   //Change the WIDTH parameter to set the counter width
(
  input wire i_clk,
  input wire i_reset_n,
  input [WIDTH-1:0] pwm_input_value,
  output reg pwm_output_high,
  output reg pwm_output_low
);

localparam COUNTERHIGH  =   (('d2 ** WIDTH)-'d1); //'d2 ** WIDTH calculates 2^WIDTH. So if WIDTH = 10, 2^10 will be 1024
localparam COUNTERLOW   =   'd1;
localparam DEADTIME     =   'd10;     //While upcounting DEADTIME sets the delay in clock cycles(e.g. 10 = 10 clock cycles). While down-counting the delay is 2x DEADTIME (e.g. 10 = 20 clock cycles)    
localparam PWMLOWLIMIT  =   COUNTERLOW  + 'd30;
localparam PWMHIGHLIMIT =   COUNTERHIGH - 'd30;

localparam
//BOOLEAN DEFINITIONS
    LOW         =  'b0,
    HIGH        =  'b1,

//STATE MACHINE VARIABLES BELOW
    RESET       = 2'b00,
    UP          = 2'b01,
    DOWN        = 2'b10,
    
//RESET STATE DEFINITIONS
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
            
            if (counter < pwm_setpoint_value - DEADTIME)
            begin
                pwm_output_low = LOW;
                pwm_output_high = HIGH;
            end
            
            if((counter >= pwm_setpoint_value - DEADTIME) && (counter < pwm_setpoint_value))
            begin
                pwm_output_low = LOW;
                pwm_output_high = LOW;
            end
            
            if (counter >= pwm_setpoint_value)
            begin
                pwm_output_low <= HIGH;
                pwm_output_high <= LOW;
            end
            
            if (counter >= COUNTERHIGH)
            begin
                counter_state = DOWN;
                counter <= COUNTERHIGH;
            end
        end
        
    DOWN:
        begin
            counter <= counter - 1;
            
            if (counter > pwm_setpoint_value + 2 * DEADTIME)
            begin
                pwm_output_low <= HIGH;
                pwm_output_high <= LOW;
            end
            
            if((counter <= pwm_setpoint_value + 2 * DEADTIME) && (counter > pwm_setpoint_value))
            begin
                pwm_output_low = LOW;
                pwm_output_high = LOW;
            end
            
            if (counter <= pwm_setpoint_value)
            begin
                pwm_output_low = LOW;
                pwm_output_high = HIGH;
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
