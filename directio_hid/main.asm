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

    UDATA   0xA0

LAST_KEY_STATE      RES     D'1'



MAIN    CODE

;***************************************************************
; Anything to do after the processor reset and before accepting 
; interrupts goes here.
Init:

    ;Custom code goes here

    ;by DirectIO module    
    bcf     T1CON,T1OSCEN
    movlw   B'00000111'
    movwf   CMCON
    clrf    CCP1CON

    bsf     STATUS,RP0
    movlw   0x0F
    andwf   TRISB,F                 ; set RB4-RB7 ouput
    bsf     TRISA,0                 ; set RA0 input
    bcf     STATUS,RP0
    clrf    PORTB

    banksel LAST_KEY_STATE
    movlw   0x01
    movwf   LAST_KEY_STATE

    return

;***************************************************************
; Code that will run in loop, called by MainLoop.
Main:

    ;Custom code goes here

    movlw   0x01
    andwf   PORTA,W
    banksel LAST_KEY_STATE
    xorwf   LAST_KEY_STATE,W
    btfsc   STATUS,Z                ; RA0 state has changed?
    return                          ; No
    
    ; RA0 stage changed, send Input Report with the new state value.
    banksel PORTA
    movlw   0x01
    andwf   PORTA,W
    banksel LAST_KEY_STATE
    movwf   LAST_KEY_STATE

    movf    LAST_KEY_STATE,W
    banksel INT_TX_BUFFER
    movwf   INT_TX_BUFFER+1
    
    movlw   0x01                    ; send one byte.
    movwf   INT_TX_LEN

    call    PrepareIntTxBuffer      ; prepare buffer

    return

    END
	