/******************************************************************************/
/* SERIAL.C: Low Level Serial Routines                                        */
/******************************************************************************/
/* This file is part of the uVision/ARM development tools.                    */
/* Copyright (c) 2005-2006 Keil Software. All rights reserved.                */
/* This software may only be used under the terms of a valid, current,        */
/* end user licence from KEIL for a compatible version of KEIL software       */
/* development tools. Nothing else gives you the right to use this software.  */
/******************************************************************************/

#include <LPC21xx.H>                     /* LPC21xx definitions               */

#define CR     0x0D

/* registers for user-defined behavior rule */
#define SERIAL_FLAG *(volatile unsigned char *) 0xe0000000
#define SERIAL_OUT *(volatile unsigned char *) 0xe0000004
#define SERIAL_IN *(volatile unsigned char *) 0xe0000008

/* implementation of putchar (also used by printf function to output data)    */
int sendchar (int ch)  {                 /* Write character to Serial Port    */

  if (ch == '\n')  {
    while (SERIAL_FLAG & 0x01);
    SERIAL_OUT = CR;                          /* output CR */
  }
  while (SERIAL_FLAG & 0x01);
  return (SERIAL_OUT = ch);
}


int getkey (void)  {                     /* Read character from Serial Port   */

  while (!(SERIAL_FLAG & 0x02));

  return (SERIAL_IN);
}
