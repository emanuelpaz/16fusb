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
;    Filename:        isr.asm                                         *
;    Date:                                                            *
;    Author:          Emanuel Paz                                     *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Files required: header.inc                                       *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Notes: Unless you know exactly what you doing, do not edit       *
;           this file. Timing is very strict here! This code is       *
;           the interrupt service routine that treats every           *
;           communication started by host with a Sync Pattern         *
;           rising edge on RB0/Int pin.                               *
;                                                                     *
;**********************************************************************


    include     "header.inc"
    
INTERRUPT_VECTOR    CODE    0x0004
; -------------- Sync (start) --------------
    ;Save context first
    movwf   W_TMP
    swapf   STATUS,W
    movwf   STATUS_TMP
    bcf     PORTB,0                     ;prepare latch

WaitForJ:
    nop
    btfsc   PORTB,0
    goto    WaitForJ
WaitForK:
    btfss   PORTB,0
    goto    WaitForK    
    nop
FoundK:
    nop
    btfss   PORTB,0
    goto    WaitForK    
    
    ;Setup RX_BUFFER
    movlw   RX_BUFFER
    movwf   FSR
    clrf    INDF
; -------------- Sync (end) ----------------

    btfsc   PORTB,0
    bsf     INDF,0
    btfss   PORTB,2
    goto    Eop
    
    btfsc   PORTB,0
    bsf     INDF,1
    btfss   PORTB,2
    goto    Eop

    btfsc   PORTB,0
    bsf     INDF,2
    btfss   PORTB,2
    goto    Eop

    btfsc   PORTB,0
    bsf     INDF,3
    btfss   PORTB,2
    goto    Eop
RxLoop:
    btfsc   PORTB,0    
    bsf     INDF,4
    btfss   PORTB,2
    goto    Eop

    btfsc   PORTB,0
    bsf     INDF,5
    btfss   PORTB,2
    goto    Eop

    btfsc   PORTB,0
    bsf     INDF,6
    btfss   PORTB,2
    goto    Eop

    btfsc   PORTB,0
    bsf     INDF,7
    incf    FSR,F
    clrf    INDF
    
    btfsc   PORTB,0
    bsf     INDF,0
    btfss   PORTB,2
    goto    Eop
    
    btfsc   PORTB,0
    bsf     INDF,1
    btfss   PORTB,2
    goto    Eop
    
    btfsc   PORTB,0
    bsf     INDF,2
    btfss   PORTB,2
    goto    Eop

    btfsc   PORTB,0
    bsf     INDF,3
    goto    RxLoop
    
;End of Packet detcted
Eop:
    btfsc   RX_BUFFER,1
    goto    DataPack                ;Jump if it's data packet
    btfss   RX_BUFFER,0
    goto    ReturnFromISR
TokenPack:
    bcf     RX_BUFFER+1,7
    movf    DEVICE_ADDRESS,W
    subwf   RX_BUFFER+1,W
    btfss   STATUS,Z
    goto    DiscardPack             ;address does not match, discard packet
    btfsc   RX_BUFFER,4             ;if it's SETUP/OUT
    goto    HandleSetupOut          ;jump

HandleIn:
    movlw   AF_TX_BUFF_READY
    subwf   ACTION_FLAG,W           ;Check ACTION_FLAG
    btfsc   STATUS,Z
    goto    $+D'4'                  ;Jump if answer is ready
    movlw   NAKPID                  ;Put NAK in TX_BUFFER
    call    SendHandshake           ;Send NAK
    goto    ReturnFromISR           ;And leave interrupt service

    call    SendTXBuffer            ;Send answer in buffer
    movf    NEW_DEVICE_ADDRESS,W
    movwf   DEVICE_ADDRESS          ;Renew device address
    movlw   AF_PROC_SETUP
    btfsc   PENDING_BYTES,0
    goto    $+D'3'                  ;Jump if theres pending bytes

    movlw   AF_FREE                 ;If there are no pending bytes, set it free
    clrf    FRAME_NUMBER

    movwf   ACTION_FLAG             ;Set ACTION_FLAG
    goto    ReturnFromISR

DiscardPack:
    clrf    LAST_TOKEN_PID
    goto    ReturnFromISR

HandleSetupOut:
    movf    RX_BUFFER,W        
    movwf   LAST_TOKEN_PID          ;Save TOKEN PID    
    
ReturnFromISR:
    ;Restore Context
    swapf   STATUS_TMP,W
    movwf   STATUS
    swapf   W_TMP,F
    swapf   W_TMP,W

    bcf     INTCON,INTF
    retfie

