`timescale 1 ns/1 ns
`define DEL 2
module nand_flash(
    clk,
	rst,
	nf_read,
	nf_write,
	nf_ben,
	nf_num,
	nf_wdata,
	
	nf_rdata
);

input          clk;
input          rst;
input          nf_read;
input          nf_write;
input  [3:0]   nf_ben;
input  [7:0]   nf_num;
input  [31:0]  nf_wdata;

output [31:0]  nf_rdata;
reg    [31:0]  nf_rdata;

/****************************************************/

reg [31:0] nfconf;
reg [7:0]  nfcont;
reg [7:0]  nfstas;

always @ (posedge clk or posedge rst)
if (rst)
    nfconf <= #`DEL 32'h862e;
else if (nf_write&(nf_num==8'h00))
    nfconf <= #`DEL nf_wdata;
else;

always @ (posedge clk or posedge rst)
if (rst)
    nfcont <= #`DEL 8'h1;
else if (nf_write & (nf_num==8'h4))
    nfcont <= #`DEL nf_wdata;
else if (nfcont[4])
    nfcont[4] <= #`DEL 1'b0;
else;

always @ (posedge clk or posedge rst)
if (rst)
    nfstas <= #`DEL 32'h85;
else if (nf_write & (nf_num==8'h20)) begin
    nfstas <= #`DEL nf_wdata;
	end
else
    nfstas <= #`DEL 32'h85;

/****************************************************/

reg prcmmd_flag;
reg praddr_flag;
reg [2:0] prcnt;
reg [7:0] prdata;

always @ (posedge clk or posedge rst)
if (rst)
    prcmmd_flag <= #`DEL 1'b0;
else if (nf_write)
    prcmmd_flag <= #`DEL (nf_num==8'h08)&(nf_wdata[7:0]==8'h90);
else;

always @ (posedge clk or posedge rst)
if (rst)
    praddr_flag <= #`DEL 1'b0;
else if (prcmmd_flag&nf_write&(nf_num==8'hc)&(nf_wdata[7:0]==8'h00))
    praddr_flag <= #`DEL 1'b1;	
else if (nf_write)
    praddr_flag <= #`DEL 1'b0;	
else;

always @ (posedge clk or posedge rst)
if (rst)
    prcnt <= #`DEL 3'h0;
else if (praddr_flag)
    if (nf_read&(nf_num==8'h10))
	    prcnt <= #`DEL prcnt + 1'b1;
	else;
else
    prcnt <= #`DEL 3'h0;

always @ (*)
case(prcnt)
3'h0: prdata = 8'hec;
3'h1: prdata = 8'hda;
3'h2: prdata = 8'h10;
3'h3: prdata = 8'h95;
3'h4: prdata = 8'h44;
default: prdata = 8'h00;
endcase

/*
always @ (posedge clk)
if (prcmmd_flag&nf_write&(nf_num==8'hc)&(nf_wdata[7:0]==8'h00))
    $display("%d:Read NAND flash ID process",$time);
else;

always @ (posedge clk)
if (nf_write&(nf_num==8'h08)&(nf_wdata[7:0]==8'h00))
    $display("%d:Read address write process",$time);
else if (nf_write&(nf_num==8'h08)&(nf_wdata[7:0]==8'h30))
	$display("%d:Read address=%h,spare_flag=%h",$time,rdaddr,spare_flag);
else;
//*/

reg rdcmd_flag;
always @ (posedge clk or posedge rst)
if (rst)
    rdcmd_flag <= #`DEL 1'b0;
else if (nf_write&(nf_num==8'h08)&(nf_wdata[7:0]==8'h00))
    rdcmd_flag <= #`DEL 1'b1;
else if (nf_write&(nf_num==8'h08)&(nf_wdata[7:0]==8'h30))
    rdcmd_flag <= #`DEL 1'b0;
else;

reg [2:0] rdcnt;
always @ (posedge clk or posedge rst)
if (rst)
    rdcnt <= #`DEL 3'd0;
else if (rdcmd_flag)
    if (nf_write&(nf_num==8'h0c))
	    rdcnt <= #`DEL rdcnt + 1'b1;
	else;
else
    rdcnt <= #`DEL 3'd0;
	

reg [27:0] rdaddr;
always @ (posedge clk or posedge rst)
if (rst)
    rdaddr <= #`DEL 29'h0;
else if (rdcmd_flag)
    if (nf_write&(nf_num==8'h0c))
        case(rdcnt)
        3'h0: rdaddr[7:0] <= #`DEL nf_wdata[7:0];
        3'h1: rdaddr[10:8] <= #`DEL nf_wdata[2:0];
        3'h2: rdaddr[18:11] <= #`DEL nf_wdata[7:0];
        3'h3: rdaddr[26:19] <= #`DEL nf_wdata[7:0];
        3'h4: rdaddr[27] <= #`DEL nf_wdata[0];
        default: ;
		endcase
    else;
else if (nf_read&(nf_num==8'h10))
    rdaddr <= #`DEL rdaddr + nf_ben[3]+nf_ben[2]+nf_ben[1]+nf_ben[0];
else;

reg spare_flag;
always @ (posedge clk or posedge rst)
if (rst)
    spare_flag <= #`DEL 1'b0;
else if (rdcmd_flag)
    if (nf_write&(nf_num==8'h0c))
	    if (rdcnt==3'h1)
		    spare_flag <= #`DEL nf_wdata[3];
		else;
	else;
else;

reg [7:0] flash [276824063:0];

integer fd;
integer fx;
initial begin
   fd = $fopen("../Obj/1.bin","rb");
//$readmemh("dhry.bin", rom_contain);
   fx = $fread(flash,fd);//,0,276824063);
   $fclose(fd);
end

wire [28:0] addr;
assign addr = spare_flag ? (rdaddr[27:11]*12'h840+12'h800+{rdaddr[10:9],rdaddr[3:0]} )  : (rdaddr[27:11]*12'h840+rdaddr[10:0]);
	
wire [31:0] rd_data;
assign rd_data = {flash[addr+3],flash[addr+2],flash[addr+1],flash[addr]};	


/****************************************************/

reg cmd70_read;
always @ (posedge clk or posedge rst)
if (rst)
    cmd70_read <= #`DEL 1'b0;
else
    cmd70_read <= #`DEL nf_read&((nf_num==8'h10));

reg cmd70_flag;
always @ (posedge clk or posedge rst)
if (rst)
    cmd70_flag <= #`DEL 1'b0;
else if (nf_write&(nf_num==8'h08)&(nf_wdata[7:0]==8'h70))
    cmd70_flag <= #`DEL 1'b1;
else if (cmd70_read)
    cmd70_flag <= #`DEL 1'b0;
else;

always @ (*)
if (cmd70_flag)
    if (nf_num==8'h20)
	    nf_rdata = 32'h85;
	else
        nf_rdata = 32'hc0;
else case(nf_num)
8'h00: nf_rdata= nfconf;
8'h04: nf_rdata= nfcont;
8'h20: nf_rdata= nfstas;
default: nf_rdata = praddr_flag ? prdata : rd_data;
endcase



endmodule
