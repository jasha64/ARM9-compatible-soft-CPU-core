//综合前，运行如下指令：
//set_param synth.elaboration.rodinMoreOptions {rt::set_parameter ignoreVhdlAssertStmts false}
//每次重新启动Vivado均需重新运行一次。
module hello_top (
   clk_100m,
   btnd,
   RxD,
   
   TxD
   );
   
input              clk_100m;
input              btnd;
input              RxD;

output             TxD;

wire               clk;
wire               rst;
wire  [31:0]       rom_data;
wire  [31:0]       ram_addr;
wire               ram_cen;
wire  [3:0]        ram_flag;
wire  [31:0]       ram_wdata;
wire               ram_wen;
wire  [31:0]       rom_addr;
wire               rom_en;
wire  [31:0]       ram_rdata_rom;
wire  [31:0]       ram_rdata_ram;
wire               rx_vld;
wire  [7:0]        rx_data;
wire               txrdy;

reg   [31:0]       ram_rdata;
reg   [3:0]        rd_sel;
reg                tx_vld;
reg   [7:0]        tx_data;

  pll u_pll
   (// Clock in ports
    .clk_in1            (clk_100m),      // IN
    // Clock out ports
    .clk_out1           (clk));    // OUT

assign rst = btnd;

arm9_compatiable_code u_arm9(
          .clk                 (    clk                   ),
          .cpu_en              (    1'b1                  ),
          .cpu_restart         (    1'b0                  ),
          .fiq                 (    1'b0                  ),
          .irq                 (    1'b0                  ),
          .ram_abort           (    1'b0                  ),
          .ram_rdata           (    ram_rdata             ),
          .rom_abort           (    1'b0                  ),
          .rom_data            (    rom_data              ),
          .rst                 (    rst                   ),

          .ram_addr            (    ram_addr              ),
          .ram_cen             (    ram_cen               ),
          .ram_flag            (    ram_flag              ),
          .ram_wdata           (    ram_wdata             ),
          .ram_wen             (    ram_wen               ),
          .rom_addr            (    rom_addr              ),
          .rom_en              (    rom_en                )
        ); 

rom  u_rom(
	      .addra               (    rom_addr[12:2]                               ),
	      .addrb               (    ram_addr[12:2]                               ),
	      .clka                (    clk                                          ),
	      .clkb                (    clk                                          ),
	      .douta               (    rom_data                                     ),
	      .doutb               (    ram_rdata_rom                                ),
	      .ena                 (    rom_en                                       ),
	      .enb                 (    ram_cen & ~ram_wen & (ram_addr[31:28]==4'h0) )
		  );		

		
ram u_ram (

         .clka                  (    clk                                 ),
	     .ena                   (    ram_cen & (ram_addr[31:28]==4'h4)   ),
	     .wea                   (    ram_wen ? ram_flag : 4'h0           ),
	     .addra                 (    ram_addr[10:2]                      ),
	     .dina                  (    ram_wdata                           ),
	     
	     .douta                 (    ram_rdata_ram                       )
	);		  
		
rxtx 
#( .baud ( 115200 ),
   .mhz  ( 25     )
 )
u_uart (
         .clk                  (    clk                  ),
		 .rst                  (    rst                  ),
		 .rx                   (    RxD                  ),
		 .tx_vld               (    tx_vld               ),
		 .tx_data              (    tx_data              ),
		
		 .rx_vld               (    rx_vld               ),
		 .rx_data              (    rx_data              ),
		 .tx                   (    TxD                  ),
		 .txrdy                (    txrdy                )
			);	
		
always @ (posedge clk or posedge rst )
if ( rst )
    rd_sel <= 4'b1;
else if (ram_cen & ~ram_wen)
    rd_sel <= { (ram_addr==32'he0000000),(ram_addr[31:28]==4'h0),(ram_addr[31:28]==4'h4) };
else;
	
always @ ( * )
if (rd_sel[2])
    ram_rdata = txrdy ? 32'h0:32'h1;
else if (rd_sel[1])
    ram_rdata = ram_rdata_rom;
else //if (rd_sel[0])
    ram_rdata = ram_rdata_ram;

always @ (posedge clk or posedge rst )
if ( rst )
    tx_vld <= 1'b0;
else
    tx_vld <= ram_cen & ram_wen & (ram_addr==32'he0000004);
	
always @ (posedge clk or posedge rst )
if ( rst )
    tx_data <= 8'h0;
else if ( ram_cen & ram_wen & (ram_addr==32'he0000004) )
    tx_data <= ram_wdata[7:0];
else;

endmodule
		

