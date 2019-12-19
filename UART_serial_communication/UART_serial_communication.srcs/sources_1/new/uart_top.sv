/*
本次实验最后因波特率错误导致一直无法收到正确的信号。
请老师帮忙调试，老师采用的方法是：将tx_data的各个位依次置1，并抄录了对应的输出，找规律。
发现输出的字节中的1是等距离左移的，最终确定了是波特率错误。
*/
module uart_top(
    input logic CLK100MHZ,
    input logic BTNC, //reset
    input logic BTNR, //send
    input logic UART_TXD_IN,
    
    output logic UART_RXD_OUT,
    output logic[6:0] A2G,
    output logic[7:0] AN,
    output logic DP
);
    logic rst;
    assign rst = BTNC;
    
    logic clk; //25MHz
    clkdiv cd(
        .mclk   (CLK100MHZ),
        .rst    (rst),
        
        .clka   (clk)
    );
    
    //十六进制显示收到的字节
    SevenSegmentDisplay X7(
        .clk    (clk),
        .clr    (rst),
        .in     (rx_data),
        
        .out    (A2G),
        .an     (AN),
        .dp     (DP)
    ) ;   
    
    rxtx u_rxtx(
        .clk    (clk),
        .rst    (rst),
        .rx     (UART_TXD_IN), //接收端口
        .tx_vld (tx_vld), //发送有效（请求发送）
        .tx_data(tx_data), //发送数据
        
        .rx_vld (rx_vld), //接收有效
        .rx_data(rx_data), //接收数据
        .tx     (UART_RXD_OUT), //发送端口
        .tx_rdy (tx_rdy) //发送端口就绪
    );
    
    //block RAM
    logic[7:0] mem[1023:0]; //1024 * 1Byte
    
    //带有写使能wr_en、写地址wr_addr和写数据wr_data，若时钟上升沿wr_en为高电平，则wr_data会写入地址wr_addr。
    logic rx_vld;
    logic[7:0] rx_data;
    always @ (posedge clk)
        if (rx_vld) mem[rx_addr] <= rx_data; //用rx_addr作为wr_addr，其余寄存器类似。直接将RxD接收到的数据写入RAM
        else;
    
    //每次RxD接收到1Byte，就将其写到RAM的末尾。为此声明一个计数器rx_addr，表示当前要写入到的地址。
    logic[9:0] rx_addr;
    always @ (posedge clk)
        if (rst) rx_addr <= 10'b0;
        else if (rx_vld) rx_addr <= rx_addr + 1'b1;
        else;
    
    //探测发送按钮的上升沿
    logic start_rising;
    logic start, start_delay;
    assign start = BTNR;
    always @ (posedge clk)
        if (rst) start_delay <= 1'b0;
        else start_delay <= start;
    assign start_rising = (~start_delay & start) & tx_rdy & (rx_addr != 10'b0); //如果发送端口未就绪，或者尚未接收到任何数据，是不能开始传送的
    
    //探测tx_rdy的上升沿。它的意义是1个Byte发送完毕。
    logic txrdy_rising;
    logic txrdy_dly;
    always @ (posedge clk)
        if (rst) txrdy_dly <= 1'b1;
        else txrdy_dly <= tx_rdy;
    assign txrdy_rising = ~txrdy_dly & tx_rdy;
    
    //“发送状态”寄存器
    logic tx_flag;
    always @ (posedge clk)
        if (rst) tx_flag <= 1'b0;
        else if (start_rising) tx_flag <= 1'b1;
        else if (tx_addr == rx_addr && txrdy_rising) tx_flag <= 1'b0;
        else;
    
    //从0地址开始，依次发送RAM中的数据。声明一个寄存器来表示将要发送的地址。
    logic[9:0] tx_addr;
    always @ (posedge clk)
        if (rst) tx_addr <= 10'b0;
        else if (start_rising & ~tx_flag) tx_addr <= 10'b1;
        else if (tx_flag)
            if (txrdy_rising) tx_addr <= tx_addr + 1'b1;
            else;
        else tx_addr <= 10'b0;
    
    //block RAM的读
    //开发板的block RAM带有一个读使能rd_en和读地址rd_addr，如果时钟上升沿rd_en为高电平，则由rd_data在下一周期给出读的数据。
    logic rd_en;
    assign rd_en = tx_flag ? txrdy_rising : start_rising;
    logic[7:0] rd_data;
    always @ (posedge clk)
        if (rd_en) rd_data <= mem[tx_addr];
        else;
    
    //发送使能。它比RAM读使能延后，确保在RAM中的数据读取完毕后再通过串口发出。
    logic tx_en;
    always @ (posedge clk)
        if (rst) tx_en <= 1'b0;
        else tx_en <= rd_en;
    
    //rxtx模块的请求发送信号，用于发送过程
    logic tx_vld;
    assign tx_vld = tx_en & tx_flag; //如果不'&'上tx_flag，则可能导致发送RAM[rx_addr]位置的无效数据
    
    //将读出的数据引入rxtx模块
    logic[7:0] tx_data;
    assign tx_data = rd_data;
endmodule
