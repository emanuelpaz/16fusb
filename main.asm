;**********************************************************************
;   16FUSB - USB 1.1 implemetation for PIC16F628/628A                 *
;                                                                     *
;   Copyright (C) 2011  Emanuel Paz <efspaz@gmail.com>                *
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
;    Files required: header.inc                                       *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Notes: This file contains the code of the main loop of the       *
;           the firmware. Main  loop  is  liable  for  check  the     *
;           ACTION_FLAG and, based in it's value, take the flow to    *                                                                   *
;           correct point. The main loop is also the glue between     *
;           core and the custom code.                                 *
;                                                                     *
;**********************************************************************

    __config 0x3F0A
    include     "header.inc"

    global      SetFreeAndReturn, SetReadyAndReturn, ComposeNullAndReturn

    extern      GetDescriptor, GetStatus, GetConfiguration, GetInterface, SetAddress
    extern      VendorRequest, ProcessOut
    extern      DoCrc, InsertStuff, PreInitTXBuffer

RESET_VECTOR    CODE    0x0000
    goto    Start
    nop
    nop
    nop

MAIN_PROG        CODE
; ---------------- Initial Setup (Start) ----------------
Start:
    ;Enable only RB0 int
    movlw   B'00010000'
    movwf   INTCON

    bcf     STATUS,IRP

    ;Adjust RB0 edge (on rise), disable pull-up resistors
    ;and make Prescaler 1:4
    bsf     STATUS,RP0
    bcf     STATUS,RP1
    movlw   B'11000001'
    movwf   OPTION_REG

    ;Disable USART (because we use RB1 for I/O)
    bcf     STATUS,RP0
    bcf     RCSTA,SPEN

    ;Clear Registers
    clrf    RX_BUFFER
    clrf    ADDITIONAL_BITS
    clrf    FRAME_NUMBER
    clrf    PENDING_BYTES

    ;Initial Device Addres (0 NRZI coded)
    movlw   NRZIINITIALADDR
    movwf   DEVICE_ADDRESS
    movwf   NEW_DEVICE_ADDRESS

    ;Set ActionFlag Free
    movlw   AF_FREE
    movwf   ACTION_FLAG

    ;Put on FSR the initial point of the RX_BUFFER
    movlw   RX_BUFFER
    movwf   FSR

    include "setup.inc"

    ;Make RB0, RB1 and RB2 input
    bsf     STATUS,RP0
    movlw   B'00000111'
    iorwf   TRISB,F
    bcf     STATUS,RP0

    ;Enable Interrupts
    bsf     INTCON,GIE
; ---------------- Initial Setup (End) ----------------

MainLoop:
    movlw   AF_PROC_SETUP
    subwf   ACTION_FLAG,W           ;Checks for PROC_SETUP
    btfsc   STATUS,Z
    call    ProcessSetup
    
    movlw   AF_PROC_OUT
    subwf   ACTION_FLAG,W           ;Checks for PROC_OUT
    btfsc   STATUS,Z
    call    ProcessOut   
    
    btfss   PORTB,2                 ;Checks for Reset
    call    CheckReset

    include "action.inc"

    goto    MainLoop

ProcessSetup:
    movlw   0xFF                    ;Initialize crc values
    movwf   crcLo
    movwf   crcHi

    movlw   0x060
    andwf   RXDATA_BUFFER,W
    btfss   STATUS,Z
    goto    VendorRequest           ;Jump if it's a vendor request

    ;Checks the Type
    btfss   RXDATA_BUFFER,7
    goto    HostToDevice

;Standard requests
DeviceToHost:
    movf    RXDATA_BUFFER+1,W
    sublw   0x06
    btfsc   STATUS,Z                ;Checks for GET_DESCRIPTOR request
    goto    GetDescriptor

    movf    RXDATA_BUFFER+1,F
    btfsc   STATUS,Z
    goto    GetStatus               ;Checks for GET_STATUS request

    movf    RXDATA_BUFFER+1,W
    sublw   0x08
    btfsc   STATUS,Z                ;Checks for GET_CONFIGURATION request
    goto    GetConfiguration

    movf    RXDATA_BUFFER+1,W
    sublw   0x0A
    btfsc   STATUS,Z                ;Checks for GET_INTERFACE request
    goto    GetInterface

    goto    SetFreeAndReturn        ;If not recognized, set it free and return

HostToDevice:
    movf    RXDATA_BUFFER+1,W
    sublw   0x05
    btfsc   STATUS,Z                ;Checks for SET_ADDRESS request
    goto    SetAddress

    movf    RXDATA_BUFFER+1,W
    sublw   0x09
    btfsc   STATUS,Z                ;Checks for SET_CONFIGURATION request
    goto    ComposeNullAndReturn

    goto    SetFreeAndReturn        ;If not recognized, set it free and return

;Prepare buffer with zero length data packet
ComposeNullAndReturn:
    movlw   DATA1PID                ;DATA1 PID
    movwf   TX_BUFFER

    movlw   0x00                    ;CRC16
    movwf   TX_BUFFER+1
    movwf   TX_BUFFER+2

    movlw   D'3'
    movwf   TX_LEN

    clrf    ADDITIONAL_BITS
    bcf     PENDING_BYTES,0

SetReadyAndReturn:
    movlw   AF_TX_BUFF_READY
    movwf   ACTION_FLAG
    return

SetFreeAndReturn:
    movlw   AF_FREE
    movwf   ACTION_FLAG
    return
        
CheckReset:
    movlw   0x3                     ;For 15 instructions (2.5us)
    movwf   COUNT
CR_Loop:
    btfsc   PORTB,2
    return
    decfsz  COUNT,F
    goto    CR_Loop    
ResetDevice:                        ;SE0 for more than 2.5us, host is sending a reset
    movlw   NRZIINITIALADDR         ;Initial Device Addres (0 NRZI coded)
    movwf   DEVICE_ADDRESS
    movwf   NEW_DEVICE_ADDRESS
    return   
    
    END
