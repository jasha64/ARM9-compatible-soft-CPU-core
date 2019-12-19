`timescale 1ns / 1ps

module rxtx_tb();
    reg clk = 1'b0; //��ֵ
    always clk = #20 ~clk;
    
    reg rst = 1'b1;
    initial #40 rst = 1'b0;
    
    reg RxD = 1'b1, tx_vld = 1'b0;
    reg[7:0] tx_data = 8'h0;
    logic rx_vld, TxD = 1'b0, tx_rdy; //��X���0Ҳ������һ��negedge��Ȼ�󴥷�һ������֮���Tx�ļ����̡�������Ҫ����ֵΪ0.
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
    
    task tx_byte; //�ȵ�tx_rdyΪ��Ч��ʱ�򣬽������ź���tx_data
    input[7:0] b;
    begin
        while (~tx_rdy)
            @ (posedge clk) ; //�ȴ�һ��ʱ�������ټ��tx_rdy�ź�
        @ (posedge clk) ; //�ȴ�һ��ʱ������
        #3 tx_vld = 1'b1; tx_data = b;
        @ (posedge clk) ;
        #3 tx_vld = 1'b0; tx_data = 8'b0;
    end
    endtask
    
    //���RxD�˿�
    always @ (posedge clk)
        if (rx_vld)
            $display("--Byte %2h received @ %0d.", rx_data, $time); //��ʾ��ǰʱ��
        else;
    
    //���TxD�˿�
    integer i;
    reg[7:0] rec_byte;
    reg checkbit;
    always @ (negedge TxD) //��TxD�½��أ���ʼ��0bit����ʱ������ʼһ�μ�����
    begin
        #52080 if (TxD != 1'b0) $display("--Start bit error @ %0d.", $time);
        for (i = 0; i < 8; i = i+1) #104167 rec_byte[i] = TxD;
        #104167 checkbit = TxD;
        #104167 if (TxD != 1'b1) $display("--End bit error @ %0d.", $time);
        #52080 $display("--Byte %2h transmitted @ %0d.", rec_byte, $time);
                if (checkbit != ^rec_byte) $display("--Check bit error @ %0d.", $time);
    end
    
    //������
    initial begin
    #100 rxtx_tb.rx_send(8'b01011010);
        rxtx_tb.tx_byte(8'b10100101);
    #2000000 $stop;
    end
endmodule
