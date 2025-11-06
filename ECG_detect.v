`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/18 15:19:48
// Design Name: 
// Module Name: ECG_detect
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

/*
module ECG_detect(
	clk,//conve_done采样频率
	rest_n,
	wave_data,
	vnpd,
	ecgstate,
	xinlv
);

	input	clk;//cove_done adc转换完成
	input rest_n;
	input [11:0]wave_data;
	reg [13:0]xinlvreg[9:0];
	output reg ecgstate;
	output reg [11:0] xinlv;
	output reg vnpd;
	
	parameter vnn = 12'd3000;	//波峰阈值
	parameter vnv = 12'd2048; 	//波谷阈值
	parameter fs60s = 14'd15000;	//采样频率*60s 250*60 = 15,000 2^14=16,384
	
	reg vn;
	reg btn1;
	reg btn2;

	reg [9:0]count;
	reg [15:0] xinlv_all;
	
	always@(posedge clk)
	begin if(wave_data >= vnn)
		vn <= 1;
	else if(wave_data <= vnv)
		vn <= 0;
	else 
		vn <= vn;
	end
	
	always@(posedge clk)
	begin 
		btn1 <= vn;
		btn2 <= btn1;
		vnpd <= btn1 & ~btn2;//vn上升沿
	end
	
	always@(posedge clk or negedge rest_n)
	if(!rest_n)
	begin
		xinlv_all <= 0;
		xinlv <= 0;
		xinlvreg[0] <=	85;
		xinlvreg[1] <=	85;
		xinlvreg[2] <=	85;
		xinlvreg[3] <=	85;
		count <= 0;
		ecgstate <= 0;
	end
	
	else
	begin 
	if(count <= 600)
		begin
			if(vnpd == 1)begin
				xinlvreg[0] <= fs60s/count; 
				xinlvreg[1] <= xinlvreg[0];
				xinlvreg[2] <= xinlvreg[1];
				xinlvreg[3] <= xinlvreg[2];
				xinlv_all <= xinlvreg[0] + xinlvreg[1] + xinlvreg[2] + xinlvreg[3] ;
				xinlv <= (xinlv_all >> 2);
				count <= 0;
				if(200 < xinlv_all < 400)
					ecgstate <= 0;
				else
					ecgstate <= 1;
			end
			else
				begin
				count <= count + 1; //心率 = fs * 60s / count
				end
		end
		
	else
		begin
			xinlv_all <= 0;
			xinlv <= 0;
			count <= 0;
			ecgstate <= 1;
		end
	end
	
endmodule	
*/
/*
module ECG_detect(
    clk, rest_n, wave_data,
    vnpd, ecgstate, xinlv,
    hrv_sdnn, arrhythmia_level, rr_current, heart_state
);

input clk, rest_n;
input [11:0] wave_data;
output reg vnpd, ecgstate;
output reg [11:0] xinlv;
output reg [11:0] hrv_sdnn;
output reg [1:0] arrhythmia_level;
output reg [11:0] rr_current;
output reg [2:0] heart_state;

// 系统参数定义
parameter vnn = 12'd3000;
parameter vnv = 12'd2048;

integer i;
reg [15:0] avg_rr;
reg [31:0] var_sum;

// 内部寄存器定义
reg vn, btn1, btn2;
reg [10:0] count;
reg [13:0] xinlvreg[4:0];
reg [15:0] xinlv_all;

// HRV相关寄存器
reg [11:0] rr_history [31:0];
reg [4:0] rr_ptr;
reg [31:0] rr_sum;
reg [5:0] data_valid;

// 心律失常检测寄存器
reg [2:0] consecutive_abnormal;
reg [11:0] last_rr;

// 采样点数转换为毫秒
function [11:0] samples_to_ms;
    input [10:0] samples;
    begin
        samples_to_ms = samples * 4;
    end
endfunction

// 计算心率BPM - 修复除零问题
function [11:0] calculate_bpm;
    input [10:0] interval_samples;
    reg [23:0] denominator;
    begin
        if(interval_samples == 0) 
            calculate_bpm = 0;
        else begin
            denominator = interval_samples * 4;
            if(denominator == 0)
                calculate_bpm = 0;
            else
                calculate_bpm = 60000 / denominator;
        end
    end
endfunction

// 简单的开方近似
function [11:0] sqrt_approx;
    input [31:0] value;
    reg [31:0] temp, res;
    integer k;
    begin
        if(value == 0) begin
            sqrt_approx = 0;
        end else begin
            res = 0;
            temp = value;
            for(k = 15; k >= 0; k = k - 1) begin
                if(temp >= ((res << (k + 1)) + (1 << (2 * k)))) begin
                    temp = temp - ((res << (k + 1)) + (1 << (2 * k)));
                    res = res + (1 << k);
                end
            end
            sqrt_approx = res[11:0];
        end
    end
endfunction

// 波峰检测逻辑
always@(posedge clk) begin
    if(wave_data >= vnn)
        vn <= 1;
    else if(wave_data <= vnv)
        vn <= 0;
    else 
        vn <= vn;
end

// 上升沿检测逻辑
always@(posedge clk) begin
    btn1 <= vn;
    btn2 <= btn1;
    vnpd <= btn1 & ~btn2;
end

// 主要处理逻辑
always@(posedge clk or negedge rest_n) begin
    if(!rest_n) begin
        // 复位所有寄存器
        xinlv_all <= 0;
        xinlv <= 0;
        for(i = 0; i < 5; i = i + 1) 
            xinlvreg[i] <= 75;
        count <= 0;
        ecgstate <= 0;
        
        hrv_sdnn <= 0;
        arrhythmia_level <= 0;
        rr_current <= 0;
        heart_state <= 0;
        rr_ptr <= 0;
        rr_sum <= 0;
        data_valid <= 0;
        consecutive_abnormal <= 0;
        last_rr <= 800;  // 初始化为正常RR间期(750ms对应80BPM)
        
        for(i = 0; i < 32; i = i + 1) 
            rr_history[i] <= 800;
    end
    else begin
        if(count <= 600) begin
            if(vnpd == 1) begin  // 检测到心跳
                // 1. 计算当前RR间期
                rr_current <= count * 4;
                
                // 2. 心率计算 - 添加边界检查
                if(count >= 10) begin  // 最小心率约25BPM
                    xinlvreg[0] <= calculate_bpm(count);
                end else begin
                    xinlvreg[0] <= 0;
                end
                
                for(i = 1; i < 5; i = i + 1)
                    xinlvreg[i] <= xinlvreg[i-1];
                
                // 计算平均心率，跳过0值
                if(xinlvreg[0] != 0 && xinlvreg[1] != 0 && xinlvreg[2] != 0 && 
                   xinlvreg[3] != 0 && xinlvreg[4] != 0) 
                begin
                    xinlv_all <= xinlvreg[0] + xinlvreg[1] + xinlvreg[2] + 
                                xinlvreg[3] + xinlvreg[4];
                    xinlv <= xinlv_all / 5;
                end
                
                // 3. HRV计算
                if(count >= 10) begin  // 有效心跳
                    rr_history[rr_ptr] <= rr_current;
                    
                    if(data_valid == 32) begin
                        rr_sum <= rr_sum - rr_history[rr_ptr] + rr_current;
                    end else begin
                        rr_sum <= rr_sum + rr_current;
                        data_valid <= data_valid + 1;
                    end
                    rr_ptr <= (rr_ptr == 31) ? 0 : rr_ptr + 1;
                    
                    // HRV计算
                    if(data_valid >= 8) begin
                        avg_rr = rr_sum / data_valid;
                        var_sum = 0;
                        
                        for(i = 0; i < data_valid; i = i + 1) begin
                            if(avg_rr > rr_history[i]) begin
                                var_sum = var_sum + (avg_rr - rr_history[i]) * (avg_rr - rr_history[i]);
                            end else begin
                                var_sum = var_sum + (rr_history[i] - avg_rr) * (rr_history[i] - avg_rr);
                            end
                        end
                        
                        if(var_sum > 0) begin
                            hrv_sdnn <= sqrt_approx(var_sum / data_valid);
                        end else begin
                            hrv_sdnn <= 0;
                        end
                    end
                    
                    // 4. 心律失常检测
                    if(data_valid >= 4) begin
                        avg_rr = rr_sum / data_valid;
                        
                        // 实时异常检测
                        if(rr_current > (avg_rr * 13) / 10 ||  // 超过30%
                           rr_current < (avg_rr * 7) / 10)      // 低于30%
                        begin
                            // 严重异常：RR间期翻倍或减半
                            if(rr_current > avg_rr * 2 || rr_current < avg_rr / 2) begin
                                arrhythmia_level <= 2;
                                consecutive_abnormal <= 3;
                            end 
                            // 连续异常
                            else if(consecutive_abnormal >= 2) begin
                                arrhythmia_level <= 2;
                                if(consecutive_abnormal < 3)
                                    consecutive_abnormal <= consecutive_abnormal + 1;
                            end
                            else begin
                                arrhythmia_level <= 1;
                                if(consecutive_abnormal < 3)
                                    consecutive_abnormal <= consecutive_abnormal + 1;
                            end
                        end 
                        else begin
                            // 正常心跳
                            if(consecutive_abnormal > 0) begin
                                consecutive_abnormal <= consecutive_abnormal - 1;
                            end
                            
                            // 更新心律失常等级
                            if(consecutive_abnormal == 0) begin
                                arrhythmia_level <= 0;
                            end
                            else if(consecutive_abnormal == 1) begin
                                arrhythmia_level <= 1;
                            end
                            else begin
                                arrhythmia_level <= 2;
                            end
                        end
                        
                        last_rr <= rr_current;
                    end
                end
                
                // 5. 心脏状态分类
                if(xinlv >= 60 && xinlv <= 100) begin
                    if(arrhythmia_level == 0)
                        heart_state <= 0;  // 正常
                    else if(arrhythmia_level == 1)
                        heart_state <= 3;  // 轻度心律失常
                    else
                        heart_state <= 4;  // 严重心律失常
                end
                else if(xinlv < 60 && xinlv > 0)
                    heart_state <= 1;      // 心动过缓
                else if(xinlv > 100)
                    heart_state <= 2;      // 心动过速
                else
                    heart_state <= 4;      // 无效心率值
                
                // ECG总体状态
                ecgstate <= (arrhythmia_level == 0 && xinlv >= 60 && xinlv <= 100) ? 0 : 1;
                
                count <= 0;
                    
            end else begin
                count <= count + 1;
            end
        end else begin
            // 超时处理
            xinlv <= 0;
            count <= 0;
            ecgstate <= 1;
            arrhythmia_level <= 2;
            heart_state <= 4;
            consecutive_abnormal <= 3;
        end
    end
end

endmodule

*/

module ECG_detect(
    clk, rest_n, wave_data,
    vnpd, ecgstate, xinlv,
    hrv_sdnn, arrhythmia_level, rr_current, heart_state
);

input clk, rest_n;
input [11:0] wave_data;
output reg vnpd, ecgstate;
output reg [11:0] xinlv;
output reg [11:0] hrv_sdnn;
output reg [1:0] arrhythmia_level;
output reg [11:0] rr_current;
output reg [2:0] heart_state;

// 系统参数定义
parameter vnn = 12'd3000;
parameter vnv = 12'd2048;

// 内部寄存器定义
reg vn, btn1, btn2;
reg [10:0] count;
reg [15:0] rr_interval;  // 当前RR间期(ms)
reg [15:0] last_rr;      // 上次RR间期

// 心率平滑滤波
reg [15:0] rr_buffer [3:0];  // RR间期缓冲区
reg [1:0] rr_index;
reg [17:0] rr_sum;           // RR间期和

reg [15:0] avg_rr;
reg [15:0] variance;
reg [3:0] valid_count;
integer i;

// 准确的心率计算
function [11:0] accurate_bpm_calculate;
    input [15:0] rr_ms;
    reg [23:0] temp;
    begin
        if(rr_ms == 0) begin
            accurate_bpm_calculate = 0;
        end else begin
            // BPM = 60000 / RR_ms
            // 使用移位和加法来近似除法
            temp = 60000 * 64 / rr_ms;  // 放大64倍避免小数
            accurate_bpm_calculate = temp[17:6];  // 除以64得到实际值
        end
    end
endfunction

// 简化的开方计算
function [11:0] simple_sqrt;
    input [15:0] x;
    reg [15:0] res, bit;
    integer i;
    begin
        if(x == 0) begin
            simple_sqrt = 0;
        end else begin
            res = 0;
            bit = 1 << 14;  // 从最高位开始
            
            for(i = 0; i < 8; i = i + 1) begin  // 减少迭代次数
                if(x >= (res | bit)) begin
                    x = x - (res | bit);
                    res = (res >> 1) | bit;
                end else begin
                    res = res >> 1;
                end
                bit = bit >> 2;
            end
            simple_sqrt = res[11:0];
        end
    end
endfunction

// 波峰检测逻辑 - 增加去抖动
reg [2:0] peak_filter;
always@(posedge clk) begin
    peak_filter <= {peak_filter[1:0], (wave_data >= vnn)};
    
    // 多数表决去抖动
    if(peak_filter[2] + peak_filter[1] + peak_filter[0] >= 2)
        vn <= 1;
    else if(wave_data <= vnv)
        vn <= 0;
end

// 上升沿检测逻辑
always@(posedge clk) begin
    btn1 <= vn;
    btn2 <= btn1;
    vnpd <= btn1 & ~btn2;
end

// 主要处理逻辑
always@(posedge clk or negedge rest_n) begin
    if(!rest_n) begin
        // 复位所有寄存器
        count <= 0;
        rr_interval <= 0;
        last_rr <= 750;  // 初始化为750ms (80BPM)
        xinlv <= 80;
        ecgstate <= 0;
        
        // 初始化RR缓冲区
        rr_index <= 0;
        rr_sum <= 750 * 4;
        for(i = 0; i < 4; i = i + 1)
            rr_buffer[i] <= 750;
        
        hrv_sdnn <= 0;
        arrhythmia_level <= 0;
        rr_current <= 750;
        heart_state <= 0;
    end
    else begin
        // 计数器递增
        count <= count + 1;
        
        if(vnpd == 1) begin  // 检测到心跳
            // 计算RR间期(ms)
            rr_interval <= count * 4;
            rr_current <= count * 4;
            
            // 更新RR缓冲区
            rr_buffer[rr_index] <= rr_interval;
            rr_index <= rr_index + 1;
            
            // 计算平均RR间期
            rr_sum <= rr_buffer[0] + rr_buffer[1] + rr_buffer[2] + rr_buffer[3];
            avg_rr <= rr_sum >> 2;  // 除以4
            
            // 准确的心率计算
            if(avg_rr >= 300 && avg_rr <= 2000) begin  // 有效心率范围30-200BPM
                xinlv <= accurate_bpm_calculate(avg_rr);
                
                // 边界检查
                if(xinlv < 30) xinlv <= 30;
                if(xinlv > 200) xinlv <= 200;
            end else begin
                xinlv <= 0;
            end
            
            // HRV计算 (使用4个RR间期的标准差)
            if(rr_index == 0) begin  // 缓冲区满时计算
                variance = 0;
                for(i = 0; i < 4; i = i + 1) begin
                    if(avg_rr > rr_buffer[i]) begin
                        variance = variance + (avg_rr - rr_buffer[i]) * (avg_rr - rr_buffer[i]);
                    end else begin
                        variance = variance + (rr_buffer[i] - avg_rr) * (rr_buffer[i] - avg_rr);
                    end
                end
                variance = variance >> 2;  // 除以4求平均方差
                hrv_sdnn <= simple_sqrt(variance);
            end
            
            // 心律失常检测
            if(last_rr != 0) begin
                // 检查RR间期变化是否超过25%
                if((rr_interval > (last_rr * 5) / 4) ||  // 增加25%
                   (rr_interval < (last_rr * 3) / 4))    // 减少25%
                begin
                    if(arrhythmia_level < 2)
                        arrhythmia_level <= arrhythmia_level + 1;
                end else begin
                    if(arrhythmia_level > 0)
                        arrhythmia_level <= arrhythmia_level - 1;
                end
            end
            
            last_rr <= rr_interval;
            
            // 心脏状态分类
            if(xinlv >= 60 && xinlv <= 100) begin
                if(arrhythmia_level == 0)
                    heart_state <= 0;  // 正常
                else if(arrhythmia_level == 1)  
                    heart_state <= 3;  // 轻度异常
                else
                    heart_state <= 4;  // 严重异常
            end
            else if(xinlv > 0 && xinlv < 60)
                heart_state <= 1;      // 心动过缓
            else if(xinlv > 100)
                heart_state <= 2;      // 心动过速
            else
                heart_state <= 5;      // 无效
            
            ecgstate <= (heart_state == 0) ? 0 : 1;
            
            count <= 0;
        end
        
        // 超时检测 (3秒无心跳)
        if(count > 750) begin  // 750 * 4ms = 3000ms
            xinlv <= 0;
            ecgstate <= 1;
            heart_state <= 5;
            arrhythmia_level <= 2;
        end
    end
end

endmodule