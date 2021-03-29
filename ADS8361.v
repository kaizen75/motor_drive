`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/08/2021 07:23:50 AM
// Design Name: 
// Module Name: ADS8361
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`define ConvTime 20

module ADS8361
(
    input   i_clk,
    input   i_reset_n,
    input   i_adc_data1,
    input   i_adc_data2,
    output  o_conv_start,
    output  reg o_adc_clock
);
    
 reg [4:0] counter;//Counter to count number of clocks elapsed
 reg [7:0] clock_counter; //counter used for main clock division to ADC_Clock
 reg [15:0] channel_A_Data;
 reg [15:0] channel_B_Data;
 reg channel_A_Enable, channel_B_Enable;
 
 localparam IDLE = 'd0, //local parameter declaration
            GET_CHANNEL = 'd1,
            ENABLE_CHA = 'd2,
            ENABLE_CHB = 'd3,
            GetData = 'd4;
 
 reg [2:0] state;
 
always @(posedge i_clk)
begin 
    if(!i_reset_n)
    begin
        clock_counter <= 0;
    end 
    if(clock_counter != 4)
        clock_counter <= clock_counter + 1;
    else
        clock_counter <= 0;
end

/*
initial 
    o_adc_clock <= 0;

always @(posedge i_clk)
begin
    if(!i_reset_n)
    begin
        o_adc_clock <= 0;
    end
    if(i_reset_n && clock_counter == 4)
        o_adc_clock <= ~o_adc_clock;
end
*/

always @(posedge i_clk)
begin
    o_adc_clock = ~o_adc_clock;
end

always @(posedge o_adc_clock)
begin
    if(!i_reset_n)
    begin
        state <= IDLE;
        channel_A_Enable <= 1'b0;
        channel_B_Enable <= 1'b0;
    end
    else
    begin
        case(state)
            IDLE:begin
                if(o_conv_start)
                    state <= GET_CHANNEL;
            end
            GET_CHANNEL:begin
                if(i_adc_data1 == 1'b1)
                    state <= ENABLE_CHA;
                
                else
                    state <= ENABLE_CHB;
            end
            ENABLE_CHA:begin
                channel_A_Enable <= 1'b1;
                state <= GetData;
            end
           ENABLE_CHB:begin
                channel_B_Enable <= 1'b1;
                state <= GetData;
            end
            GetData:begin
                if(counter == 'd16)
                begin
                    channel_A_Enable <= 1'b0;
                    channel_B_Enable <= 1'b0;
                    state <= IDLE;
                end
            end
        endcase
    end
 end
 
 always @(posedge o_adc_clock)
 begin
 if(!i_reset_n)
    channel_A_Data <= 'd0;
 else if(channel_A_Enable)
    channel_A_Data <= {channel_A_Data[14:0],i_adc_data1}; 
 end
    
    
    
 always @(posedge o_adc_clock)
 begin
 if(!i_reset_n)
    channel_B_Data <= 'd0;
 else if(channel_B_Enable)
    channel_B_Data <= {channel_B_Data[14:0],i_adc_data1};
 end
    
 
 assign o_conv_start = (counter==19) ? 1'b1 : 1'b0;
 
 always @(negedge o_adc_clock)
 begin
    if(!i_reset_n)
        counter <= 5'd0;
    else
    begin
        if(counter != 19)
            counter <= counter + 1'b1;
        else
            counter <= 5'd0;
    end
  end
 
    
endmodule
