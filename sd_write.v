module sd_write(
    input                clk_ref       ,  //ʱ���ź�
    input                clk_ref_180deg,  //ʱ���ź�,��clk_ref��λ���180��
    input                rst_n         ,  //��λ�ź�,�͵�ƽ��Ч
    //SD���ӿ�
    input                   sd_miso       ,  //SD��SPI�������������ź�
    output  reg          sd_cs         ,   //SD��SPIƬѡ�ź�  
    output  reg          sd_mosi       ,  //SD��SPI������������ź�
    //�û�д�ӿ�    
    input                  wr_start_en   ,    //��ʼдSD�������ź�
    input        [31:0]  wr_sec_addr   ,  //д����������ַ
    input        [15:0]  wr_data       ,    //д����                          
    output  reg          wr_busy       ,  //д����æ�ź�
    output  reg          wr_req           //д���������ź�
    );

//parameter define
parameter  HEAD_BYTE = 8'hfe    ;         //����ͷ
                             
//reg define                    
reg            wr_en_d0         ;          //wr_start_en�ź���ʱ����
reg            wr_en_d1         ;   
reg            res_en           ;            //����SD������������Ч�ź�      
reg    [7:0]  res_data         ;           //����SD����������                 
reg            res_flag         ;            //��ʼ���շ������ݵı�־
reg    [5:0]  res_bit_cnt      ;            //����λ���ݼ�����                   
                                
reg    [3:0]   wr_ctrl_cnt      ;           //д���Ƽ�����
reg    [47:0] cmd_wr           ;          //д����
reg    [5:0]   cmd_bit_cnt      ;         //д����λ������
reg    [3:0]   bit_cnt          ;             //д����λ������
reg    [8:0]   data_cnt         ;           //д����������
reg    [15:0] wr_data_t        ;           //�Ĵ�д������ݣ���ֹ�����ı�
reg             detect_done_flag ;       //���д�����źŵı�־
reg    [7:0]   detect_data      ;         //��⵽������

//wire define
wire           pos_wr_en        ;         //��ʼдSD�������źŵ�������

//*****************************************************
//**                    main code
//*****************************************************

assign  pos_wr_en = (~wr_en_d1) & wr_en_d0;

//wr_start_en�ź���ʱ����
always @(posedge clk_ref or negedge rst_n) begin
    if(!rst_n) begin
        wr_en_d0 <= 1'b0;
        wr_en_d1 <= 1'b0;
    end    
    else begin
        wr_en_d0 <= wr_start_en;
        wr_en_d1 <= wr_en_d0;
    end        
end 