DataPack:
    ;if packet was discarded previously, return from ISR
    movf    LAST_TOKEN_PID,F
    btfsc   STATUS,Z
    goto    ReturnFromISR

    ;Set RX_LEN
    movlw   RX_BUFFER
    subwf   FSR,W
    movwf   RX_LEN

    movlw   AF_TX_BUFF_READY
    subwf   ACTION_FLAG,W
    btfss   STATUS,Z
    goto    $+D'3'
    movlw   AF_FREE
    movwf   ACTION_FLAG

    movlw   AF_FREE
    subwf   ACTION_FLAG,W           ;Check ACTION_FLAG
    btfsc   STATUS,Z
    goto    $+D'4'

    movlw   NAKPID
    call    SendHandshake           ;If ACTION_FLAG is NOT FREE, send NAK
    goto    ReturnFromISR
    
    movlw   ACKPID                  ;If it's free...
    call    SendHandshake           ;Send ACK
    
    ;Adjust ACTION_FLAG
    movlw   AF_PROC_OUT
    btfss   LAST_TOKEN_PID,2        ;Data from OUT?
    movlw   AF_PROC_SETUP           ;no, it's from SETUP
    movwf   ACTION_FLAG

;Decode RX_BUFFER to RXDATA_BUFFER
DP_PrepareDecoding:
    movf    RX_LEN,W
    movwf   COUNT
   
    movlw   RX_BUFFER+1             ;Ignore Token PID
    movwf   SEEK1                   ;Source
    clrf    RXDATA_LEN
    movlw   RXDATA_BUFFER
    movwf   SEEK2                   ;Destiny

    movlw   0x01
    movwf   GEN2                    ;Roles as "last nrzi bit"

    movlw   0x06                    ;If DATA1
    btfsc   RX_BUFFER,6   
    movlw   0x04                    ;If DATA0
    movwf   NCHANGE_COUNT
   
    movlw   0x08
    movwf   COUNT3                  ;COUNT3 controls bits in destiny

DP_CopyLoop:                        ;Controlled by COUNT
    movf    SEEK1,W
    movwf   FSR
    movf    INDF,W
    movwf   TMP                     ;Put in TMP the byte to decode
   
    movf    SEEK2,W
    movwf   FSR
   
    movlw   0x08                    ;Decode 8 bits
    movwf   COUNT2

DP_CP_DecodeBit:                    ;Controlled by COUNT2
    movlw   0x01
    andwf   TMP,W
    movwf   GEN1       
    xorwf   GEN2,F
    comf    GEN2,F

    btfss   GEN2,0
    goto    $+D'4'
    decfsz  NCHANGE_COUNT,F
    goto    $+D'4'
    goto    DP_RemoveBitStuff

    movlw   0x06
    movwf   NCHANGE_COUNT   

    rrf     GEN2,F
    rrf     INDF,F
    movf    GEN1,W
    movwf   GEN2

DP_CP_DB_VerifyDestEnd:
    decfsz  COUNT3,F
    goto    DP_CP_DB_VerifyEnd

    incf    RXDATA_LEN,F
    movf    RXDATA_LEN,W
    subwf   RX_LEN,W
    sublw   0x03                    ;Skip PID and CRC16 on decoding (3 bytes) 
    btfsc   STATUS,Z
    goto    DP_CP_End

    incf    SEEK2,F
    movf    SEEK2,W
    movwf   FSR
    movlw   0x08
    movwf   COUNT3

DP_CP_DB_VerifyEnd:
    rrf     TMP,F
    decfsz  COUNT2,F
    goto    DP_CP_DecodeBit
DP_CP_DB_End:
    incf    SEEK1,F
    decfsz  COUNT,F
    goto    DP_CopyLoop
DP_CP_End:
    clrf    FRAME_NUMBER
    movlw   DATA0PID
    movwf   TX_BUFFER
    
    ;Put setup's wLenght in TOTAL_LEN
    movf    RXDATA_BUFFER+6,W
    movwf   TOTAL_LEN
    goto    ReturnFromISR

DP_RemoveBitStuff:
    movlw   0x06
    movwf   NCHANGE_COUNT
   
    rrf     GEN2,F
    rrf     INDF,F

    decfsz  COUNT3,F
    goto    $+D'12'
    incf    RXDATA_LEN,F
    movf    RXDATA_LEN,W
    subwf   RX_LEN,W
    sublw   0x03                    ;Skip PID and CRC16 on decoding (3 bytes)
    btfsc   STATUS,Z
    goto    DP_CP_End
    incf    SEEK2,F
    movf    SEEK2,W
    movwf   FSR
    movlw   0x08
    movwf   COUNT3

    rrf     TMP,F
    movlw   0x01
    andwf   TMP,W
    movwf   GEN2

    decfsz  COUNT2,F
    goto    DP_CP_DB_VerifyEnd
    goto    DP_CP_DB_End

