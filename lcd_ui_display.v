`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/23 22:23:24
// Design Name: 
// Module Name: lcd_ui_display
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


module lcd_ui_display(
    input              sys_clk   ,
    input              sys_rst_n ,
    
    input      [31:0]  touch_data,  // 触摸坐标数据
    input      [1:0]   ui_state  ,  // 界面状态
    input      [2:0]   data_state,
    input      [2:0]   data_sel  ,
    
    input      [15:0]  lcd_id    ,
    //ADC部分数据
    input      [11:0]  xinlv,
    input      [11:0] hrv_sdnn,
    input      [1:0] arrhythmia_level,
    input      [11:0] rr_current,

    //RGB LCD接口 
    output             lcd_hs    , //LCD 行同步信号
    output             lcd_vs    , //LCD 场同步信号
    output             lcd_de    , //LCD 数据输入使能
    inout      [23:0]  lcd_rgb   , //LCD RGB颜色数据
    output             lcd_bl    , //LCD 背光控制信号
    output             lcd_clk   , //LCD 采样时钟
    output             lcd_rst_n   //LCD复位
);

//wire define
wire  [10:0]  pixel_xpos_w ;
wire  [10:0]  pixel_ypos_w ;
wire  [23:0]  pixel_data_w ;
wire  [23:0]  lcd_rgb_o    ;
wire          lcd_pclk     ;

wire  [15:0]  xinlv_bcd    ;
wire  [15:0]  RR_bcd       ;
wire  [15:0]  HRV_bcd      ;

wire  [31:0]  data;//后面删了

// 直接使用原始触摸坐标，不要转换为BCD
wire [15:0] touch_x = touch_data[31:16];
wire [15:0] touch_y = touch_data[15:0];

//*****************************************************
//**                    main code
//*****************************************************

//RGB数据输出
assign lcd_rgb = lcd_de ? lcd_rgb_o : {24{1'bz}};

//读rgb lcd ID 模块
rd_id    u_rd_id(
    .clk          (sys_clk  ),
    .rst_n        (sys_rst_n),
    .lcd_rgb      (lcd_rgb  ),
    .lcd_id       (lcd_id   )
);

//分频模块
clk_div  u_clk_div(
    .clk          (sys_clk  ),
    .rst_n        (sys_rst_n),
    .lcd_id       (lcd_id   ),
    .lcd_pclk     (lcd_pclk )
);

//二进制转BCD码-心率
binary2bcd u_binary2bcd_xinlv(
    .sys_clk         (sys_clk),
    .sys_rst_n       (sys_rst_n),
    .data            ({4'd0,xinlv}),

    .bcd_data        (xinlv_bcd)    
);

//二进制转BCD码-RR间期
binary2bcd u_binary2bcd_RR(
    .sys_clk         (sys_clk),
    .sys_rst_n       (sys_rst_n),
    .data            ({4'd0,rr_current}),

    .bcd_data        (RR_bcd)    
); 

//二进制转BCD码-HRV
binary2bcd u_binary2bcd_HRV(
    .sys_clk         (sys_clk),
    .sys_rst_n       (sys_rst_n),
    .data            ({4'd0,hrv_sdnn}),

    .bcd_data        (HRV_bcd)    
); 

//多界面显示模块 - 传递原始坐标
ui_display  u_ui_display(          
    .lcd_pclk       (lcd_pclk    ),
    .sys_rst_n      (sys_rst_n   ),
    .touch_data     (touch_data),  // 直接传递原始坐标
    .ui_state       (ui_state    ),
    .data_state     (data_state ),
    .data_sel       (data_sel   ),
    //ADC数据显示
    .xinlv_bcd(xinlv_bcd),
    .hrv_bcd(HRV_bcd),
    .arrhythmia_level(arrhythmia_level),
    .rr_bcd(RR_bcd),
    .pixel_xpos     (pixel_xpos_w),
    .pixel_ypos     (pixel_ypos_w),
    .pixel_data     (pixel_data_w)
);

//lcd驱动模块
lcd_driver  u_lcd_driver(
    .lcd_pclk       (lcd_pclk    ),
    .rst_n          (sys_rst_n   ),
    .lcd_id         (lcd_id      ),
    .lcd_hs         (lcd_hs      ),
    .lcd_vs         (lcd_vs      ),
    .lcd_de         (lcd_de      ),
    .lcd_bl         (lcd_bl      ),
    .lcd_clk        (lcd_clk     ),
    .lcd_rgb        (lcd_rgb_o   ),
    .lcd_rst        (lcd_rst_n   ),
    .data_req       (),
    .h_disp         (),
    .v_disp         (),
    .pixel_data     (pixel_data_w),
    .pixel_xpos     (pixel_xpos_w),
    .pixel_ypos     (pixel_ypos_w)
); 

endmodule