//����sd�����ص���Ӧ����
//��clk_ref_180deg(sd_clk)����������������
always @(posedge clk_ref_180deg or negedge rst_n) begin
    if(!rst_n) begin
        res_en <= 1'b0;
        res_data <= 8'd0;
        res_flag <= 1'b0;
        res_bit_cnt <= 6'd0;
    end    
    else begin
        //sd_miso = 0 ��ʼ������Ӧ����
        if(sd_miso == 1'b0 && res_flag == 1'b0) begin
            res_flag <= 1'b1;
            res_data <= {res_data[6:0],sd_miso};
            res_bit_cnt <= res_bit_cnt + 6'd1;
            res_en <= 1'b0;
        end    
        else if(res_flag) begin
            res_data <= {res_data[6:0],sd_miso};
            res_bit_cnt <= res_bit_cnt + 6'd1;
            if(res_bit_cnt == 6'd7) begin
                res_flag <= 1'b0;
                res_bit_cnt <= 6'd0;
                res_en <= 1'b1; 
            end                
        end  
        else
            res_en <= 1'b0;       
    end
end 

//д�����ݺ���SD���Ƿ����
always @(posedge clk_ref or negedge rst_n) begin
    if(!rst_n)
        detect_data <= 8'd0;   
    else if(detect_done_flag)
        detect_data <= {detect_data[6:0],sd_miso};
    else
        detect_data <= 8'd0;    
end        

//SD��д������
always @(posedge clk_ref or negedge rst_n) begin
    if(!rst_n) begin
        sd_cs <= 1'b1;
        sd_mosi <= 1'b1; 
        wr_ctrl_cnt <= 4'd0;
        wr_busy <= 1'b0;
        cmd_wr <= 48'd0;
        cmd_bit_cnt <= 6'd0;
        bit_cnt <= 4'd0;
        wr_data_t <= 16'd0;
        data_cnt <= 9'd0;
        wr_req <= 1'b0;
        detect_done_flag <= 1'b0;
    end
    else begin
        wr_req <= 1'b0;
        case(wr_ctrl_cnt)
            4'd0 : begin
                wr_busy <= 1'b0;                          //д����
                sd_cs <= 1'b1;                                 
                sd_mosi <= 1'b1;                               
                if(pos_wr_en) begin                            
                    cmd_wr <= {8'h58,wr_sec_addr,8'hff};    //д�뵥�������CMD24
                    wr_ctrl_cnt <= wr_ctrl_cnt + 4'd1;      //���Ƽ�������1
                    //��ʼִ��д������,����дæ�ź�
                    wr_busy <= 1'b1;                      
                end                                            
            end   
            4'd1 : begin
                if(cmd_bit_cnt <= 6'd47) begin              //��ʼ��λ����д����
                    cmd_bit_cnt <= cmd_bit_cnt + 6'd1;
                    sd_cs <= 1'b0;
                    sd_mosi <= cmd_wr[6'd47 - cmd_bit_cnt]; //�ȷ��͸��ֽ�                 
                end    
                else begin
                    sd_mosi <= 1'b1;
                    if(res_en) begin                        //SD����Ӧ
                        wr_ctrl_cnt <= wr_ctrl_cnt + 4'd1;  //���Ƽ�������1 
                        cmd_bit_cnt <= 6'd0;
                        bit_cnt <= 4'd1;
                    end    
                end     
            end                                                                                                     
            4'd2 : begin                                       
                bit_cnt <= bit_cnt + 4'd1;     
                //bit_cnt = 0~7 �ȴ�8��ʱ������
                //bit_cnt = 8~15,д������ͷ8'hfe        
                if(bit_cnt>=4'd8 && bit_cnt <= 4'd15) begin
                    sd_mosi <= HEAD_BYTE[4'd15-bit_cnt];    //�ȷ��͸��ֽ�
                    if(bit_cnt == 4'd10)                       
                        wr_req <= 1'b1;                   //��ǰ����д���������ź�
                    else if(bit_cnt == 4'd15)                  
                        wr_ctrl_cnt <= wr_ctrl_cnt + 4'd1;  //���Ƽ�������1   
                end                                            
            end                                                
            4'd3 : begin                                    //д������
                bit_cnt <= bit_cnt + 4'd1;                     
                if(bit_cnt == 4'd0) begin                      
                    sd_mosi <= wr_data[4'd15-bit_cnt];      //�ȷ������ݸ�λ     
                    wr_data_t <= wr_data;                   //�Ĵ�����   
                end                                            
                else                                           
                    sd_mosi <= wr_data_t[4'd15-bit_cnt];    //�ȷ������ݸ�λ
                if((bit_cnt == 4'd10) && (data_cnt < 9'd255)) 
                    wr_req <= 1'b1;                          
                if(bit_cnt == 4'd15) begin                     
                    data_cnt <= data_cnt + 9'd1;  
                    //д�뵥��BLOCK��512���ֽ� = 256 * 16bit             
                    if(data_cnt == 9'd255) begin
                        data_cnt <= 9'd0;            
                        //д���������,���Ƽ�������1          
                        wr_ctrl_cnt <= wr_ctrl_cnt + 4'd1;      
                    end                                        
                end                                            
            end       
            //д��2���ֽ�CRCУ��,����SPIģʽ�²����У��ֵ,�˴�д�������ֽڵ�8'hff                                         
            4'd4 : begin                                       
                bit_cnt <= bit_cnt + 4'd1;                  
                sd_mosi <= 1'b1;                 
                //crcд�����,���Ƽ�������1              
                if(bit_cnt == 4'd15)                           
                    wr_ctrl_cnt <= wr_ctrl_cnt + 4'd1;            
            end                                                
            4'd5 : begin                                    
                if(res_en)                                  //SD����Ӧ   
                    wr_ctrl_cnt <= wr_ctrl_cnt + 4'd1;         
            end                                                
            4'd6 : begin                                    //�ȴ�д���           
                detect_done_flag <= 1'b1;                   
                //detect_data = 8'hffʱ,SD��д�����,�������״̬
                if(detect_data == 8'hff) begin              
                    wr_ctrl_cnt <= wr_ctrl_cnt + 4'd1;         
                    detect_done_flag <= 1'b0;                  
                end         
            end    
            default : begin
                //�������״̬��,����Ƭѡ�ź�,�ȴ�8��ʱ������
                sd_cs <= 1'b1;   
                wr_ctrl_cnt <= wr_ctrl_cnt + 4'd1;
            end     
        endcase
    end
end            

endmodule