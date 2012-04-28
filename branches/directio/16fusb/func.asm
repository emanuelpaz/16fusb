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
;    Filename:        func.asm                                        *
;    Date:                                                            *
;    Author:          Emanuel Paz                                     *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Notes: This file contais general functions used by isr and       *
;           main code.                                                *
;                                                                     *
;**********************************************************************


    #include    "def.inc"

    ;From ISR_SHARED_INTERFACE (isr.asm) ------------------------------
    extern      ADDITIONAL_BITS, PENDING_BYTES, TX_LEN

    ;From ISR_VARIABLES (isr.asm) -------------------------------------
    extern      TX_BUFFER

    ;From MAIN_SHARED_INTERFACE (main.asm )----------------------------
    extern      TOTAL_LEN


LOCAL_OVERLAY           UDATA_OVR   0x4F

TMP                     RES     D'1'    ;Temporary file
GEN                     RES     D'1'    ;General purpose file
GEN2                    RES     D'1'    ;General purpose file
COUNT                   RES     D'1'    ;Counter file level one
COUNT2                  RES     D'1'    ;Counter file level two
SEEK                    RES     D'1'    ;Index file level one
NCHANGE_COUNT           RES     D'1'    ;Number of no change level in NRZI (bit stuffing)

    global      DoCrc, InsertStuff, PreInitTXBuffer



FUNCTIONS    CODE

;***************************************************
;Calculate CRC based on parameters:
; TX_LEN must be already adjusted
DoCrc:
    movf    TX_LEN,W
    movwf   COUNT

    movlw   TX_BUFFER+1             ;Initial Address of data
    movwf   FSR
    
    ;Initialize crc values
    movlw   0xFF                   
    movwf   GEN                     ;Low byte of CRC
    movwf   GEN2                    ;High byte of CRC

DoCrc_:
    movf    INDF,W
    call    CRC16
    incf    FSR,F
    decfsz  COUNT,F
    goto    DoCrc_

    comf    GEN,F
    movf    GEN,W
    movwf   INDF

    incf    FSR,F
    comf    GEN2,F
    movf    GEN2,W
    movwf   INDF
    return

CRC16:
    xorwf   GEN,F
    movlw   0x08
    movwf   SEEK
CRC16_nextbit:
    rrf     GEN2,F
    bcf     GEN2,7
    rrf     GEN,F
    btfss   STATUS,C
    goto    CRC16_noxor
    movlw   con_a0
    xorwf   GEN2,F
    movlw   con_01
    xorwf   GEN,F
CRC16_noxor:
    decfsz  SEEK,F
    goto    CRC16_nextbit
    return

;***************************************************
;Insert bitstuffing in TX_BUFFER
; TX_LEN must be already adjusted
InsertStuff:
    clrf    ADDITIONAL_BITS
    movlw   TX_BUFFER
    movwf   FSR

    movlw   0x04
    movwf   NCHANGE_COUNT

    movf    TX_LEN,W
    addlw   0x03                    ;PID + CRC16 (3 bytes)
    movwf   COUNT

IS_Byte:                            ;controlled by COUNT
    movf    INDF,W
    movwf   GEN

    movlw   0x08
    movwf   COUNT2
IS_Bit:                             ;controlled by COUNT2
    movlw   0x01
    andwf   GEN,W
    sublw   0x01
    btfss   STATUS,Z
    goto    $+3
    decf    NCHANGE_COUNT,F
    goto    $+3
    movlw   0x06
    movwf   NCHANGE_COUNT

    rrf     GEN,F
    clrw
    subwf   NCHANGE_COUNT,W
    btfsc   STATUS,Z
    call    ShiftBuffer
    decfsz  COUNT2,F
    goto    IS_Bit

    incf    FSR,F
    decfsz  COUNT,F
    goto    IS_Byte
    return

ShiftBuffer:
    incf    ADDITIONAL_BITS,F
    movf    COUNT,W
    movwf   SEEK
    incf    SEEK,F

    movf    FSR,W
    movwf   TMP                     ;Save current address on TMP

    movf    INDF,W
    movwf   GEN2                    ;Save current value on GEN2

SB_ShiftByte:
    rlf     INDF,F
    incf    FSR,F
    decfsz  SEEK,F
    goto    SB_ShiftByte

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
    goto    SB_Clr1

    bcf     INDF,1
    btfsc   GEN2,1
    bsf     INDF,1
    decfsz  TMP,F
    goto    $+2
    goto    SB_Clr2

    bcf     INDF,2
    btfsc   GEN2,2
    bsf     INDF,2
    decfsz  TMP,F
    goto    $+2
    goto    SB_Clr3

    bcf     INDF,3
    btfsc   GEN2,3
    bsf     INDF,3
    decfsz  TMP,F
    goto    $+2
    goto    SB_Clr4

    bcf     INDF,4
    btfsc   GEN2,4
    bsf     INDF,4
    decfsz  TMP,F
    goto    $+2
    goto    SB_Clr5

    bcf     INDF,5
    btfsc   GEN2,5
    bsf     INDF,5
    decfsz  TMP,F
    goto    $+2
    goto    SB_Clr6

    bcf     INDF,6
    btfsc   GEN2,6
    bsf     INDF,6
    decfsz  TMP,F
    goto    $+2
    goto    SB_Clr7

    bcf     INDF,7
    btfsc   GEN2,7
    bsf     INDF,7
    decfsz  TMP,F
    goto    $+2
    goto    SB_Clr8

SB_Clr1:
    bcf     INDF,1
    goto    SB_Done
SB_Clr2:
    bcf     INDF,2
    goto    SB_Done
SB_Clr3:
    bcf     INDF,3
    goto    SB_Done
SB_Clr4:
    bcf     INDF,4
    goto    SB_Done
SB_Clr5:
    bcf     INDF,5
    goto    SB_Done
SB_Clr6:
    bcf     INDF,6
    goto    SB_Done
SB_Clr7:
    bcf     INDF,7
    goto    SB_Done
SB_Clr8:
    incf    FSR,F
    bcf     INDF,0
    decf    FSR,F

SB_Done:
    movlw   0x06
    movwf   NCHANGE_COUNT

    movlw   0x01
    subwf   COUNT2,W
    btfss   STATUS,Z
    decf    COUNT2,F
    return

;***********************************************************
;Adjust Data toggle, TX_LEN and PENDING_BYTES based on
;TOTAL_LEN value (initially, wLength value).
PreInitTXBuffer:
    movlw   0x08
    subwf   TOTAL_LEN,W
    btfss   STATUS,C
    goto    PITB_LessEight
    
    ;TOTAL_LEN >=8    
    movwf   TOTAL_LEN               ;TOTAL_LEN = TOTAL_LEN - 8
    movlw   0x08                    ;8 DATA bytes
    movwf   TX_LEN                  ;Number of total bytes to send
    btfsc   STATUS,Z
    goto    PITB_ClearPending       ;TOTAL_LEN = 8
    bsf     PENDING_BYTES,0         ;TOTAL_LEN > 8
    goto    PITB_DataToggle
        
PITB_LessEight:
    ;TOTAL_LEN < 8
    movf    TOTAL_LEN,W
    movwf   TX_LEN                  ;Number of total bytes to send

PITB_ClearPending:
    bcf     PENDING_BYTES,0    

PITB_DataToggle:    
    ;Data toggle
    movlw   DATA0PID
    btfss   TX_BUFFER,3
    movlw   DATA1PID
    movwf   TX_BUFFER

    return

    END