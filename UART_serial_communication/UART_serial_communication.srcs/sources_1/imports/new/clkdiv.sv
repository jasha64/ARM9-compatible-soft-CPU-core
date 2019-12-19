module clkdiv(
    input logic mclk, //100MHz
    input logic rst,
    
    output logic clka //25MHz
);
    logic[1:0] q;
    always_ff @ (posedge mclk) //只有上升沿计数，则计数器产生上升沿下降沿的频率只有实际时钟的一半
        if (rst == 1) q <= 2'b0;
        else q <= q + 1'b1;
    assign clka = q[1];
endmodule
