module ip_fifo(
    input    rst_n,       //��λ�ź�,�͵�ƽ��Ч
    input    clk_250Hz,
    input    clk_50m,    //ʱ���ź�
    input    sd_init_done,  //SD����ʼ������ź�
    input    fifo_wr_req_save,
    input    fifo_rd_req_save,
    input    fifo_wr_req_read,
    input    fifo_rd_req_read,
    input    wire [15:0] fifo_wr_data_save,
    output   wire [15:0] fifo_rd_data_save,// ��FIFO����������
    input    wire [15:0] fifo_wr_data_read,   
    output   wire [15:0] fifo_rd_data_read,// ��FIFO����������
    output   prog_full_save,     //�ɱ������ֵ
    output   prog_empty_save,
    output   prog_full_read,     //�ɱ������ֵ
    output   prog_empty_read,
    output   fifo_wr_finish,
    output   empty_read,
    output   full_read,
    output   empty_save,
    output   full_save
);

//wire define
wire         fifo_rd_en_save    ;  // FIFO��ʹ���ź�
wire         fifo_wr_en_read    ;  // FIFOдʹ���ź�
wire         fifo_rd_en_read    ;  // FIFO��ʹ���ź�
wire         almost_full_save   ;  // FIFO�����ź�
wire         almost_empty_save  ;  // FIFO�����ź�
wire         almost_full_read   ;  // FIFO�����ź�
wire         almost_empty_read  ;  // FIFO�����ź�

//*****************************************************
//**                    main code
//*****************************************************

//����FIFO IP��
fifo_generator_0  fifo_generator_save (
    .rst           (~rst_n       ),  // input wire rst
    .wr_clk        (clk_250Hz      ),  // input wire wr_clk
    .rd_clk        (clk_50m     ),  // input wire rd_clk
    .wr_en         (fifo_wr_en_save   ),  // input wire wr_en
    .rd_en         (fifo_rd_en_save   ),  // input wire rd_en
    .din           (fifo_wr_data_save ),  // input wire [15 : 0] din
    .dout          (fifo_rd_data_save ),  // output wire [15 : 0] dout
    .almost_full   (almost_full_save  ),  // output wire almost_full
    .almost_empty  (almost_empty_save ),  // output wire almost_empty
    .full          (full_save         ),  // output wire full
    .empty         (empty_save        ),  // output wire empty
    .wr_rst_busy   (wr_rst_busy_save  ),  // output wire wr_rst_busy
    .rd_rst_busy   (rd_rst_busy_save  ),   // output wire rd_rst_busy
    .prog_full     (prog_full_save),          // output wire prog_full
    .prog_empty    (prog_empty_save)        // output wire prog_empty
);

fifo_generator_0  fifo_generator_read (
    .rst           (~rst_n       ),  // input wire rst
    .wr_clk        (clk_50m      ),  // input wire wr_clk
    .rd_clk        (clk_250Hz    ),  // input wire rd_clk
    .wr_en         (fifo_wr_en_read   ),  // input wire wr_en
    .rd_en         (fifo_rd_en_read   ),  // input wire rd_en
    .din           (fifo_wr_data_read ),  // input wire [15 : 0] din
    .dout          (fifo_rd_data_read ),  // output wire [15 : 0] dout
    .almost_full   (almost_full_read  ),  // output wire almost_full
    .almost_empty  (almost_empty_read ),  // output wire almost_empty
    .full          (full_read         ),  // output wire full
    .empty         (empty_read        ),  // output wire empty
    .wr_rst_busy   (wr_rst_busy_read  ),  // output wire wr_rst_busy
    .rd_rst_busy   (rd_rst_busy_read  ),   // output wire rd_rst_busy
    .prog_full     (prog_full_read),          // output wire prog_full
    .prog_empty    (prog_empty_read)        // output wire prog_empty
);

//����дFIFOģ��
fifo_wr  u_fifo_wr_save (
    .wr_clk        (clk_250Hz   ), // дʱ��
    .rst_n         (rst_n       ), // ��λ�ź�
    .wr_rst_busy   (wr_rst_busy_save ), // д��λæ�ź�
    .fifo_wr_en    (fifo_wr_en_save  ), // fifoд����
    .fifo_wr_data  (fifo_wr_data_save), // д��FIFO������
    .empty         (empty_save       ), // fifo���ź�
    .almost_full   (almost_full_save ),  // fifo�����ź�
    .prog_full     (prog_full_save   ),   //�ɱ������ֵ
    .sd_init_done  (sd_init_done),//SD����ʼ������ź�
    .wr_req        (fifo_rw_req_save),
    .fifo_wr_finish(fifo_wr_finish)
);

//������FIFOģ��
fifo_rd  u_fifo_rd_save (
    .rd_clk        (clk_50m    ),  // ��ʱ��
    .rst_n         (rst_n       ),  // ��λ�ź�
    .rd_rst_busy   (rd_rst_busy_save ),  // ����λæ�ź�
    .fifo_rd_en    (fifo_rd_en_save  ),  // fifo������
    .fifo_rd_data  (fifo_rd_data_save),  // ��FIFO���������
    .almost_empty  (almost_empty_save),  // fifo�����ź�
    .full          (full_save        ),   // fifo���ź�
    .prog_full     (prog_full_save   ),   //�ɱ������
    .rd_req        (fifo_rd_req_save )
);

//����дFIFOģ��
fifo_wr  u_fifo_wr_read (
    .wr_clk        (clk_50m     ), // дʱ��
    .rst_n         (rst_n       ), // ��λ�ź�
    .wr_rst_busy   (wr_rst_busy_read ), // д��λæ�ź�
    .fifo_wr_en    (fifo_wr_en_read  ), // fifoд����
    .fifo_wr_data  (fifo_wr_data_read), // д��FIFO������
    .empty         (empty_read       ), // fifo���ź�
    .almost_full   (almost_full_read ),  // fifo�����ź�
    .prog_full     (prog_full_read   ),   //�ɱ������ֵ
    .sd_init_done  (sd_init_done),//SD����ʼ������ź�
    .wr_req        (fifo_rw_req_read)
);

//������FIFOģ��
fifo_rd  u_fifo_rd_read (
    .rd_clk       (clk_250Hz   ),  // ��ʱ��
    .rst_n        (rst_n       ),  // ��λ�ź�
    .rd_rst_busy  (rd_rst_busy_read ),  // ����λæ�ź�
    .fifo_rd_en   (fifo_rd_en_read  ),  // fifo������
    .fifo_rd_data (fifo_rd_data_read),  // ��FIFO���������
    .almost_empty (almost_empty_read),  // fifo�����ź�
    .full         (full_read        ),   // fifo���ź�
    .prog_full    (prog_full_read),   //�ɱ������
    .error_flag   (error_flag),
    .rd_req       (fifo_rd_req_read)
);



endmodule 