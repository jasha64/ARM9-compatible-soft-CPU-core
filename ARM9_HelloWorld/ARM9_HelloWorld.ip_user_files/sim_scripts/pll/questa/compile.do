vlib work
vlib msim

vlib msim/xil_defaultlib

vmap xil_defaultlib msim/xil_defaultlib

vlog -work xil_defaultlib -64 \
"../../../../ARM9_HelloWorld.srcs/sources_1/ip/pll/pll_clk_wiz.v" \
"../../../../ARM9_HelloWorld.srcs/sources_1/ip/pll/pll.v" \


vlog -work xil_defaultlib "glbl.v"

