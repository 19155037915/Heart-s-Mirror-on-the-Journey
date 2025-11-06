`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/07 01:02:15
// Design Name: 
// Module Name: clk_div_50mhz_to_250hz
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


module clk_div_50mhz_to_250hz (
    input        clk_50mhz,   // 50MHz输入时钟
    input        rst_n,       // 异步复位（低有效）
    output reg   clk_250hz    // 250Hz输出时钟
);
    // 分频系数：50MHz / 250Hz = 200000，计数到199999翻转
    parameter DIV_COUNT = 199_999;  
    reg [17:0] counter;       // 18位计数器（最大262143 ≥ 199999）

    always @(posedge clk_50mhz or negedge rst_n) begin
        if (!rst_n) begin     // 复位时计数器清零，输出初始为低
            counter   <= 18'd0;
            clk_250hz <= 1'b0;
        end else begin
            if (counter >= DIV_COUNT) begin  // 计数到阈值，复位计数器并翻转输出
                counter   <= 18'd0;
                clk_250hz <= ~clk_250hz;     // 关键：输出翻转生成方波
            end else begin
                counter <= counter + 18'd1;  // 未到阈值，计数器递增
            end
        end
    end
endmodule
