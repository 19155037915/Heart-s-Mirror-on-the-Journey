module fifo_wr(
    //mudule clock
    input                  wr_clk      ,  // ʱ���ź�
    input                  rst_n       ,  // ��λ�ź�
    //FIFO interface       
    input                  wr_rst_busy ,  // д��λæ�ź�
    input                  empty       ,  // FIFO���ź�
    input                  almost_full ,  // FIFO�����ź�
    input                  prog_full ,    //�ɱ������ֵ
    input                  sd_init_done  ,  //SD����ʼ������ź�  
    input                  wr_req,//sd��д����æ            
	output    reg          fifo_wr_en  ,  // FIFOдʹ��
    output    reg  [15:0]  fifo_wr_data,   // д��FIFO������
    output    reg          fifo_wr_finish
);

//reg define
reg        empty_d0;
reg        empty_d1;
reg        [10:0] wr_cnt;   //д�����ݼ���

//*****************************************************
//**                    main code
//*****************************************************

//��Ϊempty�ź�������FIFO��ʱ�����
//���Զ�empty������ͬ����дʱ������
always @(posedge wr_clk or negedge rst_n) begin
    if(!rst_n) begin
        empty_d0 <= 1'b0;
        empty_d1 <= 1'b0;
    end
    else begin
        empty_d0 <= empty;
        empty_d1 <= empty_d0;
    end
end


always @(negedge wr_clk or negedge rst_n) begin
    if(!rst_n) 
        fifo_wr_en <= 1'b0;
    else if(!wr_rst_busy&&sd_init_done) begin
        if(wr_req)
            fifo_wr_en <= 1'b1;
        else if(!wr_req)
            fifo_wr_en <= 1'b0;  
    end
    else
        fifo_wr_en <= 1'b0;
end  

//��fifo_wr_data��ֵ,0~1535
always @(posedge wr_clk or negedge rst_n) begin
    if(!rst_n) 
        fifo_wr_data <= 16'b0;
    else if(fifo_wr_en && fifo_wr_data < 11'd1535) begin  
        fifo_wr_data <= fifo_wr_data + 11'd1; 
        wr_cnt <= wr_cnt + 11'b1;
    end
    else if(fifo_wr_data >= 11'd1535)begin
        fifo_wr_finish <= 1;
    end
//    else
//        fifo_wr_data <= 10'b0;
end

endmodule