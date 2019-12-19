`define DEL 2
`timescale 1 ns/1 ns
module tb;

parameter  memLoadFile = "../Obj/uclinux0.bin";
parameter  BootLoadFile = "../Obj/boot0.bin";

reg            clk;
reg            rst;
reg            cpu_en;
reg            cpu_restart;
reg            irq;
reg            fiq;
wire           rom_en;
wire    [31:0] rom_addr; 	
reg     [31:0] rom_data;
reg            rom_abort;
wire           sp_cen;
wire           sp_wen;
wire    [31:0] sp_addr;
wire    [31:0] sp_rd_data;
reg            sp_rd_abort;
wire    [31:0] sp_wr_data;
wire    [3:0]  sp_flag;

reg [7:0] rd_data0,rd_data1,rd_data2,rd_data3;

reg [7:0] rom_all [917939:0];


arm9core u_arm9core (
          .clk                    (      clk          ),
          .cpu_en                 (      cpu_en       ),
          .cpu_restart            (      cpu_restart  ),
          .fiq                    (      fiq          ),
          .irq                    (      irq          ),
          .ram_abort              (      sp_rd_abort  ),
          .ram_rdata              (      sp_rd_data   ),
          .rom_abort              (      rom_abort    ),
          .rom_data               (      rom_data     ),
          .rst                    (      rst          ),

          .ram_addr               (      sp_addr      ),
          .ram_cen                (      sp_cen       ),
          .ram_flag               (      sp_flag      ),
          .ram_wdata              (      sp_wr_data   ),
          .ram_wen                (      sp_wen       ),
          .rom_addr               (      rom_addr     ),
          .rom_en                 (      rom_en       )
        ); 
		

integer i;
			 
initial begin
clk = 1'b0;
cpu_restart = 1'b0;
irq = 1'b0;
fiq = 1'b0;
rom_abort = 1'b0;
sp_rd_abort = 1'b0;
rst = 1'b0;
cpu_en = 1'b1;
#10 rst = 1'b1;
#20 rst = 1'b0;
cpu_restart = 1'b1;
#10 cpu_restart = 1'b0;

end

always clk = #5 ~clk;

reg [7:0] boot_all[383999:0];

initial begin
      if ( BootLoadFile != "")
        $readmemh(BootLoadFile, boot_all);  
end

reg [7:0] ram0 [65536-1:0];
reg [7:0] ram1 [4194304-1:0];
reg [7:0] ram2 [4194304-1:0];
reg [7:0] ram3 [4194304-1:0];     
initial begin
#1 for (i=0;i<65536;i=i+1) begin
   ram0[i] = 8'h00;
end
for (i=0;i<4194304;i=i+1) begin
   if ( i<926452)
       ram1[i] = rom_all[i];
   else
       ram1[i] = 8'h00;
end
for (i=0;i<4194304;i=i+1) begin
    if ( i<479232 )
	    ram2[i] = boot_all[i];
	else
	    ram2[i] = 8'h00;
end
for (i=0;i<4194304;i=i+1)
    ram3[i] = 8'h00;
end     

reg [7:0] irq_num=5;
reg irq_flag = 0;

always @ ( posedge clk )
if ( irq )
    irq_num <= 5;
