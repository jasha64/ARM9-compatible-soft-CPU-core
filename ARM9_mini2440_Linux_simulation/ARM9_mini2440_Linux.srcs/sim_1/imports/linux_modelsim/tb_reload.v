// 启动时执行Tcl命令：set_param general.maxThreads 8
// 请在设置(Tools - Project Settings - Simulation - Elaboration)中关闭波形图，否则会爆硬盘（设置xsim.elaborate.debug_level = off）
`timescale 1 ns/1 ns
`define DEL 2
module tb_kernel;

wire            rom_en;
wire [31:0]     rom_addr;
reg  [31:0]     rom_addrm;
reg  [31:0]     rom_data;

wire            ram_cen;
wire [3:0]      ram_flag;
wire            ram_wen;
wire [31:0]     ram_addr;
wire [31:0]     ram_wdata;
reg  [31:0]     ram_rdata;
reg  [31:0]     ram_addrm;
wire            irq;

reg clk=1'b0;
always clk = #5 ~clk;

reg rst = 1'b1;
initial #10 rst = 1'b0;

reg  mmu_enable = 1'b0;
always @ (posedge clk)
if (u_arm.cmd_ok&u_arm.cmd_is_mcr& ~u_arm.cmd[20] &(u_arm.cmd[11:8]==4'hf)&(u_arm.cmd[23:21]==3'h0)&(u_arm.cmd[19:16]==4'h1)&(u_arm.cmd[3:0]==4'h0)&(u_arm.cmd[7:5]==3'h0))
    mmu_enable <= #`DEL u_arm.rna[0];
else;
    
reg [17:0] ttb=18'h0c001;
always @ (posedge clk)
if (u_arm.cmd_ok&u_arm.cmd_is_mcr& ~u_arm.cmd[20] &(u_arm.cmd[11:8]==4'hf)&(u_arm.cmd[23:21]==3'h0)&(u_arm.cmd[19:16]==4'h2)&(u_arm.cmd[3:0]==4'h0)&(u_arm.cmd[7:5]==3'h0))
    ttb <= #`DEL u_arm.rna[31:14];
else;    

reg [31:0] subsrcpnd=32'h677f3d8f;
always @ (posedge clk)
if (ram_cen & ram_wen & (ram_addrm==32'h4a000008))
    subsrcpnd <= #`DEL ram_wdata;
else;

reg [31:0] tcfg0=32'h200;
always @ (posedge clk)
if (ram_cen & ram_wen & (ram_addrm==32'h51000000))
    tcfg0 <= #`DEL ram_wdata;
else;

reg [31:0] intpnd=32'h0;
always @ (posedge clk)
if (irq)
    intpnd <= #`DEL 32'h4000;
else if (ram_cen & ram_wen &(ram_addrm==32'h4a000010))
    intpnd <= #`DEL 32'h0;
else;

reg [31:0] srcpnd=32'h0;
always @ (posedge clk)
if (irq)
    srcpnd <= #`DEL 32'h4000;
else if (ram_cen & ram_wen &(ram_addrm==32'h4a000000))
    srcpnd <= #`DEL 32'h0;
else;

reg [7:0] iiccon=8'he0;
always @ (posedge clk)
if (ram_cen & ram_wen & (ram_addrm==32'h54000000))
    iiccon <= #`DEL ram_wdata[7:0];
else;	


reg timer4_enable=1'b0;
always @ (posedge clk)
if (ram_cen & ram_wen & (ram_addrm==32'h51000008))
    timer4_enable <= #`DEL ram_wdata[20];
else;

reg [15:0] timer4_cnt=16'ha4ca;

reg [5:0] timer4_subcnt=0;

always @ (posedge clk)
if (timer4_enable)
    begin
	if (timer4_subcnt==6'd47) begin
	    timer4_subcnt <= #`DEL 6'd0;
	    if (timer4_cnt==16'h0)
            timer4_cnt <= #`DEL 16'ha4ca;
        else
            timer4_cnt <= #`DEL timer4_cnt - 1'b1;
		end	
	else
        timer4_subcnt <= #`DEL timer4_subcnt + 1'b1;	
	end	
else begin
    timer4_subcnt <= #`DEL 6'd0;
    timer4_cnt <= #`DEL 16'ha4ca;
	end 

reg irq_flag=1'b0;
always @ (posedge clk)
if ((timer4_cnt==0)&(timer4_subcnt==6'd47))
    irq_flag <= #`DEL 1'b1;
else if (~u_arm.cpsr_i)
    irq_flag <= #`DEL 1'b0;
else;	

assign irq = irq_flag & ~u_arm.cpsr_i;

reg [7:0] sdram[(1<<26)-1:0];
integer i;
initial for (i=0;i<(1<<26);i=i+1) sdram[i]=0;
//initial $readmemh("sdram_now.txt",sdram);

reg [31:0] core_init [51:0];
/*
initial begin
$readmemh("core_now.txt",core_init);
#7 force u_arm.r0 = core_init[0];
   force u_arm.r1 = core_init[1];
   force u_arm.r2 = core_init[2];
   force u_arm.r3 = core_init[3];
   force u_arm.r4 = core_init[4];
   force u_arm.r5 = core_init[5];
   force u_arm.r6 = core_init[6];
   force u_arm.r7 = core_init[7];
   force u_arm.r8_usr = core_init[8];
   force u_arm.r8_fiq = core_init[9];
   force u_arm.r9_usr = core_init[10];
   force u_arm.r9_fiq = core_init[11]; 
   force u_arm.ra_usr = core_init[12];
   force u_arm.ra_fiq = core_init[13];
   force u_arm.rb_usr = core_init[14];
   force u_arm.rb_fiq = core_init[15];  
   force u_arm.rc_usr = core_init[16];
   force u_arm.rc_fiq = core_init[17]; 
   force u_arm.rd_usr = core_init[18];
   force u_arm.rd_abt = core_init[19];  
   force u_arm.rd_fiq = core_init[20];
   force u_arm.rd_irq = core_init[21]; 
   force u_arm.rd_svc = core_init[22]; 
   force u_arm.rd_und = core_init[23]; 
   force u_arm.re_usr = core_init[24];
   force u_arm.re_abt = core_init[25];  
   force u_arm.re_fiq = core_init[26];
   force u_arm.re_irq = core_init[27]; 
   force u_arm.re_svc = core_init[28]; 
   force u_arm.re_und = core_init[29];
   force u_arm.rf = core_init[30];
   force u_arm.cpsr_n = core_init[31];
   force u_arm.cpsr_z = core_init[32];   
   force u_arm.cpsr_c = core_init[33];
   force u_arm.cpsr_v = core_init[34];
   force u_arm.cpsr_i = core_init[35];
   force u_arm.cpsr_f = core_init[36];   
   force u_arm.cpsr_m = core_init[37];
   force u_arm.spsr_abt = core_init[38];
   force u_arm.spsr_fiq = core_init[39];  
   force u_arm.spsr_irq = core_init[40];
   force u_arm.spsr_svc = core_init[41];   
   force u_arm.spsr_und = core_init[42]; 
   force mmu_enable = core_init[43];
   force ttb = core_init[44];
   force subsrcpnd = core_init[45];
   force tcfg0 = core_init[46];
   force intpnd = core_init[47];
   force srcpnd = core_init[48];
   force iiccon = core_init[49];
   force timer4_enable = core_init[50];
   force timer4_cnt = core_init[51];
#1 release u_arm.r0;
   release u_arm.r1;
   release u_arm.r2;
   release u_arm.r3;
   release u_arm.r4;
   release u_arm.r5;
   release u_arm.r6;
   release u_arm.r7;
   release u_arm.r8_usr;
   release u_arm.r8_fiq;
   release u_arm.r9_usr;
   release u_arm.r9_fiq;
   release u_arm.ra_usr;
   release u_arm.ra_fiq;
   release u_arm.rb_usr;
   release u_arm.rb_fiq;
   release u_arm.rc_usr;
   release u_arm.rc_fiq;
   release u_arm.rd_usr;
   release u_arm.rd_abt;
   release u_arm.rd_fiq;
   release u_arm.rd_irq;
   release u_arm.rd_svc;
   release u_arm.rd_und;
   release u_arm.re_usr;
   release u_arm.re_abt;
   release u_arm.re_fiq;
   release u_arm.re_irq;
   release u_arm.re_svc;
   release u_arm.re_und;
   release u_arm.rf;
   release u_arm.cpsr_n;
   release u_arm.cpsr_z;
   release u_arm.cpsr_c;
   release u_arm.cpsr_v;
   release u_arm.cpsr_i;
   release u_arm.cpsr_f;
   release u_arm.cpsr_m;
   release u_arm.spsr_abt;
   release u_arm.spsr_fiq;
   release u_arm.spsr_irq;
   release u_arm.spsr_svc;
   release u_arm.spsr_und;  
   release mmu_enable;
   release ttb;
   release subsrcpnd;
   release tcfg0;
   release intpnd;
   release srcpnd;
   release iiccon;
   release timer4_enable;
   release timer4_cnt;   
end
*/
	
/*********************************************************/
//instruction mmu
/*********************************************************/

wire [31:0] rom_l1_addr;
assign rom_l1_addr = {ttb,rom_addr[31:20],2'b0};

wire [31:0] rom_l1_data;
assign rom_l1_data = {sdram[rom_l1_addr[25:0]+3],sdram[rom_l1_addr[25:0]+2],sdram[rom_l1_addr[25:0]+1],sdram[rom_l1_addr[25:0]+0]};

wire [31:0] rom_sec_addr;
assign rom_sec_addr = {rom_l1_data[31:20],rom_addr[19:0]};

wire [31:0] rom_coarse_addr;
assign rom_coarse_addr = {rom_l1_data[31:10],rom_addr[19:12],2'b0};

wire [31:0] rom_fine_addr;
assign rom_fine_addr = {rom_l1_data[31:12],rom_addr[19:10],2'b0};

wire [31:0] rom_coarse_data;
assign rom_coarse_data = {sdram[rom_coarse_addr[25:0]+3],sdram[rom_coarse_addr[25:0]+2],sdram[rom_coarse_addr[25:0]+1],sdram[rom_coarse_addr[25:0]+0]};

wire [31:0] rom_fine_data;
assign rom_fine_data = {sdram[rom_fine_addr[25:0]+3],sdram[rom_fine_addr[25:0]+2],sdram[rom_fine_addr[25:0]+1],sdram[rom_fine_addr[25:0]+0]};

wire [31:0] rom_coarse_large_addr;
assign rom_coarse_large_addr = {rom_coarse_data[31:16],rom_addr[15:0]};

wire [31:0] rom_coarse_small_addr;
assign rom_coarse_small_addr = {rom_coarse_data[31:12],rom_addr[11:0]};

wire [31:0] rom_fine_small_addr;
assign rom_fine_small_addr = {rom_fine_data[31:12],rom_addr[11:0]};

wire [31:0] rom_fine_tiny_addr;
assign rom_fine_tiny_addr = {rom_fine_data[31:10],rom_addr[9:0]};


always @ (*)
if (mmu_enable)
    case(rom_l1_data[1:0])
    2'h0 : rom_addrm = rom_addr;
    2'h1 : case(rom_coarse_data[1:0])
           2'h0 : rom_addrm = rom_addr;
           2'h1 : rom_addrm = rom_coarse_large_addr;
           2'h2 : rom_addrm = rom_coarse_small_addr;
           2'h3 : rom_addrm = rom_addr;
           endcase
    2'h2 : rom_addrm = rom_sec_addr;
	2'h3 : case(rom_fine_data[1:0])
	       2'h0 : rom_addrm = rom_addr;
		   2'h1 : rom_addrm = rom_addr;
		   2'h2 : rom_addrm = rom_fine_small_addr;
		   2'h3 : rom_addrm = rom_fine_tiny_addr;
		   endcase
	endcase
else
    rom_addrm = rom_addr;
  
reg rom_abort = 1'b0;  
always @ (posedge clk) begin
if (rom_abort)
    rom_abort <= #`DEL 1'b0;
else if (rom_en & mmu_enable & ~rst)
    case(rom_l1_data[1:0])
    2'h0 :  begin 
	            rom_abort <= #`DEL 1'b1; 
			    $display("%8d: rom mmu l1 fault at %8h",$time,rom_addr); 
			end
    2'h1 : if ((rom_coarse_data[1:0]==2'h0)|(rom_coarse_data[1:0]==2'h3)) begin
               rom_abort <= #`DEL 1'b1;
			   $display("%8d: rom mmu l1 coarse fault at %8h",$time,rom_addr);
                end
           else;
    2'h2 : ;
    2'h3 : if ((rom_fine_data[1:0]==2'h0)|(rom_fine_data[1:0]==2'h1)) begin
               rom_abort <= #`DEL 1'b1;	
               $display("%8d: rom mmu l1 fine fault at %8h",$time,rom_addr);
                end
           else;
    endcase
else;
end	

/*********************************************************/
/*********************************************************/
//ram mmu
/*********************************************************/

wire [31:0] ram_l1_addr;
assign ram_l1_addr = {ttb,ram_addr[31:20],2'b0};

wire [31:0] ram_l1_data;
assign ram_l1_data = {sdram[ram_l1_addr[25:0]+3],sdram[ram_l1_addr[25:0]+2],sdram[ram_l1_addr[25:0]+1],sdram[ram_l1_addr[25:0]+0]};

wire [31:0] ram_sec_addr;
assign ram_sec_addr = {ram_l1_data[31:20],ram_addr[19:0]};

wire [31:0] ram_coarse_addr;
assign ram_coarse_addr = {ram_l1_data[31:10],ram_addr[19:12],2'b0};

wire [31:0] ram_fine_addr;
assign ram_fine_addr = {ram_l1_data[31:12],ram_addr[19:10],2'b0};

wire [31:0] ram_coarse_data;
assign ram_coarse_data = {sdram[ram_coarse_addr[25:0]+3],sdram[ram_coarse_addr[25:0]+2],sdram[ram_coarse_addr[25:0]+1],sdram[ram_coarse_addr[25:0]+0]};

wire [31:0] ram_fine_data;
assign ram_fine_data = {sdram[ram_fine_addr[25:0]+3],sdram[ram_fine_addr[25:0]+2],sdram[ram_fine_addr[25:0]+1],sdram[ram_fine_addr[25:0]+0]};

wire [31:0] ram_coarse_large_addr;
assign ram_coarse_large_addr = {ram_coarse_data[31:16],ram_addr[15:0]};

wire [31:0] ram_coarse_small_addr;
assign ram_coarse_small_addr = {ram_coarse_data[31:12],ram_addr[11:0]};

wire [31:0] ram_fine_small_addr;
assign ram_fine_small_addr = {ram_fine_data[31:12],ram_addr[11:0]};

wire [31:0] ram_fine_tiny_addr;
assign ram_fine_tiny_addr = {ram_fine_data[31:10],ram_addr[9:0]};


always @ (*)
if (mmu_enable)
    case(ram_l1_data[1:0])
    2'h0 : ram_addrm = ram_addr;
    2'h1 : case(ram_coarse_data[1:0])
           2'h0 : ram_addrm = ram_addr;
           2'h1 : ram_addrm = ram_coarse_large_addr;
           2'h2 : ram_addrm = ram_coarse_small_addr;
           2'h3 : ram_addrm = ram_addr;
           endcase
    2'h2 : ram_addrm = ram_sec_addr;
	2'h3 : case(ram_fine_data[1:0])
	       2'h0 : ram_addrm = ram_addr;
		   2'h1 : ram_addrm = ram_addr;
		   2'h2 : ram_addrm = ram_fine_small_addr;
		   2'h3 : ram_addrm = ram_fine_tiny_addr;
		   endcase
	endcase
else
    ram_addrm = ram_addr;
	
reg ram_abort= 1'b0;
always @ (posedge clk)
if (ram_abort)
    ram_abort <= #`DEL 1'b0;
else if (ram_cen & mmu_enable)
    case(ram_l1_data[1:0])
    2'h0 :  begin
	           ram_abort <= #`DEL 1'b1;
	           $display("%8d: ram mmu l1 fault at %8h--rom_addr=%8h",$time,ram_addr,rom_addr); 
			end
    2'h1 :  if ((ram_coarse_data[1:0]==2'h0)|(ram_coarse_data[1:0]==2'h3)) begin
	           ram_abort <= #`DEL 1'b1;
               $display("%8d: ram mmu l1 coarse fault at %8h--rom_addr=%8h",$time,ram_addr,rom_addr);
                end
            else;
    2'h2 :  ;
    2'h3 :  if ((ram_fine_data[1:0]==2'h0)|(ram_fine_data[1:0]==2'h1)) begin
	           ram_abort <= #`DEL 1'b1;
               $display("%8d: ram mmu l1 fine fault at %8h--rom_addr=%8h",$time,ram_addr,rom_addr);
                end
            else;
    endcase
else;	
	
	
/*********************************************************/

reg [7:0] rom [4095:0];
initial begin
#1 for(i=0;i<2048;i=i+1)
    rom[i] = u_flash.flash[i];
   for(i=2048;i<4096;i=i+1)
    rom[i] = u_flash.flash[i+64];
end

always @ ( posedge clk )
if ( rom_en )
    if (rom_addrm[31:26]==6'b001100)
        rom_data <= #`DEL {sdram[rom_addrm[25:0]+3],sdram[rom_addrm[25:0]+2],sdram[rom_addrm[25:0]+1],sdram[rom_addrm[25:0]]};
	else if ((rom_addrm[31:26]==6'b0)& ~mmu_enable)
        rom_data <= #`DEL {rom[rom_addrm[25:0]+3],rom[rom_addrm[25:0]+2],rom[rom_addrm[25:0]+1],rom[rom_addrm[25:0]]};	
    else if (~rst)
        $display("%8d: rom physical address overrun at: physical=%8h--virtual=%8h",$time,rom_addrm,rom_addr);	
	else;	
else;

always @ (posedge clk)
if (ram_cen & ram_wen & (ram_addrm[31:26]==6'b001100))
	begin
	if (ram_flag[3]) sdram[ram_addrm[25:0]+3] <= ram_wdata[31:24]; 
	if (ram_flag[2]) sdram[ram_addrm[25:0]+2] <= ram_wdata[23:16];
    if (ram_flag[1]) sdram[ram_addrm[25:0]+1] <= ram_wdata[15:8];
    if (ram_flag[0]) sdram[ram_addrm[25:0]] <= ram_wdata[7:0]; 		
	end 	
else if (ram_cen & ram_wen & (ram_addrm[31:26]==6'b0))
	begin
	if (ram_flag[3]) rom[ram_addrm[25:0]+3] <= ram_wdata[31:24]; 
	if (ram_flag[2]) rom[ram_addrm[25:0]+2] <= ram_wdata[23:16];
    if (ram_flag[1]) rom[ram_addrm[25:0]+1] <= ram_wdata[15:8];
    if (ram_flag[0]) rom[ram_addrm[25:0]] <= ram_wdata[7:0]; 		
	end 		
else;

wire [31:0] nf_rdata;

reg [7:0] dm9000_addr;
reg [7:0] dm9000_data;
always @ (posedge clk)
if (ram_cen & ram_wen & (ram_addrm==32'h20000300))
    dm9000_addr <= #`DEL ram_wdata[7:0];
else;

always @ (posedge clk)
if (ram_cen & ram_wen & (ram_addrm==32'h20000304))
    dm9000_data <= #`DEL ram_wdata[7:0];
else if (ram_cen & ram_wen & (ram_addrm==32'h20000300) & (ram_wdata[7:0]==8'h28))
    dm9000_data <= #`DEL 8'h46;	
else if (ram_cen & ram_wen & (ram_addrm==32'h20000300) & (ram_wdata[7:0]==8'h29))
    dm9000_data <= #`DEL 8'h0a;
else if (ram_cen & ram_wen & (ram_addrm==32'h20000300) & (ram_wdata[7:0]==8'h2a))
    dm9000_data <= #`DEL 8'h00;
else if (ram_cen & ram_wen & (ram_addrm==32'h20000300) & (ram_wdata[7:0]==8'h2b))
    dm9000_data <= #`DEL 8'h90;	
else if (ram_cen & ram_wen & (ram_addrm==32'h20000300) & (ram_wdata[7:0]==8'h2c))
    dm9000_data <= #`DEL 8'h01;		
else;


always @ (posedge clk )
if ( ram_cen & ~ram_wen )
    if (ram_addrm[31:26]==6'b0)
	    ram_rdata <= #`DEL {rom[ram_addrm[25:0]+3],rom[ram_addrm[25:0]+2],rom[ram_addrm[25:0]+1],rom[ram_addrm[25:0]]};
    else if (ram_addrm[31:26]==6'b001100) 
        ram_rdata <= #`DEL {sdram[ram_addrm[25:0]+3],sdram[ram_addrm[25:0]+2],sdram[ram_addrm[25:0]+1],sdram[ram_addrm[25:0]]};
	else if (ram_addrm[31:24]==8'h4e)
        ram_rdata <= #`DEL nf_rdata;
	else if (ram_addrm==32'h50000010)//uart
        ram_rdata <= #`DEL 32'h6;
	else if (ram_addrm==32'h50000008) //ufcon0
        ram_rdata <= #`DEL 32'h0;	
	else if (ram_addrm==32'h560000b0) //cpuid
        ram_rdata <= #`DEL 32'h32440001;
	else if (ram_addrm==32'h4c000004)//MPLL configuration register
        ram_rdata <= #`DEL 32'h0007f021;
	else if (ram_addrm==32'h4c000014)//Clock divider control register
        ram_rdata <= #`DEL 32'h00000005;
	else if (ram_addrm==32'h4c000018)//Camera clock divider register
        ram_rdata <= #`DEL 32'h00000000;
	else if (ram_addrm==32'h4c000008)//UPLL configuration register
        ram_rdata <= #`DEL 32'h00038022;
	else if (ram_addrm==32'h4c000010) //Slow clock control register
        ram_rdata <= #`DEL 32'h00000004;	
	else if (ram_addrm==32'h4c00000c) //Clock generator control register
        ram_rdata <= #`DEL 32'h00fffff0;
	else if (ram_addrm==32'h51000004)//5-MUX & DMA mode selecton register
        ram_rdata <= #`DEL 32'h00000000;
	else if (ram_addrm==32'h560000a8) //External interupt pending Register
        ram_rdata <= #`DEL 32'h00000000;
	else if (ram_addrm==32'h4a000010) //Indicate the interrupt request status.
        ram_rdata <= #`DEL intpnd;
	else if (ram_addrm==32'h4a000018)//Sub source pending
        ram_rdata <= #`DEL 32'h00000002;
	else if (ram_addrm==32'h4a000008) //Determine which interrupt source is masked.
        ram_rdata <= #`DEL subsrcpnd;//32'hffffffff;
    else if (ram_addrm==32'h51000000) //Configures the two 8-bit prescalers
        ram_rdata <= #`DEL tcfg0;	
	else if (ram_addrm==32'h51000008) //Timer control register
        ram_rdata <= #`DEL 32'h00000000;
	else if (ram_addrm==32'h50000004) //UCON
        ram_rdata <= #`DEL 32'h00000245;	
	else if ((ram_addrm==32'h50004004)|(ram_addrm==32'h50008004))
        ram_rdata <= #`DEL 32'h00000000;
	else if (ram_addrm==32'h50000000)
        ram_rdata <= #`DEL 32'h3;
	else if (ram_addrm==32'h50000028)
        ram_rdata <= #`DEL 32'h1a;
	else if (ram_addrm==32'h4a000014)
        ram_rdata <= #`DEL 32'he;
	else if (ram_addrm==32'h51000040)
        ram_rdata <= #`DEL timer4_cnt;	
	else if (ram_addrm==32'h4a000000)
        ram_rdata <= #`DEL srcpnd;
	else if (ram_addrm==32'h56000020)
      	ram_rdata <= #`DEL 32'haaaaaaaa;
	else if (ram_addrm==32'h56000040)
        ram_rdata <= #`DEL 32'haa2aaaaa;
	else if (ram_addrm==32'h54000000)
        ram_rdata <= #`DEL iiccon;	
	else if (ram_addrm==32'h4d000000)
        ram_rdata <= #`DEL 32'h0;
	else if (ram_addrm==32'h56000028) //pull-up disable register for port C
        ram_rdata <= #`DEL 32'hffff;
	else if (ram_addrm==32'h56000038)
        ram_rdata <= #`DEL 32'h877a;
	else if (ram_addrm==32'h56000030) //Configures the pins of port D
        ram_rdata <= #`DEL 32'h151544;	
	else if (ram_addrm==32'h4d000050) //Temporary palette register.
        ram_rdata <= #`DEL 32'h0;
	else if (ram_addrm==32'h56000060) //Configures the pins of port G
        ram_rdata <= #`DEL 32'h100;	
	else if (ram_addrm==32'h56000064) //The data register for port G
        ram_rdata <= #`DEL 32'h7fef;
	else if (ram_addrm==32'h56000010)
        ram_rdata <= #`DEL 32'h44555;
	else if (ram_addrm==32'h56000014)
        ram_rdata <= #`DEL 32'h540;
	else if (ram_addrm==32'h4a00001c)
        ram_rdata <= #`DEL 32'h7ff;
	else if (ram_addrm==32'h48000000)
	    ram_rdata <= #`DEL 32'h22111110;
	else if (ram_addrm==32'h48000014)
        ram_rdata <= #`DEL 32'h700;	
	else if (ram_addrm==32'h20000300)
        ram_rdata <= #`DEL dm9000_addr;
    else if (ram_addrm==32'h20000304)
        ram_rdata <= #`DEL dm9000_data;		
	else
        ram_rdata <= #`DEL 32'h0;	
else;

always @ (posedge clk)
if (ram_cen & ram_wen & (ram_addrm==32'h50000020))
    $write("%s",ram_wdata[7:0]);
else;

reg [31:0] mcr_data=32'hC000507D;
wire inst_mcr;

always @ (posedge clk)
if (inst_mcr)
    if ((rom_data[23:21]==3'h0)&(rom_data[19:16]==4'h1)&(rom_data[11:8]==4'hf)&(rom_data[7:5]==3'h0)&(rom_data[3:0]==4'h0))
	    mcr_data <= #`DEL mmu_enable?32'hC000507D:32'hC000507C;
	else if ((rom_data[23:21]==3'h0)&(rom_data[19:16]==4'h0)&(rom_data[11:8]==4'hf)&(rom_data[7:5]==3'h0)&(rom_data[3:0]==4'h0))
	    mcr_data <= #`DEL 32'h41129200;
    else if ((rom_data[23:21]==3'h0)&(rom_data[19:16]==4'h0)&(rom_data[11:8]==4'hf)&(rom_data[7:5]==3'h1)&(rom_data[3:0]==4'h0))
        mcr_data <= #`DEL 32'h0d172172;   
	else if ((rom_data[23:21]==3'h0)&(rom_data[19:16]==4'h5)&(rom_data[11:8]==4'hf)&(rom_data[7:5]==3'h0)&(rom_data[3:0]==4'h0))
        mcr_data <= #`DEL 32'h5;
	else if ((rom_data[23:21]==3'h0)&(rom_data[19:16]==4'h6)&(rom_data[11:8]==4'hf)&(rom_data[7:5]==3'h0)&(rom_data[3:0]==4'h0))
        mcr_data <= #`DEL 32'h0;		
	else;
else;
/*
integer fd_mcr;
initial fd_mcr = $fopen("mcr_now.txt","w");

always @ (posedge clk)
if (u_arm.cmd_is_mcr & u_arm.cmd_ok)begin
    $fdisplay(fd_mcr,"%7d:%3s p%2d %1d R%1h CR%1h CR%1h %1d-----%8h",$time,u_arm.cmd[20]?"MRC":"MCR",u_arm.cmd[11:8],u_arm.cmd[23:21],u_arm.cmd[15:12],u_arm.cmd[19:16],u_arm.cmd[3:0],u_arm.cmd[7:5],rom_addr-8);
	if (u_arm.cmd[20]& ~( (u_arm.cmd[19:16]==4'h0)|(u_arm.cmd[19:16]==4'h1)|(u_arm.cmd[19:16]==4'h5)|(u_arm.cmd[19:16]==4'h6) ) )begin
        $display("Stop because MRC---");
		print_reg;
		#10 $stop(1);
		end
	else;
	end
else;*/
/*
integer fd_reg;
initial fd_reg = $fopen("reg_now.txt","w");


always @ (posedge clk)
if (ram_cen)
    if (~((ram_addrm[31:26]==6'b001100)|(ram_addrm[31:26]==6'b0))) begin
	    if ( ~((~ram_wen&((ram_addrm==32'h50000008)|(ram_addrm==32'h50000010)|(ram_addrm==32'h4c00000c)))|(ram_wen&((ram_addrm==32'h50000020)))) )
            if (ram_wen)
		        $fdisplay(fd_reg,"%7d: write addr=%8h data= %8h --rom_addr=%8h",$time,ram_addrm,ram_wdata,rom_addr-8);	 
		    else
		        $fdisplay(fd_reg,"%7d: read addr=%8h --rom_addr=%8h",$time,ram_addrm,rom_addr-8);
		else;	*/
		/*
		if (~( (~ram_wen&((ram_addrm==32'h50000010)|(ram_addrm==32'h50000008)|(ram_addrm==32'h560000b0)|(ram_addrm==32'h50000020)|(ram_addrm==32'h4c000004)|(ram_addrm==32'h4c000014)|(ram_addrm==32'h4c000018)|(ram_addrm==32'h4c000008)|(ram_addrm==32'h4c000010)|(ram_addrm==32'h4c00000c)|(ram_addrm==32'h51000004)|(ram_addrm==32'h560000a8)|(ram_addrm==32'h4a000010)|(ram_addrm==32'h4a000018)|(ram_addrm==32'h4a000008)|(ram_addrm==32'h51000000)|(ram_addrm==32'h51000008)|(ram_addrm==32'h50000004)|(ram_addrm==32'h50004004)|(ram_addrm==32'h50008004)|(ram_addrm==32'h50000000)|(ram_addrm==32'h50000028)|(ram_addrm==32'h4a000014)|(ram_addrm==32'h51000040)|(ram_addrm==32'h4a000000)|(ram_addrm==32'h56000020)|(ram_addrm==32'h56000040)|(ram_addrm==32'h54000000)|(ram_addrm==32'h4d000000)|(ram_addrm==32'h56000028)|(ram_addrm==32'h56000038)|(ram_addrm==32'h56000030)|(ram_addrm==32'h4d000050)|(ram_addrm==32'h56000060)|(ram_addrm==32'h56000064)|(ram_addrm==32'h56000010)|(ram_addrm==32'h56000014)|(ram_addrm==32'h4a00001c)|(ram_addrm[31:24]==8'h4e)|(ram_addrm==32'h48000000)|(ram_addrm==32'h48000014)|(ram_addrm==32'h20000304)|(ram_addrm==32'h49000004)|(ram_addrm==32'h49000048)|(ram_addrm==32'h49000034)|(ram_addrm==32'h49000008)))   |   (ram_wen&((ram_addrm==32'h50000020)|(ram_addrm==32'h4c00000c)|(ram_addrm==32'h51000004)|(ram_addrm==32'h4a000018)|(ram_addrm==32'h4a000008)|(ram_addrm==32'h51000000)|(ram_addrm==32'h5100003c)|(ram_addrm==32'h51000008)|(ram_addrm==32'h51000040)|(ram_addrm==32'h50000004)|(ram_addrm==32'h50000000)|(ram_addrm==32'h50000008)|(ram_addrm==32'h50004004)|(ram_addrm==32'h50004000)|(ram_addrm==32'h50004008)|(ram_addrm==32'h50008004)|(ram_addrm==32'h50008000)|(ram_addrm==32'h50008008)|(ram_addrm==32'h5000000c)|(ram_addrm==32'h50000028)|(ram_addrm==32'h4a000010)|(ram_addrm==32'h4a000000)|(ram_addrm==32'h56000020)|(ram_addrm==32'h56000040)|(ram_addrm==32'h54000008)|(ram_addrm==32'h54000000)|(ram_addrm==32'h54000010)|(ram_addrm==32'h4d000000)|(ram_addrm==32'h56000028)|(ram_addrm==32'h56000038)|(ram_addrm==32'h56000030)|(ram_addrm==32'h4d000060)|(ram_addrm==32'h4d000050)|(ram_addrm==32'h4d000004)|(ram_addrm==32'h4d000008)|(ram_addrm==32'h4d00000c)|(ram_addrm==32'h4d000010)|(ram_addrm==32'h4d000014)|(ram_addrm==32'h4d000018)|(ram_addrm==32'h4d00001c)|(ram_addrm==32'h56000060)|(ram_addrm==32'h56000064)|(ram_addrm==32'h56000010)|(ram_addrm==32'h56000014)|(ram_addrm==32'h58000004)|(ram_addrm==32'h4a00001c)|(ram_addrm[31:24]==8'h4e)|(ram_addrm==32'h48000000)|(ram_addrm==32'h48000014)|(ram_addrm==32'h20000300)|(ram_addrm==32'h20000304)|(ram_addrm==32'h4c000010)|(ram_addrm==32'h49000014)|(ram_addrm==32'h49000004)|(ram_addrm==32'h49000008)|(ram_addrm==32'h49000020)|(ram_addrm==32'h49000028)|(ram_addrm==32'h49000018)|(ram_addrm==32'h49000034)|(ram_addrm==32'h49000040))) ) ) begin
	        $display("Stop because RAM---");
	        print_reg;
			//save_core;
	        #10 $stop(1);
			end
		else;*/	
//	end
//	else;
//else;


/*
task print_reg;
begin
$display("--%8h--%8h--%8h--%8h\n--%8h--%8h--%8h--%8h\n--%8h--%8h--%8h--%8h\n--%8h--%8h--%8h--%8h\n",u_arm.r0,u_arm.r1,u_arm.r2,u_arm.r3,u_arm.r4,u_arm.r5,u_arm.r6,u_arm.r7,u_arm.r8,u_arm.r9,u_arm.ra,u_arm.rb,u_arm.rc,u_arm.rd,u_arm.re,u_arm.rf);
if (u_arm.go_vld)
    $display("R%h should be %8h",u_arm.go_num,u_arm.go_data);
else;
end
endtask
*/

arm u_arm(
          .clk         (             clk          ),
          .cpu_en      (             1'b1         ),
          .cpu_restart (             1'b0         ),
          .fiq         (             1'b0         ),
          .irq         (             irq          ),
		  .mcr_data    (             mcr_data     ),
          .ram_abort   (             ram_abort    ),
          .ram_rdata   (             ram_rdata    ),
          .rom_abort   (             rom_abort    ),
          .rom_data    (             rom_data     ),
          .rst         (             rst          ),

		  .inst_mcr    (             inst_mcr     ),
          .ram_addr    (             ram_addr     ),
          .ram_cen     (             ram_cen      ),
          .ram_flag    (             ram_flag     ),
          .ram_wdata   (             ram_wdata    ),
          .ram_wen     (             ram_wen      ),
          .rom_addr    (             rom_addr     ),
          .rom_en      (             rom_en       )
        ); 
///*
nand_flash u_flash (
          .clk         (             clk          ),
          .rst         (             rst          ),
          .nf_read     (  ram_cen & ~ram_wen &(ram_addrm[31:24]==8'h4e)),
		  .nf_write    (  ram_cen &  ram_wen &(ram_addrm[31:24]==8'h4e)),
		  .nf_ben      (             ram_flag     ),
		  .nf_num      (             ram_addrm[7:0]),
		  .nf_wdata    (             ram_wdata    ),
		  
		  .nf_rdata    (             nf_rdata     )

        );		
//*/
/*
task save_core;
integer fd_sdram;
integer fd_core;
integer i;
begin
fd_sdram = $fopen("sdram_now.txt","w");
fd_core = $fopen("core_now.txt","w");
for (i=0;i<=((1<<26)-1);i=i+1)   
if (i%16==15)
    $fdisplay(fd_sdram," %2h",sdram[i]);
else
    $fwrite(fd_sdram," %2h",sdram[i]); 
$fdisplay(fd_core,"%8h",(u_arm.go_vld&(u_arm.go_num==4'h0))?u_arm.go_data:u_arm.r0);
$fdisplay(fd_core,"%8h",(u_arm.go_vld&(u_arm.go_num==4'h1))?u_arm.go_data:u_arm.r1);
$fdisplay(fd_core,"%8h",(u_arm.go_vld&(u_arm.go_num==4'h2))?u_arm.go_data:u_arm.r2);
$fdisplay(fd_core,"%8h",(u_arm.go_vld&(u_arm.go_num==4'h3))?u_arm.go_data:u_arm.r3);	
$fdisplay(fd_core,"%8h",(u_arm.go_vld&(u_arm.go_num==4'h4))?u_arm.go_data:u_arm.r4);
$fdisplay(fd_core,"%8h",(u_arm.go_vld&(u_arm.go_num==4'h5))?u_arm.go_data:u_arm.r5);
$fdisplay(fd_core,"%8h",(u_arm.go_vld&(u_arm.go_num==4'h6))?u_arm.go_data:u_arm.r6);
$fdisplay(fd_core,"%8h",(u_arm.go_vld&(u_arm.go_num==4'h7))?u_arm.go_data:u_arm.r7);	
$fdisplay(fd_core,"%8h",(u_arm.go_vld&(u_arm.go_num==4'h8)&(u_arm.cpsr_m!=5'b10001))?u_arm.go_data:u_arm.r8_usr);
$fdisplay(fd_core,"%8h",(u_arm.go_vld&(u_arm.go_num==4'h8)&(u_arm.cpsr_m==5'b10001))?u_arm.go_data:u_arm.r8_fiq);
$fdisplay(fd_core,"%8h",(u_arm.go_vld&(u_arm.go_num==4'h9)&(u_arm.cpsr_m!=5'b10001))?u_arm.go_data:u_arm.r9_usr);
$fdisplay(fd_core,"%8h",(u_arm.go_vld&(u_arm.go_num==4'h9)&(u_arm.cpsr_m==5'b10001))?u_arm.go_data:u_arm.r9_fiq);	
$fdisplay(fd_core,"%8h",(u_arm.go_vld&(u_arm.go_num==4'ha)&(u_arm.cpsr_m!=5'b10001))?u_arm.go_data:u_arm.ra_usr);
$fdisplay(fd_core,"%8h",(u_arm.go_vld&(u_arm.go_num==4'ha)&(u_arm.cpsr_m==5'b10001))?u_arm.go_data:u_arm.ra_fiq);
$fdisplay(fd_core,"%8h",(u_arm.go_vld&(u_arm.go_num==4'hb)&(u_arm.cpsr_m!=5'b10001))?u_arm.go_data:u_arm.rb_usr);
$fdisplay(fd_core,"%8h",(u_arm.go_vld&(u_arm.go_num==4'hb)&(u_arm.cpsr_m==5'b10001))?u_arm.go_data:u_arm.rb_fiq);
$fdisplay(fd_core,"%8h",(u_arm.go_vld&(u_arm.go_num==4'hc)&(u_arm.cpsr_m!=5'b10001))?u_arm.go_data:u_arm.rc_usr);
$fdisplay(fd_core,"%8h",(u_arm.go_vld&(u_arm.go_num==4'hc)&(u_arm.cpsr_m==5'b10001))?u_arm.go_data:u_arm.rc_fiq);
$fdisplay(fd_core,"%8h",(u_arm.go_vld&(u_arm.go_num==4'hd)&((u_arm.cpsr_m==5'b10000)|(u_arm.cpsr_m==5'b11111)))?u_arm.go_data:u_arm.rd_usr);
$fdisplay(fd_core,"%8h",(u_arm.go_vld&(u_arm.go_num==4'hd)&(u_arm.cpsr_m==5'b10111))?u_arm.go_data:u_arm.rd_abt);
$fdisplay(fd_core,"%8h",(u_arm.go_vld&(u_arm.go_num==4'hd)&(u_arm.cpsr_m==5'b10001))?u_arm.go_data:u_arm.rd_fiq);
$fdisplay(fd_core,"%8h",(u_arm.go_vld&(u_arm.go_num==4'hd)&(u_arm.cpsr_m==5'b10010))?u_arm.go_data:u_arm.rd_irq);
$fdisplay(fd_core,"%8h",(u_arm.go_vld&(u_arm.go_num==4'hd)&(u_arm.cpsr_m==5'b10011))?u_arm.go_data:u_arm.rd_svc);
$fdisplay(fd_core,"%8h",(u_arm.go_vld&(u_arm.go_num==4'hd)&(u_arm.cpsr_m==5'b11011))?u_arm.go_data:u_arm.rd_und);
$fdisplay(fd_core,"%8h",(u_arm.go_vld&(u_arm.go_num==4'he)&((u_arm.cpsr_m==5'b10000)|(u_arm.cpsr_m==5'b11111)))?u_arm.go_data:u_arm.re_usr);
$fdisplay(fd_core,"%8h",(u_arm.go_vld&(u_arm.go_num==4'he)&(u_arm.cpsr_m==5'b10111))?u_arm.go_data:u_arm.re_abt);
$fdisplay(fd_core,"%8h",(u_arm.go_vld&(u_arm.go_num==4'he)&(u_arm.cpsr_m==5'b10001))?u_arm.go_data:u_arm.re_fiq);
$fdisplay(fd_core,"%8h",(u_arm.go_vld&(u_arm.go_num==4'he)&(u_arm.cpsr_m==5'b10010))?u_arm.go_data:u_arm.re_irq);
$fdisplay(fd_core,"%8h",(u_arm.go_vld&(u_arm.go_num==4'he)&(u_arm.cpsr_m==5'b10011))?u_arm.go_data:u_arm.re_svc);
$fdisplay(fd_core,"%8h",(u_arm.go_vld&(u_arm.go_num==4'he)&(u_arm.cpsr_m==5'b11011))?u_arm.go_data:u_arm.re_und);	
$fdisplay(fd_core,"%8h",u_arm.cmd_flag ? (u_arm.rf-8 ):(u_arm.code_flag?(u_arm.rf-4) :u_arm.rf));
$fdisplay(fd_core,"%1h",u_arm.cpsr_n);
$fdisplay(fd_core,"%1h",u_arm.cpsr_z);	
$fdisplay(fd_core,"%1h",u_arm.cpsr_c);
$fdisplay(fd_core,"%1h",u_arm.cpsr_v);
$fdisplay(fd_core,"%1h",u_arm.cpsr_i);
$fdisplay(fd_core,"%1h",u_arm.cpsr_f);
$fdisplay(fd_core,"%2h",u_arm.cpsr_m);
$fdisplay(fd_core,"%3h",u_arm.spsr_abt);
$fdisplay(fd_core,"%3h",u_arm.spsr_fiq);	
$fdisplay(fd_core,"%3h",u_arm.spsr_irq);
$fdisplay(fd_core,"%3h",u_arm.spsr_svc);	
$fdisplay(fd_core,"%3h",u_arm.spsr_und);
$fdisplay(fd_core,"%h",mmu_enable);
$fdisplay(fd_core,"%h",ttb);
$fdisplay(fd_core,"%h",subsrcpnd);
$fdisplay(fd_core,"%h",tcfg0);
$fdisplay(fd_core,"%h",intpnd);
$fdisplay(fd_core,"%h",srcpnd);
$fdisplay(fd_core,"%h",iiccon);
$fdisplay(fd_core,"%h",timer4_enable);
$fdisplay(fd_core,"%h",timer4_cnt);
$fclose(fd_sdram);
$fclose(fd_core);	
end
endtask
*/
/*
always @ (posedge clk)
if (ram_cen & (ram_addrm[31:24]==8'h4e)) begin
    save_core;
	$stop(1);
	end
else;
 */   
 
 /*
always @ (posedge clk)
if (ram_cen & ram_wen &(ram_addrm==32'h4e000008)& ~((ram_wdata[7:0]==8'h0)|(ram_wdata[7:0]==8'h30)|(ram_wdata[7:0]==8'h70)|(ram_wdata[7:0]==8'h60)|(ram_wdata[7:0]==8'hd0)) ) begin
    $display("%d:Error flash command rom_addr=%h",$time,rom_addr);
	//save_core;
	$stop(1);
	end
else;
*/
endmodule		