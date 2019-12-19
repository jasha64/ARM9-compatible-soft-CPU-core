`timescale 1ns / 1ns
`define DEL 2

module tb();
    logic clk = 1'b0;
    always clk = #5 ~clk;
    
    logic rst = 1'b1;
    initial #10 rst = 1'b0;
    
    logic[7:0] rom[8191:0]; //��СΪ8KB������Keil�е��趨����ROM��
    logic rom_en;
    logic[31:0] rom_addr;
    logic[31:0] rom_data;
    always_ff @ (posedge clk)
        if (rom_en) rom_data <= #`DEL {rom[rom_addr+3],  rom[rom_addr+2], rom[rom_addr+1], rom[rom_addr]};
        else;
    
    integer fd, fx, i;
    initial begin
        for (i = 0; i < 8192; i = i+1) rom[i] = 0; //����ROM��û�б�hello.bin���ǵ�����ΪX����.coe�ļ�������
        fd = $fopen("../Obj/hello.bin", "rb");
        fx = $fread(rom, fd); //��.bin�ļ�����������ROM����Ϊָ���
        $fclose(fd);
        fd = $fopen("hello.coe", "w"); //��.bin�ļ������ݰ�Ҫ��ĸ�ʽд����һ��.coe�ļ�����Design Sources�г�ʼ��ROM IP��
        $fdisplay(fd, "memory_initialization_radix = 16;");
        $fdisplay(fd, "memory_initialization_vector = ");
        for (i = 0; i < 8192; i = i+4)
            $fdisplay(fd, "%2h%2h%2h%2h%1s", rom[i+3], rom[i+2], rom[i+1], rom[i], i == 8188 ? ";" : ",");
        $fclose(fd);
    end
    
    logic[31:0] ram[511:0];
    logic ram_cen, ram_wen;
    logic[3:0] ram_flag;
    logic[31:0] ram_addr;
    logic[31:0] ram_wdata;
    logic[31:0] ram_rdata;
    always_ff @ (posedge clk)
        if (ram_cen && ~ram_wen) //�����ݳ�
            if (ram_addr == 32'he000_0000) ram_rdata <= #`DEL 32'h0; //����Ƕ��Ĵ����������SERIAL_FLAG��ֵ0x0����Ϊ���ڻ�û������UARTģ�飬����ͨ��������������ݣ�����SERIAL_FLAG����Ϊ0����ʾ��ʱ����������ݣ�
            else if (ram_addr[31:28] == 4'h0) ram_rdata <= #`DEL {rom[ram_addr+3], rom[ram_addr+2], rom[ram_addr+1], rom[ram_addr]}; //���ݵ�ַ�Σ��б��Ƕ�ROM�����Ƕ�RAM����
            else if (ram_addr[31:28] == 4'h4) ram_rdata <= #`DEL ram[ram_addr[27:2]];
            else;
        else;
    always_ff @ (posedge clk)
        if (ram_cen && ram_wen && ram_addr[31:28] == 4'h4) //дRAM
            ram[ram_addr[27:2]] <= #`DEL {
                (ram_flag[3] ? ram_wdata[31:24] : ram[ram_addr[27:2]][31:24]),
                (ram_flag[2] ? ram_wdata[23:16] : ram[ram_addr[27:2]][23:16]),
                (ram_flag[1] ? ram_wdata[15: 8] : ram[ram_addr[27:2]][15: 8]),
                (ram_flag[0] ? ram_wdata[ 7: 0] : ram[ram_addr[27:2]][ 7: 0])
            };
        else;
    always_ff @ (posedge clk)
        if (ram_cen && ram_wen && ram_addr == 32'he000_0004) $write("%s", ram_wdata[7:0]); //дSERIAL_OUT��Ҳ��������ַ���
        else;
    
    logic irq = 1'b0;
    initial begin
        #100000 irq = 1'b1; //���е�100000nsʱ����һ����irq����
        #10 irq = 1'b0;
    end
    
    arm9_compatiable_code u_arm9(
        .clk        (clk),
        .cpu_en     (1'b1),
        .cpu_restart(1'b0),
        .fiq        (1'b0),
        .irq        (irq),
        .ram_abort  (1'b0),
        .ram_rdata  (ram_rdata),
        .rom_abort  (1'b0),
        .rom_data   (rom_data),
        .rst        (rst),
        
        .ram_addr   (ram_addr),
        .ram_cen    (ram_cen),
        .ram_flag   (ram_flag),
        .ram_wdata  (ram_wdata),
        .ram_wen    (ram_wen),
        .rom_addr   (rom_addr),
        .rom_en     (rom_en)
    );

endmodule
