/******************************************************************************/
/* TIME.C: Time Functions for 100Hz Clock Tick                                */
/******************************************************************************/
/* This file is part of the uVision/ARM development tools.                    */
/* Copyright (c) 2005-2006 Keil Software. All rights reserved.                */
/* This software may only be used under the terms of a valid, current,        */
/* end user licence from KEIL for a compatible version of KEIL software       */
/* development tools. Nothing else gives you the right to use this software.  */
/******************************************************************************/

//#include <91M40800.H>                      /* AT91M40800 definitions        */
/* Registers are user-defined in ARM9 compatible code, so no need to include. */

long timeval = 0;

/* Timer Counter 0 Interrupt executes each 10ms @ 40 MHz Crystal Clock        */
__irq void IRQ_Handler (void) {
  timeval++;
  //AIC_EOICR = TC0_SR;                          /* end interrupt               */
}

/* Setup the Timer Counter 0 Interrupt */
/* omitted - unnecessary for RTL simulation */
//void init_time (void)  {

//  TC0_CMR  = TC_CAPT|TC_CPCTRG|TC_CLKS_MCK8;   /* set timer mode           */
//  TC0_RC   = 50000 - 1;                        /* set timer period            */
//  TC0_IER  = TC_CPCS;                          /* enable RC compare interrupt */
//  AIC_SVR4 = (unsigned long)tc0;               /* set interrupt vector        */
//  AIC_SMR4 = AIC_SRCTYPE_INT_EDGE_TRIGGERED;   /* edge triggered interrupt    */
//  AIC_IECR = (1<<TC0_ID);                      /* enable interrupt            */

//  TC0_CCR  = TC_CLKEN | TC_SWTRG;              /* enable and start timer      */
//}
