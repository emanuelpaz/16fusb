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
;    Filename:        isr.asm                                         *
;    Date:                                                            *
;    Author:          Emanuel Paz                                     *
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


    #include    "def.inc"

    ;From LOCAL_OVERLAY of main.asm -----------------------------------
    extern      RXINPUT_LEN, RXINPUT_BUFFER, DECODING_PID


ISR_SHARED_INTERFACE    UDATA_SHR

W_TMP                   RES     D'1'    ;File to save W
STATUS_TMP              RES     D'1'    ;File to save STATUS
ACTION_FLAG             RES     D'1'    ;What main loop must do
ADDITIONAL_BITS         RES     D'1'    ;Number of additional bits(stuffing bits) to send
FRAME_NUMBER            RES     D'1'    ;Frame number of a transaction with data larger than 8 bytes
PENDING_BYTES           RES     D'1'    ;A bit (0) that signals if there are pending bytes to send
                                        ;Used in transactions with data larger than 8 bytes
DEVICE_ADDRESS          RES     D'1'    ;Current device address
NEW_DEVICE_ADDRESS      RES     D'1'    ;Address designated by host
TX_LEN                  RES     D'1'    ;Number of bytes to send in TX_BUFFER

    global      ACTION_FLAG, ADDITIONAL_BITS, FRAME_NUMBER, PENDING_BYTES
    global      DEVICE_ADDRESS, NEW_DEVICE_ADDRESS, TX_LEN


ISR_VARIABLES           UDATA   0x20

FSR_TMP                 RES     D'1'    ;FIle to save FSR
TMP                     RES     D'1'    ;Temporary file
COUNT                   RES     D'1'    ;Counter file level one
SEEK                    RES     D'1'    ;Index file level one
SEEK2                   RES     D'1'    ;Index file level two
LAST_TOKEN_PID          RES     D'1'    ;The last Token PID received
RX_LEN                  RES     D'1'    ;Number of bytes received in RX_BUFFER
RX_BUFFER               RES     D'13'   ;NRZI data received from host, with bit stuffing
TX_BUFFER               RES     D'13'   ;Tranmission Buffer. Contains data (not coded) to send

    global      TX_BUFFER



INTERRUPT_VECTOR    CODE    0x0004
; -------------- Sync (start) --------------
    ;Save context first
    movwf   W_TMP
    swapf   STATUS,W
    movwf   STATUS_TMP
    
    bcf     STATUS,RP0   

WaitForJ:
    bcf     STATUS,RP1
    btfsc   PORTB,0
    goto    WaitForJ
WaitForK:
    btfss   PORTB,0
    goto    WaitForK    
    movf    FSR,W
FoundK:
    movwf   FSR_TMP
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
    subwf   ACTION_FLAG,W           ;Checks ACTION_FLAG
    btfsc   STATUS,Z
    goto    $+D'4'                  ;Jump if answer is ready
    movlw   NAKPID                  ;Put NAK to send
    call    SendHandshake           ;Send NAK
    goto    ReturnFromISR           ;And leave interrupt service

    call    SendTXBuffer            ;Send answer in buffer
    movf    NEW_DEVICE_ADDRESS,W
    movwf   DEVICE_ADDRESS          ;Renew device address
    movlw   AF_PROC_SETUP
    btfsc   PENDING_BYTES,0
    goto    HI_AdjustFrame          ;Jump if theres pending bytes

    movlw   AF_FREE                 ;If there are no pending bytes, set it free
    goto    $+D'2'

HI_AdjustFrame:
    incf    FRAME_NUMBER,F          ;Increment frame if there are pending bytes
    
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
    movf    FSR_TMP,W
    movwf   FSR
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

    ;We're in a Data packet, so if ACTION_FLAG is
    ;setted with AF_TX_BUFF_READY we must make it free.
    movlw   AF_TX_BUFF_READY
    subwf   ACTION_FLAG,W
    btfss   STATUS,Z
    goto    $+D'3'
    movlw   AF_FREE
    movwf   ACTION_FLAG

    movlw   AF_FREE
    subwf   ACTION_FLAG,W           ;Checks ACTION_FLAG
    btfsc   STATUS,Z
    goto    $+D'4'

    movlw   NAKPID
    call    SendHandshake           ;If ACTION_FLAG is not free, send NAK
    goto    ReturnFromISR           ;And return
    
    movlw   ACKPID                  ;If it's free...
    call    SendHandshake           ;Send ACK
    
    ;if it's a zero length packet, just return.
    movf    RX_LEN,W
    sublw   0x03
    btfsc   STATUS,Z
    goto    ReturnFromISR


DP_PrepareDataToDecoding:
    movlw   AF_DECODE_DATA          ;Tells MainLoop to decode data
    movwf   ACTION_FLAG

    movf    LAST_TOKEN_PID,W
    movwf   DECODING_PID

    decf    RX_LEN,W
    movwf   RXINPUT_LEN 
    movwf   COUNT

    movlw   RX_BUFFER+1             ;Ignore Token PID
    movwf   SEEK                    ;Source

    movlw   RXINPUT_BUFFER
    movwf   SEEK2                   ;Destiny

;Copy RX_BUFFER to RXINPUT_BUFFER
DP_PDTD_CopyBuffer:
    ;source
    movf    SEEK,W
    movwf   FSR
    movf    INDF,W
    movwf   TMP

    ;destiny
    movf    SEEK2,W
    movwf   FSR
    movf    TMP,W
    movwf   INDF

    incf    SEEK,F
    incf    SEEK2,F
    decfsz  COUNT,F
    goto    DP_PDTD_CopyBuffer

    goto    ReturnFromISR

SendTXBuffer:
    ;Prepare latch
    bsf     PORTB,1                 ;RB0 will by 0 due to R-M-W (we're in EOP)

    movlw   0x03
    addwf   TX_LEN,F                ;TX_LEN += PID + CRC16 (3 bytes)

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
    goto    $+D'1'                     ;Here, 1 bit time elapsed. TRM0 += 1.

    ;These two cycles makes T0IF verification at the last cycle of bit time,
    ;so we can jump to the EOP with only one excessive instruction cycle (166ns)
    ;in most cases. Sometimes trash bits, at the end of the package, 
    ;may occurs (see below).
    goto    $+D'1'

;Send Sync
STXB_SyncLoop:            
    xorwf   PORTB,F
    decfsz  COUNT,F
    goto    STXB_SyncLoop
    
    goto    $+D'1'
    goto    $+D'1'

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
    goto    $+D'1'
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

    ;Prepare latch
    bsf     PORTB,1                 ;RB0 will by 0 due to R-M-W (we're in EOP)

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
    
    goto    $+D'1'
    goto    $+D'1'

    ;Send HandShake PID
    btfss   TMP,0
    xorwf   PORTB,F
    goto    $+D'1'
    
    btfss   TMP,1
    xorwf   PORTB,F
    goto    $+D'1'

    btfss   TMP,2
    xorwf   PORTB,F
    goto    $+D'1'
    
    btfss   TMP,3
    xorwf   PORTB,F
    goto    $+D'1'

    btfss   TMP,4
    xorwf   PORTB,F
    goto    $+D'1'

    btfss   TMP,5
    xorwf   PORTB,F
    goto    $+D'1'

    btfss   TMP,6
    xorwf   PORTB,F
    goto    $+D'1'

    btfss   TMP,7
    xorwf   PORTB,F
    goto    GenEop                  ;2 cycles
    

    END