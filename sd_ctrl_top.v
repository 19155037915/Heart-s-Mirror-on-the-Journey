module sd_ctrl_top(
    input                clk_ref       ,        //ʱ���ź�
    input                clk_ref_180deg,  //ʱ���ź�,��clk_ref��λ���180��
    input                rst_n         ,       //��λ�ź�,�͵�ƽ��Ч
    //SD���ӿ�
    input                   sd_miso      ,    //SD��SPI�������������ź�
    output                 sd_clk         ,    //SD��SPIʱ���ź�    
    output  reg          sd_cs          ,    //SD��SPIƬѡ�ź�
    output  reg          sd_mosi       ,   //SD��SPI������������ź�
    //�û�дSD���ӿ�
    input                  wr_start_en    ,  //��ʼдSD�������ź�
    input        [31:0]  wr_sec_addr   ,  //д����������ַ
    input        [15:0]  wr_data         ,  //д����                  
    output                wr_busy         ,  //д����æ�ź�
    output                wr_req          ,  //д���������ź�    
    //�û���SD���ӿ�
    input                  rd_start_en     ,  //��ʼ��SD�������ź�
    input        [31:0]  rd_sec_addr   ,  //������������ַ
    output                rd_busy         ,  //������æ�ź�
    output                rd_val_en       ,  //��������Ч�ź�
    output       [15:0] rd_val_data   ,   //������    
    
    output               sd_init_done     //SD����ʼ������ź�
    );
    
//wire define
wire                init_sd_clk   ;       //��ʼ��SD��ʱ�ĵ���ʱ��
wire                init_sd_cs    ;       //��ʼ��ģ��SDƬѡ�ź�
wire                init_sd_mosi  ;       //��ʼ��ģ��SD��������ź�
wire                wr_sd_cs      ;       //д����ģ��SDƬѡ�ź�     
wire                wr_sd_mosi    ;       //д����ģ��SD��������ź� 
wire                rd_sd_cs      ;       //������ģ��SDƬѡ�ź�     
wire                rd_sd_mosi    ;       //������ģ��SD��������ź� 

//*****************************************************
//**                    main code
//*****************************************************

//SD����SPI_CLK  
assign  sd_clk = (sd_init_done==1'b0)  ?  init_sd_clk  :  clk_ref_180deg;

//SD���ӿ��ź�ѡ��
always @(*) begin
    //SD����ʼ�����֮ǰ,�˿��źźͳ�ʼ��ģ���ź�����
    if(sd_init_done == 1'b0) begin     
        sd_cs = init_sd_cs;
        sd_mosi = init_sd_mosi;
    end    
    else if(wr_busy) begin
        sd_cs = wr_sd_cs;
        sd_mosi = wr_sd_mosi;   
    end    
    else if(rd_busy) begin
        sd_cs = rd_sd_cs;
        sd_mosi = rd_sd_mosi;       
    end    
    else begin
        sd_cs = 1'b1;
        sd_mosi = 1'b1;
    end    
end    

//SD����ʼ��
sd_init u_sd_init(
    .clk_ref            (clk_ref),
    .rst_n              (rst_n),
    
    .sd_miso            (sd_miso),
    .sd_clk             (init_sd_clk),
    .sd_cs              (init_sd_cs),
    .sd_mosi            (init_sd_mosi),
    
    .sd_init_done       (sd_init_done)
    );

//SD��д����
sd_write u_sd_write(
    .clk_ref            (clk_ref),
    .clk_ref_180deg     (clk_ref_180deg),
    .rst_n              (rst_n),
    
    .sd_miso            (sd_miso),
    .sd_cs              (wr_sd_cs),
    .sd_mosi            (wr_sd_mosi),
    //SD����ʼ�����֮����Ӧд����    
    .wr_start_en        (wr_start_en & sd_init_done),  
    .wr_sec_addr        (wr_sec_addr),
    .wr_data            (wr_data),
    .wr_busy            (wr_busy),
    .wr_req             (wr_req)
    );

//SD��������
sd_read u_sd_read(
    .clk_ref            (clk_ref),
    .clk_ref_180deg     (clk_ref_180deg),
    .rst_n              (rst_n),
    
    .sd_miso            (sd_miso),
    .sd_cs              (rd_sd_cs),
    .sd_mosi            (rd_sd_mosi),    
    //SD����ʼ�����֮����Ӧ������
    .rd_start_en        (rd_start_en & sd_init_done),  
    .rd_sec_addr        (rd_sec_addr),
    .rd_busy            (rd_busy),
    .rd_val_en          (rd_val_en),
    .rd_val_data        (rd_val_data)
    );

endmodule