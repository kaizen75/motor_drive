`timescale 1ns / 1ps

`define clockFreq 10            //is dit in MHz of ns?

module tb(                      //Waarom is deze module leeg?

    );
                                    
 reg clk;
 reg reset;
 reg [5:0] tb_count=0;
 wire conv_start;
 reg channel;
 reg adc_data_A=0;
 reg adc_data_B=0;
 reg [15:0] adc_data_port_A;
 reg [15:0] adc_data_port_B;
 wire adc_clock;
 integer i;
 wire channel_0_enable;         //Heb ik zo correct een variabele geinstantieerd zodat deze in de ILA zichtbaar is? Want dat was het doel...
 wire channel_1_enable;
 integer i;
 
 initial
 begin
    clk = 0;
    forever
    begin
        clk = !clk;
        #((`clockFreq)/2);      //Is # het wait commando?
    end
 end
 
  
 initial
 begin
    reset = 0;
    #100;
    reset = 1;
 end
 
/*
always @(posedge clk)
begin
    if(!reset)
        tb_count <= 5'd0;
    else
    begin
        if(tb_count != 19)
            tb_count <= tb_count + 1'b1;
        else
            tb_count <= 5'd0;
    end
end
*/
 
 initial
 begin
    channel = 0;
    forever
    begin         
        @(posedge clk);
        
        if(!reset)
            tb_count = 0;
        
        case (tb_count)
            0:
            begin
                if(conv_start)
                begin
                    channel = !channel;
                    adc_data_A <= channel;
                    adc_data_B <= channel;     
                    tb_count <= tb_count + 1;
                end     
            end    
                    
            1:
            begin
                adc_data_A <= 1'b0;
                adc_data_B <= 1'b0;
                adc_data_port_A = 'hFFFF;
                adc_data_port_B = 'hFFFF;
                $display($time,,,,"Data from ADC Port A is %d and data from ADC Port B is %d\n",adc_data_port_A, adc_data_port_B);
                tb_count <= tb_count + 1;
            end 
            
            2:
            begin
                //adc_data_port_A = $random()%65535;
               for(i=0;i<16;i=i+1)
               begin
                    adc_data_A = adc_data_port_A[15];
                    adc_data_B = adc_data_port_B[15]; 
                    adc_data_port_A = adc_data_port_A<<1;
                    adc_data_port_B = adc_data_port_B<<1;
                    @(negedge clk);
                end
                tb_count <= tb_count + 1;
            end 
            
            3:
            begin
                adc_data_A <= 0;
                adc_data_B <= 0;
                tb_count = 0;
            end          
        endcase 
    end   
 end
    
    
 ADS8361 adc(                          //moduleName instanceName
                                       //positional //named port mapping
                                       //.formal Port(Actual Port)
.i_clk(clk),
.i_reset_n(reset),                     //if formal port is output, actual ports should be always wire type
.i_adc_port_A(adc_data_A),   //if formal port is input, actual port can be wire or reg
.i_adc_port_B(adc_data_B),   //if formal port is input, actual port can be wire or reg
.o_conv_start(conv_start),
.o_adc_clock(adc_clock),
.channel_0_enable(channel_0_enable),    //map ik zo channel_0_enable correct zodat deze te zien is in de ILA?
.channel_1_enable(channel_1_enable)
 );
 
    
endmodule
