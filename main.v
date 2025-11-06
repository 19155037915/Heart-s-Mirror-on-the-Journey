`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/23 21:43:26
// Design Name: 
// Module Name: main
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

// 修改后的 top_lcd_touch.v
module main(
    //时钟和复位接口
    input            sys_clk    ,  //系统时钟信号
    input            sys_rst_n  ,  //系统复位信号
    //TOUCH 接口                  
    inout            touch_sda  ,  //TOUCH IIC数据
    output           touch_scl  ,  //TOUCH IIC时钟
    inout            touch_int  ,  //TOUCH INT信号
    output           touch_rst_n,  //TOUCH 复位信号
    //RGB LCD接口                 
    output           lcd_de     ,  //LCD 数据使能信号
    output           lcd_hs     ,  //LCD 行同步信号
    output           lcd_vs     ,  //LCD 场同步信号
    output           lcd_bl     ,  //LCD 背光控制信号
    output           lcd_clk    ,  //LCD 像素时钟
    output           lcd_rst_n  ,  //LCD 复位
    inout    [23:0]  lcd_rgb    ,    //LCD RGB颜色数据

    output clk_driver,	//模块时钟管脚
    input [12:0]IO_data	,//模块数据管脚
    
    input                sd_miso     , //SPI
    output               sd_clk      , //SPI
    output               sd_cs       , //SPI
    output               sd_mosi       
);

//wire define
wire  [15:0]  lcd_id     ;      //LCD屏ID
wire  [31:0]  touch_data ;      //触摸点坐标
wire          touch_valid;      //触摸数据有效信号
wire  [1:0]   ui_state   ;      //界面状态
wire  [2:0]   data_state ;
wire  [2:0]   data_sel   ;

//ADC
wire [11:0] test_ecg_data;      // 测试心电数据
wire test_data_valid;
wire [11:0] ADC_Data;//12位ADC数据
wire ADC_OTR;		//信号过压标志位
wire [11:0] xinlv;
wire [11:0] hrv_sdnn;
wire [1:0] arrhythmia_level;
wire [11:0] rr_current;
wire [2:0] heart_state;

wire [11:0] xinlv2;
wire [11:0] hrv_sdnn2;
wire [1:0] arrhythmia_level2;
wire [11:0] rr_current2;

wire [11:0] xinlv1;
wire [11:0] hrv_sdnn1;
wire [1:0] arrhythmia_level1;
wire [11:0] rr_current1;
wire [2:0] heart_state1;

// 触摸有效信号判断
assign touch_valid = (touch_data[31:16] != 16'd0 && touch_data[15:0] != 16'd0);

//*****************************************************
//**                    main code
//*****************************************************                                       

//触摸驱动顶层模块    
touch_top  u_touch_top(
    .clk            (sys_clk    ),
    .rst_n          (sys_rst_n  ),

    .touch_rst_n    (touch_rst_n),
    .touch_int      (touch_int  ),
    .touch_scl      (touch_scl  ),
    .touch_sda      (touch_sda  ),
    
    .lcd_id         (lcd_id     ),
    .data           (touch_data )
);

// 界面状态机模块
ui_state_machine u_ui_state_machine(
    .clk            (sys_clk),
    .rst_n          (sys_rst_n),
    .touch_data     (touch_data),
    .touch_valid    (touch_valid),
    .ui_state       (ui_state),
    .data_state     (data_state),
    .data_sel       (data_sel)
);
      
//例化LCD显示模块 - 修改后的支持多界面
lcd_ui_display  u_lcd_ui_display(
   .sys_clk         (sys_clk    ),
   .sys_rst_n       (sys_rst_n  ),
   .touch_data      (touch_data ),
   .ui_state        (ui_state   ),
   .data_state      (data_state ),
   .data_sel        (data_sel   ),
   .lcd_id          (lcd_id     ),
   //ADC部分数据
   .xinlv(xinlv),
   .hrv_sdnn(hrv_sdnn),
   .arrhythmia_level(arrhythmia_level),
   .rr_current(rr_current),
   //RGB LCD接口 
   .lcd_hs          (lcd_hs     ),
   .lcd_vs          (lcd_vs     ),
   .lcd_de          (lcd_de     ),
   .lcd_rgb         (lcd_rgb    ),
   .lcd_bl          (lcd_bl     ),
   .lcd_rst_n       (lcd_rst_n  ),
   .lcd_clk         (lcd_clk    )
);


ADC_read u_ADC_read(
.sys_clk(sys_clk),
.sys_rst_n(sys_rst_n),

.clk_driver(clk_driver),	//模块时钟管脚
.IO_data(IO_data),	//模块数据管脚

.ADC_Data(ADC_Data),//12位ADC数据
.ADC_OTR(ADC_OTR),			//信号过压标志位

.test_ecg_data(test_ecg_data),      // 测试心电数据
.test_data_valid(test_data_valid),   // 测试数据有效

.xinlv(xinlv1),
.hrv_sdnn(hrv_sdnn1),
.arrhythmia_level(arrhythmia_level1),
.rr_current(rr_current1),
.heart_state(heart_state1)

);

ecg_parameter_simulator u_ecg_parameter_simulator(
.clk(clk_driver),              // 时钟信号
.rst_n(sys_rst_n),            // 复位信号
.data_sel(data_sel),   // 模式选择: 1-心律不齐, 2-心率过速, 3-HRV过低
.heart_rate(xinlv2),    // 心率输出 (bpm)
.rr_interval(rr_current2),   // RR间期输出 (ms)
.hrv_value(hrv_sdnn2)      // HRV值输出 (ms)
);


top_sd_rw u_top_sd_rw(
    .sys_clk              (sys_clk),    
    .sys_rst_n            (sys_rst_n),    
                                    
    //SD
    .sd_miso              (sd_miso),  
    .sd_write_data        (test_ecg_data), 
    .statue               (data_sel),
    .sd_clk               (sd_clk),  
    .sd_cs                (sd_cs), 
    .sd_mosi              (sd_mosi) 
    );
    
assign arrhythmia_level = (data_sel == 3'd0 || data_sel==3'd1) ? 2'd0 : 2'd1;

// 组合逻辑选择器
assign xinlv = (data_sel == 3'd0) ? xinlv1 : xinlv2;
assign hrv_sdnn = (data_sel == 3'd0) ? hrv_sdnn1 : hrv_sdnn2;
assign rr_current = (data_sel == 3'd0) ? rr_current1 : rr_current2;

endmodule
