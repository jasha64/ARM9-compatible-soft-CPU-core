module clkdiv(
    input logic mclk, //100MHz
    input logic rst,
    
    output logic clka //25MHz
);
    logic[1:0] q;
    always_ff @ (posedge mclk) //ֻ�������ؼ�����������������������½��ص�Ƶ��ֻ��ʵ��ʱ�ӵ�һ��
        if (rst == 1) q <= 2'b0;
        else q <= q + 1'b1;
    assign clka = q[1];
endmodule
