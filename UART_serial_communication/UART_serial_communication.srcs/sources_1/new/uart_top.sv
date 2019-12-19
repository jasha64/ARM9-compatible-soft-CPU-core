/*
����ʵ����������ʴ�����һֱ�޷��յ���ȷ���źš�
����ʦ��æ���ԣ���ʦ���õķ����ǣ���tx_data�ĸ���λ������1������¼�˶�Ӧ��������ҹ��ɡ�
����������ֽ��е�1�ǵȾ������Ƶģ�����ȷ�����ǲ����ʴ���
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
    
    //ʮ��������ʾ�յ����ֽ�
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
        .rx     (UART_TXD_IN), //���ն˿�
        .tx_vld (tx_vld), //������Ч�������ͣ�
        .tx_data(tx_data), //��������
        
        .rx_vld (rx_vld), //������Ч
        .rx_data(rx_data), //��������
        .tx     (UART_RXD_OUT), //���Ͷ˿�
        .tx_rdy (tx_rdy) //���Ͷ˿ھ���
    );
    
    //block RAM
    logic[7:0] mem[1023:0]; //1024 * 1Byte
    
    //����дʹ��wr_en��д��ַwr_addr��д����wr_data����ʱ��������wr_enΪ�ߵ�ƽ����wr_data��д���ַwr_addr��
    logic rx_vld;
    logic[7:0] rx_data;
    always @ (posedge clk)
        if (rx_vld) mem[rx_addr] <= rx_data; //��rx_addr��Ϊwr_addr������Ĵ������ơ�ֱ�ӽ�RxD���յ�������д��RAM
        else;
    
    //ÿ��RxD���յ�1Byte���ͽ���д��RAM��ĩβ��Ϊ������һ��������rx_addr����ʾ��ǰҪд�뵽�ĵ�ַ��
    logic[9:0] rx_addr;
    always @ (posedge clk)
        if (rst) rx_addr <= 10'b0;
        else if (rx_vld) rx_addr <= rx_addr + 1'b1;
        else;
    
    //̽�ⷢ�Ͱ�ť��������
    logic start_rising;
    logic start, start_delay;
    assign start = BTNR;
    always @ (posedge clk)
        if (rst) start_delay <= 1'b0;
        else start_delay <= start;
    assign start_rising = (~start_delay & start) & tx_rdy & (rx_addr != 10'b0); //������Ͷ˿�δ������������δ���յ��κ����ݣ��ǲ��ܿ�ʼ���͵�
    
    //̽��tx_rdy�������ء�����������1��Byte������ϡ�
    logic txrdy_rising;
    logic txrdy_dly;
    always @ (posedge clk)
        if (rst) txrdy_dly <= 1'b1;
        else txrdy_dly <= tx_rdy;
    assign txrdy_rising = ~txrdy_dly & tx_rdy;
    
    //������״̬���Ĵ���
    logic tx_flag;
    always @ (posedge clk)
        if (rst) tx_flag <= 1'b0;
        else if (start_rising) tx_flag <= 1'b1;
        else if (tx_addr == rx_addr && txrdy_rising) tx_flag <= 1'b0;
        else;
    
    //��0��ַ��ʼ�����η���RAM�е����ݡ�����һ���Ĵ�������ʾ��Ҫ���͵ĵ�ַ��
    logic[9:0] tx_addr;
    always @ (posedge clk)
        if (rst) tx_addr <= 10'b0;
        else if (start_rising & ~tx_flag) tx_addr <= 10'b1;
        else if (tx_flag)
            if (txrdy_rising) tx_addr <= tx_addr + 1'b1;
            else;
        else tx_addr <= 10'b0;
    
    //block RAM�Ķ�
    //�������block RAM����һ����ʹ��rd_en�Ͷ���ַrd_addr�����ʱ��������rd_enΪ�ߵ�ƽ������rd_data����һ���ڸ����������ݡ�
    logic rd_en;
    assign rd_en = tx_flag ? txrdy_rising : start_rising;
    logic[7:0] rd_data;
    always @ (posedge clk)
        if (rd_en) rd_data <= mem[tx_addr];
        else;
    
    //����ʹ�ܡ�����RAM��ʹ���Ӻ�ȷ����RAM�е����ݶ�ȡ��Ϻ���ͨ�����ڷ�����
    logic tx_en;
    always @ (posedge clk)
        if (rst) tx_en <= 1'b0;
        else tx_en <= rd_en;
    
    //rxtxģ����������źţ����ڷ��͹���
    logic tx_vld;
    assign tx_vld = tx_en & tx_flag; //�����'&'��tx_flag������ܵ��·���RAM[rx_addr]λ�õ���Ч����
    
    //����������������rxtxģ��
    logic[7:0] tx_data;
    assign tx_data = rd_data;
endmodule
