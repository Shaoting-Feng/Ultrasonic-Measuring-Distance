`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/10 14:00:58
// Design Name: ultrasound measuring distance
// Module Name: UltrasoundDME
// Project Name: ultrasound measuring distance
// Target Devices: FPGA
// Tool Versions: 3
// Description: ultrasound measuring distance
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module D0_display( // transistor module
    input [3:0] D0_bits,
    input [3:0] D0_NUM,
    output reg [6:0] D0_a_to_g,
    output D0_dot,
    output [3:0] D0_led_bits
);
    assign D0_dot = D0_led_bits[1];
    assign D0_led_bits = D0_bits;
    always @(*) begin
        case(D0_NUM)
            0:D0_a_to_g=7'b1111110;
            1:D0_a_to_g=7'b0110000;
            2:D0_a_to_g=7'b1101101;
            3:D0_a_to_g=7'b1111001;
            4:D0_a_to_g=7'b0110011;
            5:D0_a_to_g=7'b1011011;
            6:D0_a_to_g=7'b1011111;
            7:D0_a_to_g=7'b1110000;
            8:D0_a_to_g=7'b1111111;
            9:D0_a_to_g=7'b1111011;
            default: D0_a_to_g=7'b1111110;
        endcase
    end
endmodule

module UltrasoundDME(
    input   clk,
    input   start,
    input   receive,
    output  reg signal_1,
    output  reg signal_2,
    output  [6:0] a_to_g,
    output  dot,
    output  [3:0] led_bits ,
    output  reg receive_detect,         // LED for display
    output  reg start_detect,           // ~
    output  reg flag_square_detect,     // ~
    output  reg flag_button_detect      // ~
    );
    
    reg [3:0]   t_led_bits      ;
    reg [31:0]  clk_cnt         ;
    reg         flag_button     ; // for debounce
    reg [9:0]   delay           ; // ~
    reg         flag_square     ; // for #waves control
    reg [6:0]   waves           ;
    reg [6:0]   waves_cnt       ;
    reg         flag_receive    ;             
    integer     ultrasound_speed;
    integer     t               ; // timekeeping
    reg         t_rst           ;
    integer     distance        ;
    reg [3:0]   num             ;
    reg [31:0]  d               ; // for specified freguency
    
    initial begin
        clk_cnt             <=      0   ;
        flag_button         <=      0   ;
        flag_square         <=      0   ;
        d                   <=      0   ;
        delay               <=      1000;
        waves               <=      40  ;
        waves_cnt           <=      0   ;
        flag_receive        <=      0   ;
        receive_detect      <=      0   ;
        ultrasound_speed    <=      280 ;
        distance            <=      0   ;
        num                 <=      0   ;  
        t                   <=      0   ;  
        t_rst               <=      0   ;
    end

    always@(posedge clk) begin  
        clk_cnt <= clk_cnt + 1;  // 10ns
        if (t_rst) begin
            t <= 0;
            t_rst <= 0;
        end else
            t <= t + 1;
            
        if (start && (~flag_button)) begin  // press the button
            flag_button <= 1;
            flag_square <= 1;
            flag_receive <= 0;
            t_rst <= 1;
            d <= 0;
        end

        if (flag_square) // generate square wave module       
            if (d == 1250) begin // 40kHz
                d <= 0;
                signal_1 <= signal_2;
                signal_2 <= ~signal_2;
                waves_cnt <= waves_cnt + 1;
            end else begin
                d <= d+1;
                signal_1 <= signal_1;
                signal_2 <= signal_2;
                waves_cnt <= waves_cnt + 1;
            end
        if (waves_cnt >= waves) begin
            flag_square <= 0;
            waves_cnt <= 0;
        end

        if (flag_button && t >= delay * 1000) begin // debounce
            flag_button <= 0;
        end
        
        if (receive) begin  
            if (~flag_receive) begin
                flag_receive <= 1;
                distance <= ultrasound_speed * t / 200000;
            end
        end
    end
    
    always@(*) begin // display
        case (clk_cnt[15:14])
            0: begin
                num <= distance % 10;
                t_led_bits <= 4'b0001;
            end
            1: begin
                num <= distance / 10 % 10;
                t_led_bits <= 4'b0010;
            end
            2: begin
                num <= distance / 100 % 10;
                t_led_bits <= 4'b0100;
            end
            3: begin
                num <= distance / 1000 % 10;
                t_led_bits <= 4'b1000;
            end
        endcase
    end
    
    always@(*)  begin   // LED for display
        receive_detect <= flag_receive;
        start_detect <= start;
        flag_square_detect <= flag_square;
    end
    
    D0_display myD0_display(.D0_bits(t_led_bits),.D0_NUM(num),.D0_a_to_g(a_to_g),.D0_dot(dot),.D0_led_bits(led_bits)) ;
endmodule

