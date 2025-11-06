module fifo_rd(
    //system clock
    input               rd_clk      , //ʱ���ź�
    input               rst_n       , //��λ�ź�
    //FIFO interface
    input               rd_req, //����������
    input               rd_rst_busy , //����λæ�ź�
    input        [15:0]  fifo_rd_data, //��FIFO����������
    input               full        , //FIFO���ź�
    input                prog_full ,    //�ɱ������ֵ
    input               almost_empty, //FIFO�����ź�
    output  reg         fifo_rd_en,    //FIFO��ʹ��
    output               error_flag
);

//reg define
reg       full_d0;
reg       full_d1;
reg    [15:0]    rd_comp_data     ;      
reg    [10:0]      rd_right_cnt        ; 


assign  error_flag = (rd_right_cnt == (11'd1535))  ?  1'b0 : 1'b1;

//*****************************************************
//**                    main code
//*****************************************************

//��Ϊfull�ź�������FIFOдʱ�����
//���Զ�full������ͬ������ʱ������
always @(posedge rd_clk or negedge rst_n) begin
    if(!rst_n) begin
        full_d0 <= 1'b0;
        full_d1 <= 1'b0;
    end
    else begin
        full_d0 <= prog_full;
        full_d1 <= full_d0;
    end
end    
    
//��fifo_rd_en���и�ֵ,FIFOд��֮��ʼ��������֮��ֹͣ��
always @(negedge rd_clk or negedge rst_n) begin
    if(!rst_n) 
        fifo_rd_en <= 1'b0;
    else if(!rd_rst_busy) begin
        if(rd_req)
           fifo_rd_en <= 1'b1;
        else if(!rd_req)
           fifo_rd_en <= 1'b0; 
    end
    else
        fifo_rd_en <= 1'b0;
end

always @(negedge rd_clk or negedge rst_n) begin
    if(!rst_n) begin
        rd_comp_data <= 16'd0;
        rd_right_cnt <= 11'd0;
    end     
    else begin
        if(fifo_rd_en) begin
            rd_comp_data <= rd_comp_data + 16'b1;
            if(fifo_rd_data == rd_comp_data)
                rd_right_cnt <= rd_right_cnt + 11'd1;  
        end    
    end        
end

endmodule