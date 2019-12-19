module rxtx(
    input logic clk,
    input logic rst,
    input logic rx, //接收端口
    input logic tx_vld, //发送有效（请求发送）
    input logic[7:0] tx_data, //发送数据
    
    output logic rx_vld, //接收有效
    output logic[7:0] rx_data, //接收数据
    output logic tx, //发送端口
    output logic tx_rdy //发送端口就绪
);
    //用2-3个寄存器同步来消除异步传输的不确定性
    logic rxx;
    logic rx1, rx2, rx3;
    always_ff @ (posedge clk)
    begin
        rx1 <= rx; rx2 <= rx1; rx3 <= rx2; rxx <= rx3;
    end
    
    //检测rxx的变化，该检测结果为计数器服务
    logic rx_change;
    logic rx_dly;
    always_ff @ (posedge clk)
        rx_dly <= rxx;
    assign rx_change = (rxx != rx_dly); //用一个周期之前的值与当前值比较，得到变化与否的标志
    
    //时钟计数器，在rx保持为同一个值的时候，用这个值持续的时长来计算持续了多少位。
    logic[13:0] rx_cnt;
    always_ff @ (posedge clk)
    begin
        if (rst) rx_cnt <= 14'b0;
        else if (rx_change || (rx_cnt == 14'd2603)) rx_cnt <= 14'b0;
        else rx_cnt <= rx_cnt + 1'b1;
    end
    
    //采样标志
    logic rx_en;
    assign rx_en = (rx_cnt == 14'd1301); //半周期时刻，该采样了
    
    //接收数据状态指示寄存器，是否开始接收数据
    logic data_vld;
    always_ff @ (posedge clk)
        if (rst) data_vld <= 1'b0;
        else if (rx_en && ~rxx && ~data_vld) data_vld <= 1'b1; //rxx接收到一个低电平信号，说明接收将在一周期后开始
        else if (data_vld && (data_cnt == 4'd9) && rx_en) data_vld <= 1'b0;
        else;
    
    //专用于接收过程的计数器，含义是当前接收过程已接收了多少位（不含起始位），每接收1位则值加1
    logic[3:0] data_cnt;
    always_ff @ (posedge clk)
        if (rst) data_cnt <= 4'b0;
        else if (data_vld) //在接收已经开始后，每周期计数
            if (rx_en) data_cnt <= data_cnt + 1'b1;
            else; //latch
        else data_cnt <= 4'b0;
    
    //接收到的前8位（0-7）：数据位
    //logic[7:0] rx_data;
    always_ff @ (posedge clk)
        if (rst) rx_data <= 8'b0;
        else if (data_vld & rx_en & ~data_cnt[3]) rx_data[data_cnt] <= rxx; //rx_data <= {rxx, rx_data[7:1]};
        else;
    
    //接收完毕，发送接收有效信号
    //logic rx_vld;
    always_ff @ (posedge clk)
        if (rst) rx_vld <= 1'b0;
        else rx_vld <= data_vld && rx_en && (data_cnt == 4'd9);
    
    //发送模块，接收到请求发送信号时暂存发送数据
    logic[7:0] tx_rdy_data;
    always_ff @ (posedge clk)
        if (rst) tx_rdy_data <= 8'b0;
        else if (tx_vld && tx_rdy) tx_rdy_data <= tx_data;
        else;
    
    //发送数据状态指示寄存器
    logic trans_vld;
    always_ff @ (posedge clk)
        if (rst) trans_vld <= 1'b0;
        else if (tx_vld) trans_vld <= 1'b1;
        else if (rx_en && trans_vld && (trans_cnt == 4'd10)) trans_vld <= 1'b0;
        else;
    
    //发送过程的计数器
    logic[3:0] trans_cnt;
    always_ff @ (posedge clk)
        if (rst) trans_cnt <= 4'b0;
        else if (trans_vld)
            if (rx_en) trans_cnt <= trans_cnt + 1'b1; //采样信号只需要在计数器中判断，其它过程中不必
            else;
        else if (!trans_vld) trans_cnt <= 4'b0;
    
    //发送过程
    //logic tx;
    always_ff @ (posedge clk)
        if (rst) tx <= 1'b1;
        else if (trans_vld)
            if (rx_en)
                case (trans_cnt)
                4'd0: tx <= 1'b0;
                4'd1: tx <= tx_rdy_data[0];
                4'd2: tx <= tx_rdy_data[1];
                4'd3: tx <= tx_rdy_data[2];
                4'd4: tx <= tx_rdy_data[3];
                4'd5: tx <= tx_rdy_data[4];
                4'd6: tx <= tx_rdy_data[5];
                4'd7: tx <= tx_rdy_data[6];
                4'd8: tx <= tx_rdy_data[7];
                4'd9: tx <= ^tx_rdy_data;
                4'd10: tx <= 1'b1;
                default: tx <= 1'b1;
                endcase
            else; //latch
        else tx <= 1'b1;
    
    //发送就绪
    //logic tx_rdy;
    assign tx_rdy = ~trans_vld;
    
endmodule
