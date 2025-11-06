module top_sd_rw(
    input                sys_clk     ,    
    input                sys_rst_n   ,    
                                    
    //SD
    input                sd_miso     ,  
    input         [12:0] sd_write_data, 
    input         [2:0]  statue       ,
    output               sd_clk        ,  
    output               sd_cs         , 
    output               sd_mosi      , 
    output   wire [12:0] sd_read_data   
    );
    
//wire define
wire            clk_ref              ;
wire            clk_ref_180deg ;
wire            clk_ref_100 ;
wire            clk_250Hz  ;
wire            rst_n                ;
wire            locked             ;
wire            save_start         ;
wire            read_start        ;
wire            wr_start_en      ;       
wire   [31:0]   wr_sec_addr     ;              
wire            rd_start_en       ;       
wire   [31:0]   rd_sec_addr     ;       
wire            error_flag        ;       
wire            wr_busy          ;       
wire            wr_req            ;      
wire            rd_busy           ;      
wire            rd_val_en       ;       
wire   [15:0]   rd_val_data     ;       
wire            sd_init_done    ;      
wire            fifo_wr_req_save;
wire            fifo_rd_req_save;
wire            fifo_wr_req_read;
wire            fifo_rd_req_read;
wire            wr_rst_busy_save;
wire            rd_rst_busy_save;
wire            wr_rst_busy_read;
wire            rd_rst_busy_read;
wire   [15:0]   fifo_rd_data_read;
wire   [12:0]   fifo_wr_data_save;

//*****************************************************
//**                    main code
//*****************************************************

assign  rst_n = sys_rst_n & locked;
assign  sd_read_data =  fifo_rd_data_read[11:0];
assign  fifo_wr_data_save = {4'b0,sd_write_data};
assign  save_start = (statue == 5)? 1:0;
assign  read_start = (statue == 6)? 1:0;

clk_wiz_0 u_clk_wiz_0(
    // Clock out ports
    .clk_out1           (clk_ref),     // output clk_out1
    .clk_out2           (clk_ref_180deg),     // output clk_out2   
    // Status and control signals
    .reset              (1'b0), // input reset
    .locked             (locked),       // output locked
    // Clock in ports
    .clk_in1            (sys_clk)
    );      // input clk_in1
    
clk_div_50mhz_to_250hz u_clk_div_50mhz_to_250hz(
    .clk_50mhz          (sys_clk),    // 输入50MHz时钟
    .rst_n              (sys_rst_n),        // 复位信号，低电平有效
    .clk_250hz          (clk_250hz)     // 输出250Hz时钟
    );

//  
data_gen u_data_gen(
    .clk                (clk_ref),
    .clk_250Hz          (clk_250Hz),
    .rst_n              (rst_n),
    .sd_init_done       (sd_init_done),
    .wr_busy            (wr_busy),
    .wr_req             (wr_req),
    .wr_start_en        (wr_start_en),
    .wr_sec_addr        (wr_sec_addr),
    .rd_val_en          (rd_val_en),
    .rd_val_data        (rd_val_data),
    .rd_busy            (rd_busy),
    .rd_start_en        (rd_start_en),
    .rd_sec_addr        (rd_sec_addr),
    .prog_full          (prog_full_save),
    .prog_empty         (prog_empty_read),
    .empty              (empty_read),
    .fifo_wr_finish     (fifo_wr_finish),
    .fifo_wr_req_save   (fifo_wr_req_save),
    .fifo_rd_req_save   (fifo_rd_req_save),
    .fifo_wr_req_read   (fifo_wr_req_read),
    .fifo_rd_req_read   (fifo_rd_req_read),
    .save_start         (save_start),
    .read_start         (read_start)
    );   
    
//
sd_ctrl_top u_sd_ctrl_top(
    .clk_ref            (clk_ref),
    .clk_ref_180deg     (clk_ref_180deg),
    .rst_n              (rst_n),
    //
    .sd_miso            (sd_miso),
    .sd_clk             (sd_clk),
    .sd_cs              (sd_cs),
    .sd_mosi            (sd_mosi),
    //
    .wr_start_en        (wr_start_en),
    .wr_sec_addr        (wr_sec_addr),
    .wr_data            (fifo_rd_data_save),
    .wr_busy            (wr_busy),
    .wr_req             (wr_req),
    //
    .rd_start_en        (rd_start_en),
    .rd_sec_addr        (rd_sec_addr),
    .rd_busy            (rd_busy),
    .rd_val_en          (rd_val_en),
    .rd_val_data        (rd_val_data),    
    .sd_init_done       (sd_init_done)
    );
    
ip_fifo u_ip_fifo(
    .clk_50m            (clk_ref),    
    .clk_250Hz          (clk_250Hz),
    .rst_n              (rst_n),       
    .sd_init_done       (sd_init_done),
    .fifo_rd_data_save  (fifo_rd_data_save),
    .fifo_rd_data_read  (fifo_rd_data_read),
    .fifo_wr_data_save  (fifo_wr_data_save),
    .fifo_wr_data_read  (fifo_wr_data_read),
    .fifo_wr_req_save   (fifo_wr_req_save),
    .fifo_rd_req_save   (fifo_rd_req_save),
    .fifo_wr_req_read   (fifo_wr_req_read),
    .fifo_rd_req_read   (fifo_rd_req_read),
    .prog_full_save     (prog_full_save),
    .prog_empty_save    (prog_empty_save),
    .prog_full_read     (prog_full_read),
    .prog_empty_read    (prog_empty_read),
    .fifo_wr_finish     (fifo_wr_finish),
    .empty_read         (empty_read),
    .full_read          (full_read),
    .empty_save         (empty_save),
    .full_save          (full_save)
    );
     
endmodule