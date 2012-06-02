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

    ; Local labels to export
    global  DoCrc
    global  InsertStuff
    global  PreInitTXBuffer

    ; (isr.asm)
    extern  ACTION_FLAG
    extern  TX_BUFFER
    extern  TX_LEN
    extern  TX_EXTRA_BITS
#if INTERRUPT_IN_ENDPOINT == 1
    extern  INT_TX_BUFFER
    extern  INT_TX_LEN
    extern  INT_TX_EXTRA_BITS
#endif

    ; (usb.asm)
    extern  CTRL_TOTAL_LEN


LOCAL_OVERLAY   UDATA_OVR   0x4A+(INTERRUPT_IN_ENDPOINT*D'16')+(INTERRUPT_OUT_ENDPOINT*D'14')

TMP                 RES     D'1'    ; Temporary
GEN                 RES     D'1'    ; General
GEN2                RES     D'1'    ; General
COUNT               RES     D'1'    ; Counter level one
COUNT2              RES     D'1'    ; Counter level two
SEEK                RES     D'1'    ; Index level one
NCHANGE_COUNT       RES     D'1'    ; Number of no change level in NRZI (bit stuffing)
EP                  RES     D'1'    ; EP where we inserting bit stuffing


FUNCTIONS   CODE
;***************************************************
; Calculate CRC.
; W must have EP adrress.
; TX_LEN/INT_TX_LEN must be already adjusted.
DoCrc:
#if INTERRUPT_IN_ENDPOINT == 1
    xorlw   0x00
    btfsc   STATUS,Z
    goto    DoCrc_Setup_Transfer
DoCrc_Setup_Int_Transfer:
    movlw   INT_TX_BUFFER+1         ; Initial Address of data
    movwf   FSR
    movf    INT_TX_LEN,W
    goto    DoCrc_Init
#endif
DoCrc_Setup_Transfer:
    movlw   TX_BUFFER+1             ; Initial Address of data
    movwf   FSR
    movf    TX_LEN,W
DoCrc_Init:
    movwf   COUNT
    ;Initialize crc values
    movlw   0xFF                   
    movwf   GEN                     ; Low byte of CRC
    movwf   GEN2                    ; High byte of CRC

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
; Insert bitstuffing in TX_BUFFER.
; W must indicate EP. 0 = EP0, 1 = EP1.
; TX_LEN/INT_TX_LEN must be already adjusted.
InsertStuff:
#if INTERRUPT_IN_ENDPOINT == 1
    movwf   EP
    xorlw   0x00
    btfsc   STATUS,Z
    goto    IS_Setup_Transfer
IS_Setup_Int_Transfer: 
    movlw   INT_TX_BUFFER
    movwf   FSR
    clrf    INT_TX_EXTRA_BITS
    movf    INT_TX_LEN,W    
    goto    IS_Init
#endif
IS_Setup_Transfer:
    movlw   TX_BUFFER
    movwf   FSR
    clrf    TX_EXTRA_BITS
    movf    TX_LEN,W
IS_Init:
    addlw   0x03                    ; PID + CRC16 (3 bytes)
    movwf   COUNT

    movlw   0x04
    movwf   NCHANGE_COUNT

IS_Byte:                            ; controlled by COUNT
    movf    INDF,W
    movwf   GEN

    movlw   0x08
    movwf   COUNT2
IS_Bit:                             ; controlled by COUNT2
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
#if INTERRUPT_IN_ENDPOINT == 0
    incf    TX_EXTRA_BITS,F
#else
    movf    EP,0
    btfss   STATUS,Z
    goto    $+3
    incf    TX_EXTRA_BITS,F
    goto    $+2
    incf    INT_TX_EXTRA_BITS,F
#endif
    movf    COUNT,W
    movwf   SEEK
    incf    SEEK,F

    movf    FSR,W
    movwf   TMP                     ; Save current address on TMP

    movf    INDF,W
    movwf   GEN2                    ; Save current value on GEN2

SB_ShiftByte:
    rlf     INDF,F
    incf    FSR,F
    decfsz  SEEK,F
    goto    SB_ShiftByte

    movf    TMP,W
    movwf   FSR                     ; Restore FSR

    movlw   0x09
    movwf   TMP
    movf    COUNT2,W
    subwf   TMP,F                   ; Number of bits to restore

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
; Adjust Data toggle, TX_LEN and AF_BIT_PEND_BYTES based on
; CTRL_TOTAL_LEN value (initially, wLength value).
PreInitTXBuffer:
    movlw   0x08
    subwf   CTRL_TOTAL_LEN,W
    btfss   STATUS,C
    goto    PITB_LessEight
    
    ; CTRL_TOTAL_LEN >=8    
    movwf   CTRL_TOTAL_LEN          ; CTRL_TOTAL_LEN = CTRL_TOTAL_LEN - 8
    movlw   0x08                    ; 8 DATA bytes
    movwf   TX_LEN                  ; Number of total bytes to send
    btfsc   STATUS,Z
    goto    PITB_ClearPending       ; CTRL_TOTAL_LEN = 8
    bsf     AF_BIT_PEND_BYTES       ; CTRL_TOTAL_LEN > 8
    goto    PITB_DataToggle
        
PITB_LessEight:
    ; CTRL_TOTAL_LEN < 8
    movf    CTRL_TOTAL_LEN,W
    movwf   TX_LEN                  ; Number of total bytes to send

PITB_ClearPending:
    bcf     AF_BIT_PEND_BYTES    

PITB_DataToggle:
    movlw   USB_PID_DATA0
    btfss   TX_BUFFER,3
    movlw   USB_PID_DATA1
    movwf   TX_BUFFER

    return

    END