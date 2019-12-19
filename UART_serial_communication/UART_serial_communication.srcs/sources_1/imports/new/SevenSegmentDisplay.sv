module SevenSegmentDisplay(
    input logic clk,
    input logic clr,
    input logic[7:0] in,
    
    output logic[7:0] an,
    output logic dp,
    output logic[6:0] out
);
    //С����ر�
    assign dp = 1;
    
    //�߶��������ʾ����
    logic[3:0] digit;
    logic[6:0] outc;
    always_comb
    case (digit)
        'h0: outc = 7'b0111111;
        'h1: outc = 7'b0000110;
        'h2: outc = 7'b1011011;
        'h3: outc = 7'b1001111;
        'h4: outc = 7'b1100110;
        'h5: outc = 7'b1101101;
        'h6: outc = 7'b1111101;
        'h7: outc = 7'b0000111;
        'h8: outc = 7'b1111111;
        'h9: outc = 7'b1100111;
        'hA: outc = 7'b1110111;
        'hB: outc = 7'b1111100;
        'hC: outc = 7'b0111001;
        'hD: outc = 7'b1011110;
        'hE: outc = 7'b1111001;
        'hF: outc = 7'b1110001;
    endcase
    assign out = ~outc;
    
    //ʱ�ӷ�Ƶ��
    logic[16:0] clkdiv;
    always_ff @ (posedge clk)
        if (clr) clkdiv <= 0;
        else clkdiv <= clkdiv + 1;
    
    //��ʱ���������
    logic s;
    assign s = clkdiv[16]; //ѡ��95KHz�ķ�Ƶ��ÿ��10.4msѡ����һ�������
    always_comb
    begin
        an = 8'b1111_1111;
        case (s)
            0: begin an[0] = 0; digit = in[3:0]; end
            1: begin an[1] = 0; digit = in[7:4]; end
        endcase
    end
        
endmodule
//ע����ʦ�ṩ��ԭ���ļ�����clr����������ڸ�λʱ�ӣ������ʵ���а���ȥ��Ҳ��Ӱ��
//�����Ժ�����ӵ�ʱ���·����У������������reset�����������Ǳ���ʹ�õ�
