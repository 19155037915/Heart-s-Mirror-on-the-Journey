`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/06 16:35:50
// Design Name: 
// Module Name: ecg_parameter_simulator
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


`timescale 1ns / 1ps

module ecg_parameter_simulator(
    input wire clk,              // 时钟信号
    input wire rst_n,            // 复位信号
    input wire [2:0] data_sel,   // 模式选择: 1-正常心律, 2-心率过速, 3-HRV过低
    output reg [11:0] heart_rate,    // 心率输出 (bpm)
    output reg [11:0] rr_interval,   // RR间期输出 (ms)
    output reg [11:0] hrv_value      // HRV值输出 (ms)
);

    // 内部寄存器
    reg [31:0] counter;
    reg [15:0] lfsr1, lfsr2, lfsr3;  // 三个独立的LFSR
    reg [11:0] base_hr, base_rr, base_hrv;
    reg [15:0] update_counter;       // 扩大计数器位宽
    
    // 更新间隔参数 - 大幅增加更新间隔，模拟真实生理变化
    parameter UPDATE_INTERVAL_NORMAL = 16'd50;   // 正常心律更新间隔 (约1秒)
    parameter UPDATE_INTERVAL_TACHY = 16'd44;     // 心率过速更新间隔 (约0.8秒)  
    parameter UPDATE_INTERVAL_LOW = 16'd50;      // HRV过低更新间隔 (约1.5秒)
    
    // 三个独立的LFSR伪随机数生成器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr1 <= 16'hACE1;
            lfsr2 <= 16'hBEEF;
            lfsr3 <= 16'hCAFE;
        end else begin
            lfsr1 <= {lfsr1[14:0], lfsr1[15] ^ lfsr1[13] ^ lfsr1[12] ^ lfsr1[10]};
            lfsr2 <= {lfsr2[14:0], lfsr2[15] ^ lfsr2[12] ^ lfsr2[11] ^ lfsr2[9]};
            lfsr3 <= {lfsr3[14:0], lfsr3[15] ^ lfsr3[14] ^ lfsr3[13] ^ lfsr3[11]};
        end
    end
    
    // 根据模式选择基础参数和更新条件
    reg update_enable;
    reg [15:0] current_update_interval;
    
    always @(*) begin
        case(data_sel)
            3'd1: begin // 正常心律 - 基于您提供的参数
                base_hr = 12'd76;     // 平均心率75.7 -> 76 bpm
                base_rr = 12'd793;    // 平均RR间期793 ms
                base_hrv = 12'd41;    // HRV 40.7 -> 41 ms
                current_update_interval = UPDATE_INTERVAL_NORMAL;
            end
            3'd2: begin // 心率过速 - 中等波动
                base_hr = 12'd123;
                base_rr = 12'd497;
                base_hrv = 12'd89;
                current_update_interval = UPDATE_INTERVAL_TACHY;
            end
            3'd3: begin // HRV过低 - 很小波动
                base_hr = 12'd75;
                base_rr = 12'd800;
                base_hrv = 12'd9;
                current_update_interval = UPDATE_INTERVAL_LOW;
            end
            default: begin
                base_hr = 12'd76;
                base_rr = 12'd793;
                base_hrv = 12'd41;
                current_update_interval = UPDATE_INTERVAL_NORMAL;
            end
        endcase
        
        // 更新使能信号
        update_enable = (update_counter >= current_update_interval);
    end
    
    // 更新计数器 - 使用更大的计数范围
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            update_counter <= 0;
        end else begin
            if (update_counter >= current_update_interval) begin
                update_counter <= 0;
            end else begin
                update_counter <= update_counter + 1;
            end
        end
    end
    
    // 参数生成 - 添加更平滑的变化
    reg [11:0] next_heart_rate, next_rr_interval, next_hrv_value;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            heart_rate <= 12'd76;
            rr_interval <= 12'd793;
            hrv_value <= 12'd41;
        end else if (update_enable) begin
            case(data_sel)
                3'd1: begin // 正常心律 - 适度波动
                    // 心率：72-79 bpm范围内的适度波动（每次变化±1-2 bpm）
                    next_heart_rate = 12'd72 + (lfsr1[3:0] % 12'd8);
                    heart_rate <= (next_heart_rate > heart_rate + 2) ? heart_rate + 2 : 
                                 (next_heart_rate < heart_rate - 2) ? heart_rate - 2 : next_heart_rate;
                    
                    // RR间期：760-820 ms范围内的适度波动（每次变化±5-10 ms）
                    next_rr_interval = 12'd760 + (lfsr2[4:0] % 12'd61);
                    rr_interval <= (next_rr_interval > rr_interval + 10) ? rr_interval + 10 : 
                                  (next_rr_interval < rr_interval - 10) ? rr_interval - 10 : next_rr_interval;
                    
                    // HRV：35-47 ms范围内的适度波动（每次变化±1-3 ms）
                    next_hrv_value = 12'd35 + (lfsr3[3:0] % 12'd13);
                    hrv_value <= (next_hrv_value > hrv_value + 3) ? hrv_value + 3 : 
                                (next_hrv_value < hrv_value - 3) ? hrv_value - 3 : next_hrv_value;
                end
                3'd2: begin // 心率过速 - 在103-170范围内波动
                    // 心率：103-170 bpm，每次变化±3-5 bpm
                    next_heart_rate = 12'd103 + (lfsr1[6:0] % 12'd68);
                    heart_rate <= (next_heart_rate > heart_rate + 5) ? heart_rate + 5 : 
                                 (next_heart_rate < heart_rate - 5) ? heart_rate - 5 : next_heart_rate;
                    
                    // RR间期：353-582 ms，每次变化±10-20 ms
                    next_rr_interval = 12'd353 + (lfsr2[6:0] % 12'd230);
                    rr_interval <= (next_rr_interval > rr_interval + 20) ? rr_interval + 20 : 
                                  (next_rr_interval < rr_interval - 20) ? rr_interval - 20 : next_rr_interval;
                    
                    // HRV：70-110 ms，每次变化±5-8 ms
                    next_hrv_value = 12'd70 + (lfsr3[6:0] % 12'd41);
                    hrv_value <= (next_hrv_value > hrv_value + 8) ? hrv_value + 8 : 
                                (next_hrv_value < hrv_value - 8) ? hrv_value - 8 : next_hrv_value;
                end
                3'd3: begin // HRV过低 - 非常稳定
                    // 心率：74-76 bpm很小波动，每次变化±1 bpm
                    next_heart_rate = 12'd74 + (lfsr1[2:0] % 12'd3);
                    heart_rate <= (next_heart_rate > heart_rate + 1) ? heart_rate + 1 : 
                                 (next_heart_rate < heart_rate - 1) ? heart_rate - 1 : next_heart_rate;
                    
                    // RR间期：788-812 ms很小波动，每次变化±2-4 ms
                    next_rr_interval = 12'd788 + (lfsr2[3:0] % 12'd25);
                    rr_interval <= (next_rr_interval > rr_interval + 4) ? rr_interval + 4 : 
                                  (next_rr_interval < rr_interval - 4) ? rr_interval - 4 : next_rr_interval;
                    
                    // HRV：8-11 ms极小波动，每次变化±1 ms
                    next_hrv_value = 12'd8 + (lfsr3[1:0] % 12'd4);
                    hrv_value <= (next_hrv_value > hrv_value + 1) ? hrv_value + 1 : 
                                (next_hrv_value < hrv_value - 1) ? hrv_value - 1 : next_hrv_value;
                end
                default: begin
                    heart_rate <= base_hr;
                    rr_interval <= base_rr;
                    hrv_value <= base_hrv;
                end
            endcase
        end
    end

endmodule