SendTXBuffer:
    ;Set RB0/RB1 Output
    bsf     STATUS,RP0
    movlw   0xFC
    andwf   TRISB,F
    bcf     STATUS,RP0

    movlw   TX_BUFFER
    movwf   FSR    
    movlw   0x07
    movwf   COUNT

    bcf     STATUS,C
    rlf     TX_LEN,F
    rlf     TX_LEN,F
    rlf     TX_LEN,W
    addlw   0x08                    ;8 bits of Sync Pattern            
    addwf   ADDITIONAL_BITS,W
    sublw   0xFF                    ;255 - 8 - (TX_LEN*8) - AdditionalBits    
    movwf   TMR0
                                    
    nop                             ;Stabilize TRM0 value

    ;TMR0 written, two (next) cycles inhibited.
    nop    
    movlw   B'00110000'             ;Enable TIMER0 int

    ;The next four lines takes 1 bit time (-1).
    movwf   INTCON
    movlw   0x03
    nop
    nop                             ;Here, 1 bit time elapsed. TRM0 = 1.

    ;These two 'nops' makes T0IF verification at the last cycle of bit time,
    ;so we can jump to the EOP with only one excessive instruction cycle (166ns)
    ;in most cases. Sometimes trash bits, at the end of the package, 
    ;may occurs (see below).
    nop
    nop

;Send Sync
STXB_SyncLoop:            
    xorwf   PORTB,F
    decfsz  COUNT,F
    goto    STXB_SyncLoop
    call    WaitOneBitTime

    ;Send TX_Buffer (doing NRZI encode)    
    btfss   INDF,0
    xorwf   PORTB,F
    btfsc   INTCON,T0IF
    goto    GenEop
    
    btfss   INDF,1
    xorwf   PORTB,F
    btfsc   INTCON,T0IF
    goto    GenEop

STXB_SendByte:
    btfss   INDF,2
    xorwf   PORTB,F
    btfsc   INTCON,T0IF
    goto    GenEop
    
    btfss   INDF,3
    xorwf   PORTB,F
    btfsc   INTCON,T0IF
    goto    GenEop
    
    btfss   INDF,4
    xorwf   PORTB,F
    btfsc   INTCON,T0IF
    goto    GenEop
    
    btfss   INDF,5
    xorwf   PORTB,F
    btfsc   INTCON,T0IF
    goto    GenEop
    
    btfss   INDF,6
    xorwf   PORTB,F
    btfsc   INTCON,T0IF
    goto    GenEop
    
    ;We can't check for T0IF here because FSR needs to be
    ;incremented to take next bit in buffer. Due this, sometimes,
    ;one trash bit may be present before EOP. In fact, it's not a
    ;problem, because hosts just ignore extra bits in package. ;)
    btfss   INDF,7
    xorwf   PORTB,F
    incf    FSR,F
    nop

    btfss   INDF,0
    xorwf   PORTB,F
    btfsc   INTCON,T0IF
    goto    GenEop
    
    ;Same about trash bit here, but this time due to 'goto STXB_SendByte'.
    btfss   INDF,1
    xorwf   PORTB,F
    goto    STXB_SendByte

GenEop:
    movlw   0xFC
GenEop_01:
    andwf   PORTB,F
    bcf     INTCON,T0IE             ;Disable TIMER0 int
    goto    GenEop_02
GenEop_02:
    movlw   0x02
    nop
    nop
    nop
    xorwf   PORTB,F

    ;Set RB0/RB1 Input
    bsf     STATUS,RP0
    movlw   0x03
    iorwf   TRISB,F
    bcf     STATUS,RP0
    return

SendHandshake:
    movwf   TMP                     ;Save W (PID to send) in TMP
    movlw   TX_BUFFER
    movwf   FSR
    
    movf    TMP,W
    movwf   INDF

    ;Set RB0/RB1 Output
    bsf     STATUS,RP0
    movlw   0xFC
    andwf   TRISB,F
    bcf     STATUS,RP0              ;Back to bank 0

    movlw   0x07
    movwf   COUNT
    movlw   0x03
    
SH_SyncLoop:                        ;Send Sync    
    xorwf   PORTB,F
    decfsz  COUNT,F
    goto    SH_SyncLoop
    call    WaitOneBitTime

    ;Send HandShake PID
    btfss   INDF,0
    xorwf   PORTB,F
    nop
    nop
    
    btfss   INDF,1
    xorwf   PORTB,F
    nop
    nop

    btfss   INDF,2
    xorwf   PORTB,F
    nop
    nop
    
    btfss   INDF,3
    xorwf   PORTB,F
    nop    
    nop

    btfss   INDF,4
    xorwf   PORTB,F
    nop
    nop

    btfss   INDF,5
    xorwf   PORTB,F
    nop
    nop

    btfss   INDF,6
    xorwf   PORTB,F
    nop
    nop

    btfss   INDF,7
    xorwf   PORTB,F
    nop
    nop
    movlw   0xFC

    ;Send EOP
    andwf   PORTB,F
    goto    $+D'1'
    movlw   0x02
    
    call    WaitOneBitTime    

    xorwf   PORTB,F    
    ;Set RB0/RB1 Input
    bsf     STATUS,RP0
    movlw   0x03
    iorwf   TRISB,F
    bcf     STATUS,RP0              ;Back to bank 0    
    return

WaitOneBitTime:
    return

    END