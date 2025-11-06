`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/23 22:21:53
// Design Name: 
// Module Name: ui_state_machine
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
//界面状态机模块
// ui_state_machine.v

`timescale 1ns / 1ps

module ui_state_machine(
    input               clk,
    input               rst_n,
    input      [31:0]   touch_data,    // 触摸坐标数据
    input               touch_valid,   // 触摸数据有效
    output reg [1:0]    ui_state,      // 界面状态
    output reg [2:0]    data_state,
    output reg [2:0]    data_sel
);

// 界面状态定义
localparam MAIN_MENU     = 2'b00;    // 主界面
localparam ECG_DISPLAY   = 2'b01;    // 显示心电图界面
localparam HEART_RATE_REVIEW = 2'b10; // 心率回看界面

// 触摸坐标
wire [10:0] touch_x = touch_data[26:16];
wire [10:0] touch_y = touch_data[10:0];

// 触摸坐标变化检测
reg [31:0] prev_touch_data;
wire touch_changed = (touch_data != prev_touch_data);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        prev_touch_data <= 32'b0;
    end else begin
        prev_touch_data <= touch_data;
    end
end

//按键区域定义
localparam xdt_X_START = 11'd62;
localparam xdt_X_END = 11'd412;
localparam xdt_Y_START = 11'd475;
localparam xdt_Y_END = 11'd575;

localparam save_X_START = 11'd487;
localparam save_X_END = 11'd687;
localparam save_Y_START = 11'd475;
localparam save_Y_END = 11'd575;

localparam search_X_START = 11'd762;
localparam search_X_END = 11'd962;
localparam search_Y_START = 11'd475;
localparam search_Y_END = 11'd575;

//子界面按键区域
localparam return_X_START = 11'd72;
localparam return_X_END = 11'd272;
localparam return_Y_START = 11'd25;
localparam return_Y_END = 11'd125;

localparam sel_X_START = 11'd156;
localparam sel_X_END = 11'd356;
localparam sel_Y_START = 11'd495;
localparam sel_Y_END = 11'd595;

localparam del_X_START = 11'd668;
localparam del_X_END = 11'd868;
localparam del_Y_START = 11'd495;
localparam del_Y_END = 11'd595;

localparam data1_X_START = 11'd312;
localparam data1_X_END = 11'd712;
localparam data1_Y_START = 11'd100;
localparam data1_Y_END = 11'd180;

localparam data2_X_START = 11'd312;
localparam data2_X_END = 11'd712;
localparam data2_Y_START = 11'd200;
localparam data2_Y_END = 11'd280;

localparam data3_X_START = 11'd312;
localparam data3_X_END = 11'd712;
localparam data3_Y_START = 11'd300;
localparam data3_Y_END = 11'd380;

localparam data4_X_START = 11'd312;
localparam data4_X_END = 11'd712;
localparam data4_Y_START = 11'd400;
localparam data4_Y_END = 11'd480;

// 状态机
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ui_state <= MAIN_MENU;
        data_state <= 3'd0;
        data_sel <= 3'd0;
    end else begin
        case (ui_state)
            MAIN_MENU: begin
                // 检测主界面按钮点击（只在坐标变化时响应）
                if (touch_changed) begin
                    if (touch_x >= xdt_X_START && touch_x <= xdt_X_END &&
                        touch_y >= xdt_Y_START && touch_y <= xdt_Y_END) begin
                        ui_state <= ECG_DISPLAY;
                    end else if (touch_x >= search_X_START && touch_x <= search_X_END &&
                               touch_y >= search_Y_START && touch_y <= search_Y_END) begin
                        ui_state <= HEART_RATE_REVIEW;
                        data_sel <= 3'd0;
                    end else if (touch_x >= save_X_START && touch_x <= save_X_END &&
                               touch_y >= save_Y_START && touch_y <= save_Y_END) begin
                          data_state <= data_state + 3'd1;
                          if(data_state >= 3'd5)begin
                            data_state <= 3'd4;
                          end
                    end
                end
            end
            
            ECG_DISPLAY: begin
                // 检测返回按钮点击（只在坐标变化时响应）
                if (touch_changed && touch_x >= return_X_START && touch_x <= return_X_END &&
                    touch_y >= return_Y_START && touch_y <= return_Y_END) begin
                    ui_state <= MAIN_MENU;
                end
            end
            
            HEART_RATE_REVIEW: begin
                // 检测各种按钮点击（只在坐标变化时响应）
                if (touch_changed) begin
                    if (touch_x >= return_X_START && touch_x <= return_X_END &&
                        touch_y >= return_Y_START && touch_y <= return_Y_END) begin
                        ui_state <= MAIN_MENU;
                    end else if (touch_x >= data1_X_START && touch_x <= data1_X_END &&
                        touch_y >= data1_Y_START && touch_y <= data1_Y_END) begin
                        data_sel <= 3'd1;
                    end else if (touch_x >= data2_X_START && touch_x <= data2_X_END &&
                        touch_y >= data2_Y_START && touch_y <= data2_Y_END) begin
                        data_sel <= 3'd2;
                    end else if (touch_x >= data3_X_START && touch_x <= data3_X_END &&
                        touch_y >= data3_Y_START && touch_y <= data3_Y_END) begin
                        data_sel <= 3'd3;
                    end else if (touch_x >= data4_X_START && touch_x <= data4_X_END &&
                        touch_y >= data4_Y_START && touch_y <= data4_Y_END) begin
                        data_sel <= 3'd4;
                    end else if (touch_x >= sel_X_START && touch_x <= sel_X_END &&
                        touch_y >= sel_Y_START && touch_y <= sel_Y_END && data_sel != 3'd0) begin
                        ui_state <= MAIN_MENU;
                    end else if (touch_x >= del_X_START && touch_x <= del_X_END &&
                        touch_y >= del_Y_START && touch_y <= del_Y_END && data_sel != 3'd0) begin
                        data_state <= data_state - 3'd1;
                        data_sel <= 3'd0;
                    end
                end
            end
            
            default: ui_state <= MAIN_MENU;
        endcase
    end
end

endmodule