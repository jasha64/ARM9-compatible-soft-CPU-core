//通过串口输入测试次数n时，需要选择发送附加位（正校验）
module dhry_top (
   clk_100m,
   btnd,
   sw0,
   RxD,
   
   TxD
   );
   
input              clk_100m;
input              btnd;
input              sw0;
input              RxD;

output             TxD;


wire               clk;
wire               rst;
wire               irq;
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
reg                irq_delay;
wire               cpu_en;

 pll u_pll
   (// Clock in ports
    .clk_in1            (clk_100m),      // IN
    // Clock out ports
    .clk_out1           (clk));    // OUT

assign rst = btnd;

assign cpu_en = sw0;


reg [17:0] timer_cnt;
always @ (posedge clk or posedge rst )
if ( rst )
    timer_cnt <= 18'b0;
else if ( timer_cnt == 18'd249999 )
    timer_cnt <= 18'b0;
else
    timer_cnt <= timer_cnt + 1'b1;
	
assign irq = ( timer_cnt == 18'd249999 );

arm9_compatiable_code u_arm9(
          .clk                 (    clk                   ),
          .cpu_en              (    cpu_en                ),
          .cpu_restart         (    1'b0                  ),
          .fiq                 (    1'b0                  ),
          .irq                 (    irq                   ),
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
		
		
reg [14:0] wr_addr;
always @ (posedge clk or posedge rst )
if ( rst )
    wr_addr <= 14'b0;
else if (cpu_en)
    wr_addr <= 14'b0;
else if (rx_vld)
    wr_addr <= wr_addr + 1'b1;
else;

reg [23:0] wr_data;
always @ (posedge clk or posedge rst )
if ( rst )
    wr_data <= 24'b0;
else if (cpu_en)
    wr_data <= 24'b0;
else if (rx_vld & (wr_addr[1:0]!=2'b11) )
    wr_data <= {rx_data,wr_data[23:8]};
else;
		 
		 
rom  u_rom(
	      .addra               (    cpu_en ? rom_addr[14:2] : wr_addr[14:2]      ),
	      .addrb               (    ram_addr[14:2]       ),
	      .clka                (    clk                  ),
	      .clkb                (    clk                  ),
		  .dina                (    {rx_data,wr_data}    ),
	      .douta               (    rom_data             ),
	      .doutb               (    ram_rdata_rom        ),
	      .ena                 (    cpu_en ? rom_en : (rx_vld & (wr_addr[1:0]==2'b11))    ),
	      .enb                 (    ram_cen & ~ram_wen & (ram_addr[31:28]==4'h0) ),
		  .wea                 (    cpu_en ? 1'b0 :  (rx_vld & (wr_addr[1:0]==2'b11))     ),
		  .web                 (    1'b0                     ),
		  .dinb                (    32'h0                    )
		  );		

ram u_ram (

         .clka                  (    clk                                 ),
	     .ena                   (    ram_cen & (ram_addr[31:28]==4'h4)   ),
	     .wea                   (    ram_wen ? ram_flag : 4'h0           ),
	     .addra                 (    ram_addr[13:2]                      ),
	     .dina                  (    ram_wdata                           ),
	     
	     .douta                 (    ram_rdata_ram                       )
	);		  
	
rxtx 
# ( .baud ( 115200 ),
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
    rd_sel <= { (ram_addr==32'he0000008),(ram_addr==32'he0000000),(ram_addr[31:28]==4'h0),(ram_addr[31:28]==4'h4) };
else;
	
reg         rec_flag;
reg [7:0]   rec_data;	
always @ (posedge clk or posedge rst )
if ( rst )
    rec_flag <= 1'b0;
else if (~cpu_en)
    rec_flag <= 1'b0;
else if  (rx_vld)
    rec_flag <= 1'b1;
else if (ram_cen & ~ram_wen & (ram_addr==32'he0000008) )
    rec_flag <= 1'b0;
else;

always @ (posedge clk or posedge rst )
if ( rst )
    rec_data <= 8'b0;
else if (cpu_en & rx_vld)
    rec_data <= rx_data;
else; 	
	
always @ ( * )
if (rd_sel[3])
    ram_rdata = rec_data;
else if (rd_sel[2])
    ram_rdata = {rec_flag,(txrdy ? 1'b0:1'b1)};
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

			
