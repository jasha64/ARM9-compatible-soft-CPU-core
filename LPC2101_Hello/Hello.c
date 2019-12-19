/******************************************************************************/
/* HELLO.C: Hello World Example                                               */
/******************************************************************************/
/* This file is part of the uVision/ARM development tools.                    */
/* Copyright (c) 2005-2006 Keil Software. All rights reserved.                */
/* This software may only be used under the terms of a valid, current,        */
/* end user licence from KEIL for a compatible version of KEIL software       */
/* development tools. Nothing else gives you the right to use this software.  */
/******************************************************************************/

#include <stdio.h>                /* prototype declarations for I/O functions */
#include <LPC21xx.H>              /* LPC21xx definitions                      */

__irq void IRQ_Handler(void) {
	printf("There is an IRQ!\n");
}
/****************/
/* main program */
/****************/
int main (void)  {                /* execution starts here                    */

	/* initialize the serial interface */
  /* 5 lines omitted - unnecessary for FPGA runs. */
	
	//int i;
	//for (i = 0; i < 10; i++) printf ("Hello World! This is the %d time!\n", i);       /* the 'printf' function call               */

  while (1) {                          /* An embedded program does not stop and       */
    printf ("Hello World!\n");  /* ... */                       /* never returns. We use an endless loop.      */
  }                                    /* Replace the dots (...) with your own code.  */

}
