module data_gen(
    input                clk           ,  
    input                clk_250Hz      ,
    input                rst_n         ,  
    input                sd_init_done  ,  
    //
    input                wr_busy       ,  
    input                wr_req        , 
    input                prog_full ,    
    input                prog_empty ,        
    input                empty,
    input        [15:0]  rd_val_data   ,  //读数据
    output  reg          wr_start_en   ,  
    output  reg  [31:0]  wr_sec_addr   ,  
    //
    input                rd_val_en     ,  
    input                rd_busy       ,  
    input                fifo_wr_finish,
    input                save_start,
    input                read_start,
    output  reg          rd_start_en   ,  
    output  reg  [31:0]  rd_sec_addr  ,  
    output               fifo_wr_req_save,
    output               fifo_rd_req_save,
    output               fifo_wr_req_read,
    output               fifo_rd_req_read
    );

//reg define
reg              sd_init_done_d0  ;       
reg              sd_init_done_d1  ;       
reg              prog_full_d0  ;       
reg              prog_full_d1  ;  
reg              prog_empty_d0  ;       
reg              prog_empty_d1  ; 
reg              wr_busy_d0       ;      
reg              wr_busy_d1       ;
reg              rd_busy_d0       ;       
reg              rd_busy_d1       ;
reg              save_finish_d0;
reg              save_finish_d1;
reg              save_start_d0;
reg              save_start_d1;
reg              read_start_d0;
reg              read_start_d1;
reg    [15:0]    rd_comp_data     ;      
reg    [9:0]     rd_right_cnt        ;       
reg    [3:0]     wr_data_256_cnt   ;       
reg    [3:0]     rd_data_256_cnt   ;      
reg    [3:0]     wr_busy_cnt   ;       
reg    [3:0]     rd_busy_cnt   ;  

//wire define
wire             pos_init_done    ;      
wire             neg_wr_busy      ; 
wire             neg_rd_budy      ;      
wire             pos_prog_full    ;    
wire             pos_save_finish  ;
wire             save_finish      ;
wire             read_finish      ;
//*****************************************************
//**                    main code
//*****************************************************

assign  pos_init_done = (~sd_init_done_d1) & sd_init_done_d0;
assign  neg_wr_busy = wr_busy_d1 & (~wr_busy_d0);
assign  neg_rd_busy = rd_busy_d1 & (~rd_busy_d0);
assign  pos_prog_full = (~prog_full_d1) & prog_full_d0;    
assign  pos_prog_empty = (~prog_empty_d1) & prog_empty_d0;
assign  pos_save_finish = (~save_finish_d1) & save_finish_d0;
assign  pos_save_start = (~save_start_d1) & save_start_d0;
assign  pos_read_start = (~read_start_d1) & read_start_d0;
assign  fifo_rw_req_read = rd_val_en;
assign  fifo_rd_req_read = clk_250Hz&(~empty);
assign  fifo_rw_req_save = clk_250Hz&(~fifo_wr_finish)&save_start;
assign  fifo_rd_req_save = wr_req;
assign  save_finish = (wr_busy_cnt>=6) ? (1):(0);
assign  read_finish = (rd_busy_cnt>=6) ? (1):(0);
assign  error_flag = (rd_right_cnt == (11'd1024))  ?  1'b0 : 1'b1;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        sd_init_done_d0 <= 1'b0;
        sd_init_done_d1 <= 1'b0;
    end
    else begin
        sd_init_done_d0 <= sd_init_done;
        sd_init_done_d1 <= sd_init_done_d0;
    end        
end


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        prog_full_d0 <= 1'b0;
        prog_full_d1 <= 1'b0;
    end
    else begin
        prog_full_d0 <= prog_full;
        prog_full_d1 <= prog_full_d0;
    end        
end

//prog_empty
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        prog_empty_d0 <= 1'b0;
        prog_empty_d1 <= 1'b0;
    end
    else begin
        prog_empty_d0 <= prog_empty;
        prog_empty_d1 <= prog_empty_d0;
    end        
end

//save_finish 测试
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        save_finish_d0 <= 1'b0;
        save_finish_d1 <= 1'b0;
    end
    else begin
        save_finish_d0 <= save_finish;
        save_finish_d1 <= save_finish_d0;
    end        
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        wr_busy_d0 <= 1'b0;
        wr_busy_d1 <= 1'b0;
    end    
    else begin
        wr_busy_d0 <= wr_busy;
        wr_busy_d1 <= wr_busy_d0;
    end
end 


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        save_start_d0 <= 1'b0;
        save_start_d1 <= 1'b0;
    end    
    else begin
        save_start_d0 <= save_start;
        save_start_d1 <= save_start_d0;
    end
end 

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        read_start_d0 <= 1'b0;
        read_start_d1 <= 1'b0;
    end    
    else begin
        read_start_d0 <= read_start;
        read_start_d1 <= read_start_d0;
    end
end 

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        wr_busy_cnt <= 1'b0;
    end    
    else begin
        if(neg_wr_busy)begin
            wr_busy_cnt <= wr_busy_cnt + 1;
        end
    end
end 

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rd_busy_cnt <= 1'b0;
    end    
    else begin
        if(neg_rd_busy)begin
            rd_busy_cnt <= rd_busy_cnt + 1;
        end
    end
end 

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        wr_start_en <= 1'b0;
        wr_sec_addr <= 32'd0;
        wr_data_256_cnt <= 4'd0; 
    end    
    else begin
        if(sd_init_done) begin
            if(pos_prog_full&&wr_data_256_cnt<6)begin
                wr_start_en <= 1'b1;
                wr_data_256_cnt <= wr_data_256_cnt + 4'b1;
                wr_sec_addr <= 32'd16652 + wr_data_256_cnt;         
            end
            else
                wr_start_en <= 1'b0;
        end             
        else
            wr_start_en <= 1'b0;
    end    
end 

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rd_start_en <= 1'b0;
        rd_sec_addr <= 32'd0;  
        rd_data_256_cnt <= 4'd0;   
    end
    else begin
        if(sd_init_done) begin
            if((pos_prog_empty&&rd_data_256_cnt<6&&rd_data_256_cnt>0)||(pos_read_start&&rd_data_256_cnt==0)) begin
                rd_start_en <= 1'b1;
                rd_data_256_cnt <= rd_data_256_cnt + 1;
                rd_sec_addr <= 32'd16652 + rd_data_256_cnt;
            end 
            else
                rd_start_en <= 1'b0;
        end        
    end    
end    

endmodule