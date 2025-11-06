`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/30 14:19:56
// Design Name: 
// Module Name: clk_en
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


module clk_en(
    input clk_in,
    input rst_n,
    output reg clk_1k,
	output reg clk_25M,
	output reg clk_1M
    );

    reg [14:0] count;
	reg [1:0] count1;
	reg [4:0] count2;

always@(posedge clk_in or negedge rst_n) begin
	if(!rst_n)
	begin
		count <= 15'd0;
		clk_1k<=1'd0;
	end
	else if(count == 15'd25000)
	begin
		clk_1k <= ~clk_1k;
		count<= 15'd0;
	end	
	else
		count <= count + 15'd1;
    end
		    
always@(posedge clk_in or negedge rst_n) begin
	if(!rst_n)
	begin
		count1 <= 2'd0;
		clk_25M<=1'd0;
	end
	else if(count1 == 2'd1)
	begin
		clk_25M <= ~clk_25M;
		count1<= 2'd0;
	end	
	else
		count1 <= count1 + 2'd1;
    end

always@(posedge clk_in or negedge rst_n) begin
	if(!rst_n)
	begin
		count2 <= 5'd0;
		clk_1M<=1'd0;
	end
	else if(count2 == 5'd25)
	begin
		clk_1M <= ~clk_1M;
		count2<= 5'd0;
	end	
	else
		count2 <= count2 + 5'd1;
    end
endmodule
