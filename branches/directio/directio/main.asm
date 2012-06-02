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
;    Filename:        main.asm                                        *
;    Date:                                                            *
;    Author:          Emanuel Paz                                     *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Notes: In this file you can insert initial setup code            *
;           and something to run in loop, called by MainLoop.         *
;                                                                     *
;**********************************************************************

    #include    "def.inc"

    ; Local labels to export
    global  Init
    global  Main

    ; (isr.asm)
    extern  ACTION_FLAG
#if INTERRUPT_IN_ENDPOINT == 1
    extern  INT_TX_BUFFER
    extern  INT_TX_LEN
    ; (usb.asm)
    extern  PrepareIntTxBuffer
#endif


LOCAL_OVERLAY   UDATA_OVR   0x4A+(INTERRUPT_IN_ENDPOINT*D'16')+(INTERRUPT_OUT_ENDPOINT*D'14')

    ; Local temporary variables goes here



MAIN    CODE

;***************************************************************
; Anything to do after the processor reset and before accepting 
; interrupts goes here.
Init:
    ;by DirectIO module    
    bcf     T1CON,T1OSCEN
    movlw   B'00000111'
    movwf   CMCON
    clrf    CCP1CON
    clrf    PORTA
    clrf    PORTB

    return

;***************************************************************
; Code that will run in loop, called by MainLoop.
Main:

    ;Custom code goes here

    return

    END
	