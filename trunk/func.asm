;**********************************************************************
;   16FUSB - USB 1.1 implemetation for PIC16F628/648                  *
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
;    Filename:        func.asm                                        *
;    Date:                                                            *
;    Author:          Emanuel Paz                                     *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Files required: header.inc                                       *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Notes: This file contais general functions used by isr and       *
;           main code.                                                *
;                                                                     *
;**********************************************************************


    include     "header.inc"

    global      DoCrc, InsertStuff, PreInitTXBuffer

FUNCTIONS    CODE

;***************************************************
;Calculate CRC based on parameters:
;  COUNT: size of data
;  FSR: address of first byte (payload) on data buffer
DoCrc:
    movf    INDF,W
    call    CRC16
    incf    FSR,F
    decfsz  COUNT,F
    goto    DoCrc

    comf    crcLo,F
    movf    crcLo,W
    movwf   INDF

    incf    FSR,F
    comf    crcHi,F
    movf    crcHi,W
    movwf   INDF
    return

CRC16:
    xorwf   crcLo,F
    movlw   0x08
    movwf   SEEK1
CRC16_nextbit:
    rrf     crcHi,F
    bcf     crcHi,7
    rrf     crcLo,F
    btfss   STATUS,C
    goto    CRC16_noxor
    movlw   con_a0
    xorwf   crcHi,F
    movlw   con_01
    xorwf   crcLo,F
CRC16_noxor:
    decfsz  SEEK1,F
    goto    CRC16_nextbit
    return
;***************************************************


;***************************************************
;Insert bitstuffing in TX_BUFFER
;  TX_LEN must be already adjusted
InsertStuff:
    clrf    ADDITIONAL_BITS
    movlw   TX_BUFFER
    movwf   FSR

    movlw   0x04
    movwf   NCHANGE_COUNT

    movf    TX_LEN,W
    movwf   COUNT

Ins_Stuff_Byte:                     ;controlled by COUNT
    movf    INDF,W
    movwf   GEN1

    movlw   0x08
    movwf   COUNT2
Ins_Stuff_Bit:                      ;controlled by COUNT2
    movlw   0x01
    andwf   GEN1,W
    sublw   0x01
    btfss   STATUS,Z
    goto    $+3
    decf    NCHANGE_COUNT,F
    goto    $+3
    movlw   0x06
    movwf   NCHANGE_COUNT

    rrf     GEN1,F
    clrw
    subwf   NCHANGE_COUNT,W
    btfsc   STATUS,Z
    call    ShiftBuffer
    decfsz  COUNT2,F
    goto    Ins_Stuff_Bit

    incf    FSR,F
    decfsz  COUNT,F
    goto    Ins_Stuff_Byte
    return

ShiftBuffer:
    incf    ADDITIONAL_BITS,F
    movf    COUNT,W
    movwf   SEEK1
    incf    SEEK1,F

    movf    FSR,W
    movwf   TMP                     ;Save current address on TMP

    movf    INDF,W
    movwf   GEN2                    ;Save current value on GEN2

SBuff_ShiftByte:
    rlf     INDF,F
    incf    FSR,F
    decfsz  SEEK1,F
    goto    SBuff_ShiftByte

    movf    TMP,W
    movwf   FSR                     ;Restore FSR

    movlw   0x09
    movwf   TMP
    movf    COUNT2,W
    subwf   TMP,F                   ;Number of bits to restore

    bcf     INDF,0
    btfsc   GEN2,0
    bsf     INDF,0
    decfsz  TMP,F
    goto    $+2
    goto    SBuff_Clr1

    bcf     INDF,1
    btfsc   GEN2,1
    bsf     INDF,1
    decfsz  TMP,F
    goto    $+2
    goto    SBuff_Clr2

    bcf     INDF,2
    btfsc   GEN2,2
    bsf     INDF,2
    decfsz  TMP,F
    goto    $+2
    goto    SBuff_Clr3

    bcf     INDF,3
    btfsc   GEN2,3
    bsf     INDF,3
    decfsz  TMP,F
    goto    $+2
    goto    SBuff_Clr4

    bcf     INDF,4
    btfsc   GEN2,4
    bsf     INDF,4
    decfsz  TMP,F
    goto    $+2
    goto    SBuff_Clr5

    bcf     INDF,5
    btfsc   GEN2,5
    bsf     INDF,5
    decfsz  TMP,F
    goto    $+2
    goto    SBuff_Clr6

    bcf     INDF,6
    btfsc   GEN2,6
    bsf     INDF,6
    decfsz  TMP,F
    goto    $+2
    goto    SBuff_Clr7

    bcf     INDF,7
    btfsc   GEN2,7
    bsf     INDF,7
    decfsz  TMP,F
    goto    $+2
    goto    SBuff_Clr8

SBuff_Clr1:
    bcf     INDF,1
    goto    SBuff_Done
SBuff_Clr2:
    bcf     INDF,2
    goto    SBuff_Done
SBuff_Clr3:
    bcf     INDF,3
    goto    SBuff_Done
SBuff_Clr4:
    bcf     INDF,4
    goto    SBuff_Done
SBuff_Clr5:
    bcf     INDF,5
    goto    SBuff_Done
SBuff_Clr6:
    bcf     INDF,6
    goto    SBuff_Done
SBuff_Clr7:
    bcf     INDF,7
    goto    SBuff_Done
SBuff_Clr8:
    incf    FSR,F
    bcf     INDF,0
    decf    FSR,F

SBuff_Done:
    movlw   0x06
    movwf   NCHANGE_COUNT

    movlw   0x01
    subwf   COUNT2,W
    btfss   STATUS,Z
    decf    COUNT2,F
    return
;***************************************************


;**************************************************************************
;Adjust Data toggle, TX_LEN, COUNT(for CRC calc), PENDING_BYTES
;and FRAME_NUMBER based on TOTAL_LEN value (initially, wLength value).
PreInitTXBuffer:
    movlw   0x08
    subwf   TOTAL_LEN,W
    btfss   STATUS,C
    goto    $+D'11'
    
    ;TOTAL_LEN >=8    
    movwf   TOTAL_LEN               ;TOTAL_LEN = TOTAL_LEN - 8
    movlw   D'11'                   ;PID + 8 DATA bytes + CRC16 (11 bytes)
    movwf   TX_LEN                  ;Number of total bytes to send
    movlw   0x08                    ;8 DATA bytes
    movwf   COUNT                   ;Size of payload data for CRC calc
    btfsc   STATUS,Z
    goto    $+8                     ;TOTAL_LEN = 8
    bsf     PENDING_BYTES,0         ;TOTAL_LEN > 8
    incf    FRAME_NUMBER,F
    goto    $+6
        
    ;TOTAL_LEN < 8
    movf    TOTAL_LEN,W             
    movwf   COUNT                   ;Size of payload data for CRC calc
    addlw   0x03                    ;PID + CRC16 (3 bytes)
    movwf   TX_LEN                  ;Number of total bytes to send
    
    bcf     PENDING_BYTES,0    
    
    ;Data toggle
    movlw   DATA0PID
    btfss   TX_BUFFER,3
    movlw   DATA1PID
    movwf   TX_BUFFER
    
    return
;**************************************************************************

    END