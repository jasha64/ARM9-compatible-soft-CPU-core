module rxtx(
    input logic clk,
    input logic rst,
    input logic rx, //���ն˿�
    input logic tx_vld, //������Ч�������ͣ�
    input logic[7:0] tx_data, //��������
    
    output logic rx_vld, //������Ч
    output logic[7:0] rx_data, //��������
    output logic tx, //���Ͷ˿�
    output logic tx_rdy //���Ͷ˿ھ���
);
    //��2-3���Ĵ���ͬ���������첽����Ĳ�ȷ����
    logic rxx;
    logic rx1, rx2, rx3;
    always_ff @ (posedge clk)
    begin
        rx1 <= rx; rx2 <= rx1; rx3 <= rx2; rxx <= rx3;
    end
    
    //���rxx�ı仯���ü����Ϊ����������
    logic rx_change;
    logic rx_dly;
    always_ff @ (posedge clk)
        rx_dly <= rxx;
    assign rx_change = (rxx != rx_dly); //��һ������֮ǰ��ֵ�뵱ǰֵ�Ƚϣ��õ��仯���ı�־
    
    //ʱ�Ӽ���������rx����Ϊͬһ��ֵ��ʱ�������ֵ������ʱ������������˶���λ��
    logic[13:0] rx_cnt;
    always_ff @ (posedge clk)
    begin
        if (rst) rx_cnt <= 14'b0;
        else if (rx_change || (rx_cnt == 14'd2603)) rx_cnt <= 14'b0;
        else rx_cnt <= rx_cnt + 1'b1;
    end
    
    //������־
    logic rx_en;
    assign rx_en = (rx_cnt == 14'd1301); //������ʱ�̣��ò�����
    
    //��������״ָ̬ʾ�Ĵ������Ƿ�ʼ��������
    logic data_vld;
    always_ff @ (posedge clk)
        if (rst) data_vld <= 1'b0;
        else if (rx_en && ~rxx && ~data_vld) data_vld <= 1'b1; //rxx���յ�һ���͵�ƽ�źţ�˵�����ս���һ���ں�ʼ
        else if (data_vld && (data_cnt == 4'd9) && rx_en) data_vld <= 1'b0;
        else;
    
    //ר���ڽ��չ��̵ļ������������ǵ�ǰ���չ����ѽ����˶���λ��������ʼλ����ÿ����1λ��ֵ��1
    logic[3:0] data_cnt;
    always_ff @ (posedge clk)
        if (rst) data_cnt <= 4'b0;
        else if (data_vld) //�ڽ����Ѿ���ʼ��ÿ���ڼ���
            if (rx_en) data_cnt <= data_cnt + 1'b1;
            else; //latch
        else data_cnt <= 4'b0;
    
    //���յ���ǰ8λ��0-7��������λ
    //logic[7:0] rx_data;
    always_ff @ (posedge clk)
        if (rst) rx_data <= 8'b0;
        else if (data_vld & rx_en & ~data_cnt[3]) rx_data[data_cnt] <= rxx; //rx_data <= {rxx, rx_data[7:1]};
        else;
    
    //������ϣ����ͽ�����Ч�ź�
    //logic rx_vld;
    always_ff @ (posedge clk)
        if (rst) rx_vld <= 1'b0;
        else rx_vld <= data_vld && rx_en && (data_cnt == 4'd9);
    
    //����ģ�飬���յ��������ź�ʱ�ݴ淢������
    logic[7:0] tx_rdy_data;
    always_ff @ (posedge clk)
        if (rst) tx_rdy_data <= 8'b0;
        else if (tx_vld && tx_rdy) tx_rdy_data <= tx_data;
        else;
    
    //��������״ָ̬ʾ�Ĵ���
    logic trans_vld;
    always_ff @ (posedge clk)
        if (rst) trans_vld <= 1'b0;
        else if (tx_vld) trans_vld <= 1'b1;
        else if (rx_en && trans_vld && (trans_cnt == 4'd10)) trans_vld <= 1'b0;
        else;
    
    //���͹��̵ļ�����
    logic[3:0] trans_cnt;
    always_ff @ (posedge clk)
        if (rst) trans_cnt <= 4'b0;
        else if (trans_vld)
            if (rx_en) trans_cnt <= trans_cnt + 1'b1; //�����ź�ֻ��Ҫ�ڼ��������жϣ����������в���
            else;
        else if (!trans_vld) trans_cnt <= 4'b0;
    
    //���͹���
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
    
    //���;���
    //logic tx_rdy;
    assign tx_rdy = ~trans_vld;
    
endmodule