else if ( sp_cen & sp_wen & ( sp_addr==32'hfffff130 ) ) begin
    if ( irq_flag ) begin
	    irq_num  <= 6;
		irq_flag <= 0;
		end
	else
	    irq_num <= 0;
	end
else;
    
		
				

always @ ( posedge clk or posedge rst )
if ( rst )
    rd_data0 <= 8'h0;
else if ( sp_cen & sp_flag[0] )
    if ( ~sp_wen )
	    if ( ( sp_addr>=32'h0 ) & ( sp_addr < 32'h4000 ) )
		    rd_data0 <= ram0[sp_addr];
		else if ( ( sp_addr>=32'h01000000 ) & ( sp_addr < 32'h01400000 ) )
		    rd_data0 <= ram1[(sp_addr-32'h01000000)];
		else if ( ( sp_addr>=32'h01400000 ) & ( sp_addr < 32'h01800000 ) )
		    rd_data0 <= ram2[(sp_addr-32'h01400000)];
		else if ( ( sp_addr>=32'h02000000 ) & ( sp_addr < 32'h02400000 ) )
		    rd_data0 <= ram3[(sp_addr-32'h02000000)];
		else if ( sp_addr==32'hfff00000 )
		    rd_data0 <= 8'h40;
		else if ( sp_addr==32'hfffe00c4 )
		    rd_data0 <= 8'hff;
		else if ( sp_addr==32'hfffd0014 )
		    rd_data0 <= 8'h0b;
		else if ( sp_addr==32'hfffff100 ) 
		    rd_data0 <= irq_num;
		else if ( sp_addr==32'hfffff108 )  
		    rd_data0 <= irq_num;
		else if ( sp_addr==32'hfffe0060 )
		    rd_data0 <= 8'hff;
		else if ( sp_addr==32'hfffe0050 )
		    rd_data0 <= 8'h12;			
		else
		    rd_data0 <= $random;
	else
	    if ( ( sp_addr>=32'h0 ) & ( sp_addr < 32'h4000 ) )
		    ram0[sp_addr] <= sp_wr_data[7:0];
		else if ( ( sp_addr>=32'h01000000 ) & ( sp_addr < 32'h01400000 ) )
		    ram1[(sp_addr-32'h01000000)] <= sp_wr_data[7:0];
		else if ( ( sp_addr>=32'h01400000 ) & ( sp_addr < 32'h01800000 ) )
		    ram2[(sp_addr-32'h01400000)] <= sp_wr_data[7:0];
		else if ( ( sp_addr>=32'h02000000 ) & ( sp_addr < 32'h02400000 ) )
		    ram3[(sp_addr-32'h02000000)] <= sp_wr_data[7:0];
		else;	
else;


always @ ( posedge clk or posedge rst )
if ( rst )
    rd_data1 <= 8'h0;
else if ( sp_cen & sp_flag[1] )
    if ( ~sp_wen )
	    if ( ( sp_addr>=32'h0 ) & ( sp_addr < 32'h4000 ) )
		    rd_data1 <= ram0[sp_addr+1];
		else if ( ( sp_addr>=32'h01000000 ) & ( sp_addr < 32'h01400000 ) )
		    rd_data1 <= ram1[(sp_addr-32'h01000000)+1];
		else if ( ( sp_addr>=32'h01400000 ) & ( sp_addr < 32'h01800000 ) )
		    rd_data1 <= ram2[(sp_addr-32'h01400000)+1];
		else if ( ( sp_addr>=32'h02000000 ) & ( sp_addr < 32'h02400000 ) )
		    rd_data1 <= ram3[(sp_addr-32'h02000000)+1];
		else if ( sp_addr==32'hfff00000 )
		    rd_data1 <= 8'h00;
		else if ( sp_addr==32'hfffe00c4 )
		    rd_data1 <= 8'hff;
		else if ( sp_addr==32'hfffd0014 )
		    rd_data1 <= 8'h02;
		else if ( sp_addr==32'hfffff100 )
		    rd_data1 <= 8'h00;
		else if ( sp_addr==32'hfffff108 )
		    rd_data1 <= 8'h00;
		else if ( sp_addr==32'hfffe0060 )
		    rd_data1 <= 8'hff;
		else if ( sp_addr==32'hfffe0050 )
		    rd_data1 <= 8'h00;	
		else
		    rd_data1 <= $random;
	else
	    if ( ( sp_addr>=32'h0 ) & ( sp_addr < 32'h4000 ) )
		    ram0[(sp_addr)+1] <= sp_wr_data[15:8];
		else if ( ( sp_addr>=32'h01000000 ) & ( sp_addr < 32'h01400000 ) )
		    ram1[(sp_addr-32'h01000000)+1] <= sp_wr_data[15:8];
		else if ( ( sp_addr>=32'h01400000 ) & ( sp_addr < 32'h01800000 ) )
		    ram2[(sp_addr-32'h01400000)+1] <= sp_wr_data[15:8];
		else if ( ( sp_addr>=32'h02000000 ) & ( sp_addr < 32'h02400000 ) )
		    ram3[(sp_addr-32'h02000000)+1] <= sp_wr_data[15:8];
		else;	
else;



always @ ( posedge clk or posedge rst )
if ( rst )
    rd_data2 <= 8'h0;
else if ( sp_cen & sp_flag[2] )
    if ( ~sp_wen )
	    if ( ( sp_addr>=32'h0 ) & ( sp_addr < 32'h4000 ) )
		    rd_data2 <= ram0[(sp_addr)+2];
		else if ( ( sp_addr>=32'h01000000 ) & ( sp_addr < 32'h01400000 ) )
		    rd_data2 <= ram1[(sp_addr-32'h01000000)+2];
		else if ( ( sp_addr>=32'h01400000 ) & ( sp_addr < 32'h01800000 ) )
		    rd_data2 <= ram2[(sp_addr-32'h01400000)+2];
		else if ( ( sp_addr>=32'h02000000 ) & ( sp_addr < 32'h02400000 ) )
		    rd_data2 <= ram3[(sp_addr-32'h02000000)+2];
		else if ( sp_addr==32'hfff00000 )
		    rd_data2 <= 8'h00;
		else if ( sp_addr==32'hfffe00c4 )
		    rd_data2 <= 8'hff;
		else if ( sp_addr==32'hfffd0014 )
		    rd_data2 <= 8'h00;
		else if ( sp_addr==32'hfffff100 )
		    rd_data2 <= 8'h00;
		else if ( sp_addr==32'hfffff108 )
		    rd_data2 <= 8'h00;
		else if ( sp_addr==32'hfffe0060 )
		    rd_data2 <= 8'hff;
		else if ( sp_addr==32'hfffe0050 )
		    rd_data2 <= 8'h00;				
		else
		    rd_data2 <= $random;
	else
	    if ( ( sp_addr>=32'h0 ) & ( sp_addr < 32'h4000 ) )
		    ram0[(sp_addr)+2] <= sp_wr_data[23:16];
		else if ( ( sp_addr>=32'h01000000 ) & ( sp_addr < 32'h01400000 ) )
		    ram1[(sp_addr-32'h01000000)+2] <= sp_wr_data[23:16];
		else if ( ( sp_addr>=32'h01400000 ) & ( sp_addr < 32'h01800000 ) )
		    ram2[(sp_addr-32'h01400000)+2] <= sp_wr_data[23:16];
		else if ( ( sp_addr>=32'h02000000 ) & ( sp_addr < 32'h02400000 ) )
		    ram3[(sp_addr-32'h02000000)+2] <= sp_wr_data[23:16];
		else;	
else;


always @ ( posedge clk or posedge rst )
if ( rst )
    rd_data3 <= 8'h0;
else if ( sp_cen & sp_flag[3] )
    if ( ~sp_wen )
	    if ( ( sp_addr>=32'h0 ) & ( sp_addr < 32'h4000 ) )
		    rd_data3 <= ram0[(sp_addr)+3];
		else if ( ( sp_addr>=32'h01000000 ) & ( sp_addr < 32'h01400000 ) )
		    rd_data3 <= ram1[(sp_addr-32'h01000000)+3];
		else if ( ( sp_addr>=32'h01400000 ) & ( sp_addr < 32'h01800000 ) )
		    rd_data3 <= ram2[(sp_addr-32'h01400000)+3];
		else if ( ( sp_addr>=32'h02000000 ) & ( sp_addr < 32'h02400000 ) )
		    rd_data3 <= ram3[(sp_addr-32'h02000000)+3];
		else if ( sp_addr==32'hfff00000 )
		    rd_data3 <= 8'h14;
		else if ( sp_addr==32'hfffe00c4 )
		    rd_data3 <= 8'hff;
		else if ( sp_addr==32'hfffd0014 )
		    rd_data3 <= 8'h00;
		else if ( sp_addr==32'hfffff100 )
		    rd_data3 <= 8'h00;
		else if ( sp_addr==32'hfffff108 )
		    rd_data3 <= 8'h00;
		else if ( sp_addr==32'hfffe0060 )
		    rd_data3 <= 8'hff;
		else if ( sp_addr==32'hfffe0050 )
		    rd_data3 <= 8'h00;	
		else
		    rd_data3 <= $random;
	else
	    if ( ( sp_addr>=32'h0 ) & ( sp_addr < 32'h4000 ) )
		    ram0[(sp_addr)+3] <= sp_wr_data[31:24];
		else if ( ( sp_addr>=32'h01000000 ) & ( sp_addr < 32'h01400000 ) )
		    ram1[(sp_addr-32'h01000000)+3] <= sp_wr_data[31:24];
		else if ( ( sp_addr>=32'h01400000 ) & ( sp_addr < 32'h01800000 ) )
		    ram2[(sp_addr-32'h01400000)+3] <= sp_wr_data[31:24];
		else if ( ( sp_addr>=32'h02000000 ) & ( sp_addr < 32'h02400000 ) )
		    ram3[(sp_addr-32'h02000000)+3] <= sp_wr_data[31:24];
		else;	
else;



assign sp_rd_data = {rd_data3,rd_data2,rd_data1,rd_data0};

/**************************************************************/




initial begin
      if ( memLoadFile != "")
        $readmemh(memLoadFile, rom_all);  
end

wire [31:0] in_addr;
assign in_addr = rom_addr;

always @ ( posedge clk )
if ( rom_en )
    if ( rom_addr[31:20]==12'h010 )
        rom_data <= #2 { ram1[in_addr[21:0]+2'd3],ram1[in_addr[21:0]+2'd2],ram1[in_addr[21:0]+2'd1],ram1[in_addr[21:0]]};
	else if ( rom_addr[31:20]==12'h014 )
	    rom_data <= #2 { ram2[in_addr[21:0]+2'd3],ram2[in_addr[21:0]+2'd2],ram2[in_addr[21:0]+2'd1],ram2[in_addr[21:0]]}; 
	else
	    rom_data <= #2 { ram0[in_addr[13:0]+2'd3],ram0[in_addr[13:0]+2'd2],ram0[in_addr[13:0]+2'd1],ram0[in_addr[13:0]]}; 
else;
	

reg [23:0] addr_reg;
always @ ( posedge clk )
if ( sp_cen & sp_wen & ( sp_addr ==  32'hfffd0038 ) )
    addr_reg <= sp_wr_data[23:0];
else;

reg [7:0] print_len=1;
always @ ( posedge clk )
if ( sp_cen & sp_wen & ( sp_addr ==  32'hfffd003c ) )
    print_len <= sp_wr_data[7:0];
else;

always @ ( posedge clk )
if ( sp_cen & ~sp_wen & ( sp_addr==32'hfffd0014 ) ) begin
    for (i=0;i<print_len;i=i+1 )
	$write("%s",ram1[addr_reg+i]);
	end
else;



initial begin
#7109927 irq = 1;
//$display("\nA IRQ Here-1-\n");
#10 irq = 0;
#250718;
#2737517 irq = 1;
//$display("\nA IRQ Here-2-\n");
#10 irq = 0;
#2934647 irq = 1;
//$display("\nA IRQ Here-3-\n");
#10 irq = 0; //13032839
#2825411 irq = 1; 
//$display("\nA IRQ Here-4-\n");
#10 irq = 0; //15858260
#417730 ;//16275990
#2192710 irq = 1;
//$display("\nA IRQ Here-5-\n");
#10 irq = 0; //18468710
#3040400 irq = 1;
//$display("\nA IRQ Here-6-\n");
#10 irq = 0; //21509100 
#2716070 irq = 1;
//$display("\nA IRQ Here-7-\n");
#10 irq = 0; //24225170 
#584130 ;//24809300
#2077340 irq = 1;
//$display("\nA IRQ Here-8-\n");
#10 irq = 0;//26886650
#2634170 irq = 1;
//$display("\nA IRQ Here-9-\n");
#10 irq = 0;//29520830
#2620510 irq = 1;
//$display("\nA IRQ Here-10-\n");
#10 irq = 0;//32141350
#2613690 irq = 1;
//$display("\nA IRQ Here-11-\n");
#10 irq = 0;//34755040
#2610430 irq = 1;
//$display("\nA IRQ Here-12-\n");
#10 irq = 0;//37365300
#3043820 irq = 1;
//$display("\nA IRQ Here-13-\n");
#10 irq = 0;//40409350
#2610430 irq = 1;
//$display("\nA IRQ Here-14-\n");
#10 irq = 0;//43019790
#3042120 irq = 1;
//$display("\nA IRQ Here-15-\n");
#10 irq = 0;//46061920
#2610440 irq = 1;
//$display("\nA IRQ Here-16-\n");
#10 irq = 0;//48672370
#2106680 irq = 1;
//$display("\nA IRQ Here-17-\n");
#10 irq = 0;//50779060
#2041210 irq = 1;
//$display("\nA IRQ Here-18-\n");
#10 irq = 0;//52820280
#2273270 irq = 1;
//$display("\nA IRQ Here-19-\n");
#10 irq = 0;//55093560
#2324600 irq = 1;
//$display("\nA IRQ Here-20-\n");
#10 irq = 0;//57418160
#2241780 irq = 1;
//$display("\nA IRQ Here-21-\n");
#10 irq = 0;//59659960
#2508810 irq = 1;
//$display("\nA IRQ Here-22-\n");
#10 irq = 0;//62168780
#2481000 irq = 1;
//$display("\nA IRQ Here-23-\n");
#10 irq = 0;//64649790
#2535220 irq = 1;
    irq_flag = 1;
//$display("\nA IRQ Here-24-\n");
#10 irq = 0;//67185020
#2866150 irq = 1;
//$display("\nA IRQ Here-25-\n");
#10 irq = 0;//70051180
#2513840 irq = 1;
//$display("\nA IRQ Here-26-\n");
#10 irq = 0;//72565020
#2350380 irq = 1;
//$display("\nA IRQ Here-26-\n");
#10 irq = 0;//74915420
//$stop(1);
end


	
//total 90 ms
		
endmodule             