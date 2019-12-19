## Introduction

In this repo are projects from the book *ARM9-compatible CPU soft core design based on FPGA* (《兼容ARM9的软核处理器设计：基于FPGA》[https://baike.baidu.com/item/兼容ARM9的软核处理器设计%EF%BC%9A基于FPGA/1686845?fr=aladdin](https://baike.baidu.com/item/兼容ARM9的软核处理器设计%EF%BC%9A基于FPGA/1686845?fr=aladdin)).



## Contents

Up to now I have successfully replicated all the experiments in this book:

**Chapter 2** Verilog RTL programming

- **Section 2.5** UART serial communication (in folder "[UART_serial_communication](https://github.com/jasha64/ARM9-compatible-soft-CPU-core/tree/master/UART_serial_communication)")

**Chapter 7** Run "Hello World" on ARM9 compatible CPU core

- **Section 7.2** Compile "Hello World" program with RealView MDK-ARM ("[LPC2101_Hello](https://github.com/jasha64/ARM9-compatible-soft-CPU-core/tree/master/LPC2101_Hello)")
- **Section 7.3** Output "Hello World" in simulation ("[ARM9_HelloWorld](https://github.com/jasha64/ARM9-compatible-soft-CPU-core/tree/master/ARM9_HelloWorld)")
- **Section 7.4** "Hello World" project for FPGA ("[ARM9_HelloWorld](https://github.com/jasha64/ARM9-compatible-soft-CPU-core/tree/master/ARM9_HelloWorld)")

**Chapter 8** Dhrystone Benchmark on ARM9 compatible CPU core

- **Section 8.2** Porting Dhrystone 2.1 to FPGA ("[LPC2104_DHRY](https://github.com/jasha64/ARM9-compatible-soft-CPU-core/tree/master/LPC2104_DHRY)")
- **Section 8.3** Dhrystone Benchmark in RTL simulation ("[ARM9_Dhrystone](https://github.com/jasha64/ARM9-compatible-soft-CPU-core/tree/master/ARM9_Dhrystone)")
- **Section 8.5** Dhrystone Benchmark on FPGA board ("[ARM9_Dhrystone](https://github.com/jasha64/ARM9-compatible-soft-CPU-core/tree/master/ARM9_Dhrystone)")

**Chapter 9** uClinux simulation - booting non-MMU OS in reference to SkyEye

- **Section 9.4** SkyEye hardware simulation platform ("[skyeye-testsuite-1.2.5](https://github.com/jasha64/ARM9-compatible-soft-CPU-core/tree/master/skyeye-testsuite-1.2.5)")
- **Section 9.5** Boot uClinux in RTL simulation ("[ARM9_uClinux_simulation](https://github.com/jasha64/ARM9-compatible-soft-CPU-core/tree/master/ARM9_uClinux_simulation)")

**Chapter 10** Linux simulation - booting OS with MMU in reference to FriendlyARM Mini2440 board

- **Section 10.6** Boot Linux in simulation ("[ARM9_mini2440_Linux_simulation](https://github.com/jasha64/ARM9-compatible-soft-CPU-core/tree/master/ARM9_mini2440_Linux_simulation)")



... and is currently working on **Chapter 6** Verilog RTL design of ARM9 compatible CPU core.

My report [report.pdf](https://github.com/jasha64/ARM9-compatible-soft-CPU-core/blob/master/report.pdf) consists of two parts: summary of book content; my experimental results.



## Note

- **xpr** projects are to open with Vivado 2015.4 and its simulator, except that "[ARM9_mini2440_Linux_simulation](https://github.com/jasha64/ARM9-compatible-soft-CPU-core/tree/master/ARM9_mini2440_Linux_simulation)" requires Modelsim 10.6 (it fails on Vivado 2015 simulator); **uvproj** projects are to open with μVision>=4, and the "**skyeye**" stuff is to run in SkyEye under Ubuntu. My operating system is Windows 10, and my FPGA board is Digilent Nexys4 DDR.
- The majority of code are downloaded from https://code.google.com/archive/p/risclite/ and https://code.google.com/archive/p/arm-cpu-core/, which are provided by book author; however, those projects are based on obsolete platforms such as Xilinx ISE, and I spent effort to make them runnable on Vivado on Windows 10.
- This repo requires Git LFS (large file support)

