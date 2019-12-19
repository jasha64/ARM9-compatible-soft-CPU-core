`timescale 1ns / 1ns
`define DEL 2

module tb();
    logic clk = 1'b0;
    always clk = #5 ~clk;
    
    logic rst = 1'b1;
    initial #10 rst = 1'b0;
    
    logic[7:0] rom[8191:0]; //大小为8KB（按照Keil中的设定）的ROM块
    logic rom_en;
    logic[31:0] rom_addr;
    logic[31:0] rom_data;
    always_ff @ (posedge clk)
        if (rom_en) rom_data <= #`DEL {rom[rom_addr+3],  rom[rom_addr+2], rom[rom_addr+1], rom[rom_addr]};
        else;
    
    integer fd, fx, i;
    initial begin
        for (i = 0; i < 8192; i = i+1) rom[i] = 0; //避免ROM中没有被hello.bin覆盖的区域为X，供.coe文件生成用
        fd = $fopen("../Obj/hello.bin", "rb");
        fx = $fread(rom, fd); //把.bin文件的内容送入ROM，作为指令池
        $fclose(fd);
        fd = $fopen("hello.coe", "w"); //把.bin文件的内容按要求的格式写入另一个.coe文件，供Design Sources中初始化ROM IP用
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
        if (ram_cen && ~ram_wen) //读数据池
            if (ram_addr == 32'he000_0000) ram_rdata <= #`DEL 32'h0; //如果是读寄存器，则给出SERIAL_FLAG的值0x0（因为现在还没有连接UART模块，而是通过仿真器输出数据，所以SERIAL_FLAG保持为0，表示随时可以输出数据）
            else if (ram_addr[31:28] == 4'h0) ram_rdata <= #`DEL {rom[ram_addr+3], rom[ram_addr+2], rom[ram_addr+1], rom[ram_addr]}; //根据地址段，判别是读ROM区域还是读RAM区域
            else if (ram_addr[31:28] == 4'h4) ram_rdata <= #`DEL ram[ram_addr[27:2]];
            else;
        else;
    always_ff @ (posedge clk)
        if (ram_cen && ram_wen && ram_addr[31:28] == 4'h4) //写RAM
            ram[ram_addr[27:2]] <= #`DEL {
                (ram_flag[3] ? ram_wdata[31:24] : ram[ram_addr[27:2]][31:24]),
                (ram_flag[2] ? ram_wdata[23:16] : ram[ram_addr[27:2]][23:16]),
                (ram_flag[1] ? ram_wdata[15: 8] : ram[ram_addr[27:2]][15: 8]),
                (ram_flag[0] ? ram_wdata[ 7: 0] : ram[ram_addr[27:2]][ 7: 0])
            };
        else;
    always_ff @ (posedge clk)
        if (ram_cen && ram_wen && ram_addr == 32'he000_0004) $write("%s", ram_wdata[7:0]); //写SERIAL_OUT，也就是输出字符串
        else;
    
    logic irq = 1'b0;
    initial begin
        #100000 irq = 1'b1; //运行到100000ns时给出一周期irq脉冲
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
