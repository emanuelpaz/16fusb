;**********************************************************************
;   16FUSB - USB 1.1 implemetation for PIC16F628/628A                 *
;                                                                     *
;   Copyright (C) 2011-2012  Emanuel Paz <efspaz@gmail.com>           *
;                                                                     *
;   This program is free software; you can redistribute it and/or     *
;   modify it under the terms of the GNU General Public License as    *
;   published by the Free Software Foundation; either version 2 of    *
;   the License, or (at your option) any later version.               *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Filename:        out.asm                                         *
;    Date:                                                            *
;    Author:          Emanuel Paz                                     *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Notes: The function ProcessOut in this file can be treated as    *
;           a callback for Out packages sent by host. All data        * 
;           from data stage of a Host-to-Device Control Transfer      *
;           or an Out Interrupt transfer, will be present here.       *
;           Check AF_BIT_INTERRUPT to know if packet is from a        *
;           control(clear) or interrupt(set) transfer.                *
;**********************************************************************

    #include     "def.inc"

    ; Local labels to export
    global  ProcessOut
    
    ; (isr.asm)
    extern  ACTION_FLAG
#if INTERRUPT_IN_ENDPOINT == 1
    extern  INT_TX_BUFFER
    extern  INT_TX_LEN
    ; (usb.asm)
    extern  PrepareIntTxBuffer
#endif

    ; (usb.asm)
    extern  RXDATA_BUFFER
	extern	RXDATA_LEN


LOCAL_OVERLAY   UDATA_OVR   0x4A+(INTERRUPT_IN_ENDPOINT*D'16')+(INTERRUPT_OUT_ENDPOINT*D'14')

    ; Local temporary variables goes here



PROCESS_OUT     CODE

ProcessOut:
    
    ; Custom code goes here
   
    return

    END