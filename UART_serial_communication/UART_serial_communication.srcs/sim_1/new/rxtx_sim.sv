`timescale 1ns / 1ps

module rxtx_tb();
    reg clk = 1'b0; //初值
    always clk = #20 ~clk;
    
    reg rst = 1'b1;
    initial #40 rst = 1'b0;
    
    reg RxD = 1'b1, tx_vld = 1'b0;
    reg[7:0] tx_data = 8'h0;
    logic rx_vld, TxD = 1'b0, tx_rdy; //从X变成0也会算作一次negedge，然后触发一次意料之外的Tx的检测过程。所以需要赋初值为0.
    logic[7:0] rx_data;
    
    rxtx u_rxtx(
            .clk    (clk),
            .rst    (rst),
            .rx     (RxD),
            .tx_vld (tx_vld),
            .tx_data(tx_data),
            
            .rx_vld (rx_vld),
            .rx_data(rx_data),
            .tx     (TxD),
            .tx_rdy (tx_rdy)
    );
    
    task rx_send;
    input[7:0] b;
    integer i;
    begin
        RxD = 1'b0; //#100
        for (i = 0; i < 8; i = i+1) #104167 RxD = b[i]; //#104267
        #104167 RxD = ^b; //#
        #104167 RxD = 1'b1;
        #104167 RxD = 1'b1;
    end
    endtask
    
    task tx_byte; //等到tx_rdy为有效的时候，将输入信号送tx_data
    input[7:0] b;
    begin
        while (~tx_rdy)
            @ (posedge clk) ; //等待一个时钟周期再检测tx_rdy信号
        @ (posedge clk) ; //等待一个时钟周期
        #3 tx_vld = 1'b1; tx_data = b;
        @ (posedge clk) ;
        #3 tx_vld = 1'b0; tx_data = 8'b0;
    end
    endtask
    
    //检测RxD端口
    always @ (posedge clk)
        if (rx_vld)
            $display("--Byte %2h received @ %0d.", rx_data, $time); //显示当前时间
        else;
    
    //检测TxD端口
    integer i;
    reg[7:0] rec_byte;
    reg checkbit;
    always @ (negedge TxD) //在TxD下降沿（起始的0bit出现时），开始一次检测过程
    begin
        #52080 if (TxD != 1'b0) $display("--Start bit error @ %0d.", $time);
        for (i = 0; i < 8; i = i+1) #104167 rec_byte[i] = TxD;
        #104167 checkbit = TxD;
        #104167 if (TxD != 1'b1) $display("--End bit error @ %0d.", $time);
        #52080 $display("--Byte %2h transmitted @ %0d.", rec_byte, $time);
                if (checkbit != ^rec_byte) $display("--Check bit error @ %0d.", $time);
    end
    
    //检测过程
    initial begin
    #100 rxtx_tb.rx_send(8'b01011010);
        rxtx_tb.tx_byte(8'b10100101);
    #2000000 $stop;
    end
endmodule
