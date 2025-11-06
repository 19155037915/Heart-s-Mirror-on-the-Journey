`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/30 14:19:42
// Design Name: 
// Module Name: ADC_read
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


module ADC_read(
input sys_clk,
input sys_rst_n,

output clk_driver,	//模块时钟管脚
input [12:0]IO_data,	//模块数据管脚

output [11:0]ADC_Data,//12位ADC数据
output ADC_OTR,			//信号过压标志位

output reg [11:0]  test_ecg_data,      // 测试心电数据
output reg         test_data_valid,   // 测试数据有效

output  [11:0] xinlv,
output  [11:0] hrv_sdnn,
output  [1:0] arrhythmia_level,
output  [11:0] rr_current,
output  [2:0] heart_state

);

wire clk_1M;
wire clk_25M;
wire clk_1k;

// 测试心电数据
reg [31:0]  test_counter;       // 测试计数器
reg [11:0]  ecg_wave_counter;   // 心电波形计数器

reg [11:0] sample_counter;
reg data_tvalid;
wire s_axis_data_tvalid;
wire s_axis_data_tready;
wire fir_m_axis_data_tvalid;
wire [31:0] fir_m_axis_data_tdata;

wire vnpd;
wire ecgstate;

clk_en clk_en_r(
.clk_in(sys_clk),
.rst_n(sys_rst_n),
.clk_1k(clk_1k),
.clk_25M(clk_25M),
.clk_1M(clk_1M)
);

/*
AD9226控制器：
将输入的260M时钟4分频(在AD9220_ReadModule.V中定义)后，用于驱动AD9226模块，并采集信号电压数据。
数据输入电压对应关系（受信号调理电路器件值公差影响，不同模块可能有微小差异）：
信号(-10V)~(+10V):数据(0~4095)
*/

AD9220_ReadModule U1_AD9220_ReadModule(
.clk(clk_1k),
.rstn(sys_rst_n),

.clk_driver(clk_driver),
.IO_data(IO_data),

.ADC_Data({ADC_OTR, ADC_Data})
);

fir_compiler_0 fir_compiler_0_r ( 
.aclk(clk_1M), // 100m 时钟 
.s_axis_data_tvalid(s_axis_data_tvalid), // fir 数据通道的输入数据有效使能 
.s_axis_data_tready(s_axis_data_tready), // fir 数据通道准备完成信号 
.s_axis_data_tdata({4'd0,ADC_Data}), // fir 数据通道的输入数据 
.m_axis_data_tvalid(fir_m_axis_data_tvalid), // fir 主机数据有效信号 
.m_axis_data_tdata(fir_m_axis_data_tdata) // fir 主机数据信号 
);

always@(posedge clk_1M or negedge sys_rst_n)
begin
    if(!sys_rst_n)begin
        sample_counter <= 12'd0;
        data_tvalid <= 1'b0;
    end
    else if (sample_counter == 12'd3999 && s_axis_data_tready) begin
        data_tvalid <= 1'b1;  // 只有FIR准备好时才发送
        sample_counter <= 12'd0;
    end
    else begin
        data_tvalid <= 1'b0;
        sample_counter <= sample_counter + 12'd1;
    end
end

assign s_axis_data_tvalid = data_tvalid;


ECG_detect m_ECG_detect(
	.clk(clk_driver),//conve_done采样频率
	.rest_n(sys_rst_n),
	.wave_data(fir_m_axis_data_tdata[23:12]),
	.vnpd(vnpd),
	.ecgstate(ecgstate),
	.xinlv(xinlv),
    .hrv_sdnn(hrv_sdnn),          // 心率变异性 (ms)
    .arrhythmia_level(arrhythmia_level),  // 心律失常等级
    .rr_current(rr_current),        // 当前RR间期 (ms)
    .heart_state(heart_state)        // 心脏状态分类
);

/*
reg [11:0] history [0:2];  // 3点历史数据
reg [11:0] smoothed;
reg [11:0] data_out;
parameter SMOOTH_THRESHOLD = 12'd20;  // 阈值：20LSB以内的变化进行平滑

always@(posedge clk_1M or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        history[0] <= 12'd2048;
        history[1] <= 12'd2048;
        history[2] <= 12'd2048;
        smoothed <= 12'd2048;
        data_out <= 12'd2048;
    end else begin
        // 更新历史数据
        history[0] <= fir_m_axis_data_tdata[23:12];
        history[1] <= history[0];
        history[2] <= history[1];
        
        // 计算变化量
        if (($signed(fir_m_axis_data_tdata[23:12]) - $signed(history[1]) < SMOOTH_THRESHOLD) && 
            ($signed(fir_m_axis_data_tdata[23:12]) - $signed(history[1]) > -SMOOTH_THRESHOLD)) begin
            // 小幅度变化：进行3点平均平滑
            smoothed <= (history[0] + history[1] + history[2]) / 3;
            data_out <= smoothed;
        end 
        else begin
            // 大幅度变化（可能是QRS波）：直接输出，保持陡峭边缘
            data_out <= fir_m_axis_data_tdata[23:12];
            smoothed <= fir_m_axis_data_tdata[23:12];
        end
    end
end
*/

endmodule

