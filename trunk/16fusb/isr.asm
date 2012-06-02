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

    ; (usb.asm)
    extern  RXINPUT_LEN
    extern  RXINPUT_BUFFER


ISR_SHARED_INTERFACE    UDATA_SHR

W_TMP                   RES     D'1'    ; File to save W
STATUS_TMP              RES     D'1'    ; File to save STATUS
FSR_TMP                 RES     D'1'    ; File to save FSR
ACTION_FLAG             RES     D'1'    ; What main loop must do
FRAME_NUMBER            RES     D'1'    ; Frame number of a transaction with data larger than 8 bytes
DEVICE_ADDRESS          RES     D'1'    ; Current device address
NEW_DEVICE_ADDRESS      RES     D'1'    ; Address designated by host

    global  ACTION_FLAG
    global  TX_EXTRA_BITS
    global  FRAME_NUMBER
    global  DEVICE_ADDRESS
    global  NEW_DEVICE_ADDRESS
    global  TX_LEN


ISR_VARIABLES           UDATA   0x20

RX_BUFFER               RES     D'13'   ; NRZI data received from host, with bit stuffing

TX_BUFFER               RES     D'14'   ; EP0 tranmission buffer for control transfers
TX_LEN                  RES     D'1'    ; Number of bytes to send in TX_BUFFER
TX_EXTRA_BITS           RES     D'1'    ; Number of additional bits(stuffing bits) to send

#if INTERRUPT_IN_ENDPOINT == 1
INT_TX_BUFFER           RES     D'14'   ; EP1(IN) tranmission buffer for interrupt transfer
INT_TX_LEN              RES     D'1'    ; Number of bytes to send in INT_TX_BUFFER
INT_TX_EXTRA_BITS       RES     D'1'    ; Number of additional bits(stuffing bits) to send
#endif

TMP                     RES     D'1'    ; Temporary
TMP2                    RES     D'1'    ; Temporary
GEN                     RES     D'1'    ; General
GEN2                    RES     D'1'    ; General

    global  TX_BUFFER
#if INTERRUPT_IN_ENDPOINT == 1
    global  INT_TX_BUFFER
    global  INT_TX_LEN
    global  INT_TX_EXTRA_BITS
#endif


#define COUNT               TMP         ; Counter
#define PID                 TMP2        ; PID to send on handshake
#define RX_LEN              TMP2        ; Number of bytes received in RX_BUFFER
#define SEEK                GEN         ; Index level one
#define SEEK2               GEN2        ; Index level two
#define LAST_TOKEN_PID      GEN         ; The last Token PID received
#define LAST_TOKEN_ADDR     GEN2        ; The address of last token received
#define PAYLOAD_LEN         GEN
#define ADDITIONAL_BITS     GEN2


INTERRUPT_VECTOR    CODE    0x04
; -------------- Sync (start) --------------
    ; save context
    movwf   W_TMP
    swapf   STATUS,W
    movwf   STATUS_TMP
    
    bcf     STATUS,RP0   

WaitForJ:
    bcf     STATUS,RP1
    btfsc   USB_DPLUS
    goto    WaitForJ
WaitForK:
    btfss   USB_DPLUS
    goto    WaitForK    
    movf    FSR,W
FoundK:
    movwf   FSR_TMP
    btfss   USB_DPLUS
    goto    WaitForK    
    
    ; setup RX_BUFFER
    movlw   RX_BUFFER
    movwf   FSR
    clrf    INDF
; -------------- Sync (end) ----------------

    btfsc   USB_DPLUS
    bsf     INDF,0
    btfss   USB_EOPCHK
    goto    Eop
    
    btfsc   USB_DPLUS
    bsf     INDF,1
    btfss   USB_EOPCHK
    goto    Eop

    btfsc   USB_DPLUS
    bsf     INDF,2
    btfss   USB_EOPCHK
    goto    Eop

    btfsc   USB_DPLUS
    bsf     INDF,3
    btfss   USB_EOPCHK
    goto    Eop
RxLoop:
    btfsc   USB_DPLUS    
    bsf     INDF,4
    btfss   USB_EOPCHK
    goto    Eop

    btfsc   USB_DPLUS
    bsf     INDF,5
    btfss   USB_EOPCHK
    goto    Eop

    btfsc   USB_DPLUS
    bsf     INDF,6
    btfss   USB_EOPCHK
    goto    Eop

    btfsc   USB_DPLUS
    bsf     INDF,7
    incf    FSR,F
    clrf    INDF
    
    btfsc   USB_DPLUS
    bsf     INDF,0
    btfss   USB_EOPCHK
    goto    Eop
    
    btfsc   USB_DPLUS
    bsf     INDF,1
    btfss   USB_EOPCHK
    goto    Eop
    
    btfsc   USB_DPLUS
    bsf     INDF,2
    btfss   USB_EOPCHK
    goto    Eop

    btfsc   USB_DPLUS
    bsf     INDF,3
    goto    RxLoop
    
; End of Packet detcted
Eop:
    btfsc   RX_BUFFER,1             ; is it data packet?
    goto    DataPack
    btfss   RX_BUFFER,0
    goto    ReturnFromISR

TokenPack:
    btfsc   RX_BUFFER,4             ; is it SETUP/OUT?
    goto    HandleSetupOut

HandleIn:
#if INTERRUPT_IN_ENDPOINT == 1
    ; check endpoint
    bcf     AF_BIT_INTERRUPT
    rlf     RX_BUFFER+1,W
    xorwf   RX_BUFFER+1,F
    btfss   RX_BUFFER+1,7
    bsf     AF_BIT_INTERRUPT

    btfss   AF_BIT_INTERRUPT
    goto    HI_Is_TX_Ready  
HI_Is_Int_TX_Ready:
    btfss   AF_BIT_INT_TX_READY     ; answer from EP1 is ready?
    goto    HI_Nak
    bcf     AF_BIT_INT_TX_READY
    movlw   INT_TX_BUFFER
    movwf   FSR
    movf    INT_TX_EXTRA_BITS,W
    movwf   ADDITIONAL_BITS
    movf    INT_TX_LEN,W
    goto    HI_Send
#endif
HI_Is_TX_Ready:
    btfss   AF_BIT_TX_READY         ; answer from EP0 is ready?
    goto    HI_Nak
    bcf     AF_BIT_TX_READY
    movlw   TX_BUFFER
    movwf   FSR
#if INTERRUPT_IN_ENDPOINT == 1
    movf    TX_EXTRA_BITS,W
    movwf   ADDITIONAL_BITS
#endif
    movf    TX_LEN,W
    goto    HI_Send
HI_Nak:
    movlw   USB_PID_NAK             ; if answer isn't ready put NAK to send
    call    SendHandshake           ; send NAK
    goto    ReturnFromISR           ; and leave interrupt service
HI_Send:
    call    SendTXBuffer            ; send answer in buffer
#if INTERRUPT_IN_ENDPOINT == 1
    btfsc   AF_BIT_INTERRUPT
    goto    ReturnFromISR
#endif
    movf    NEW_DEVICE_ADDRESS,W
    movwf   DEVICE_ADDRESS          ; renew device address

    btfss   AF_BIT_PEND_BYTES
    goto    ReturnFromISR

    incf    FRAME_NUMBER,F          ; increment frame if there are pending bytes
    bsf     AF_BIT_BUSY 
    goto    ReturnFromISR

HandleSetupOut:
    movf    RX_BUFFER,W        
    movwf   LAST_TOKEN_PID          ; save token PID

    movf    RX_BUFFER+1,W           ; save token ADDR and first EP bit (bit7)
    movwf   LAST_TOKEN_ADDR 

ReturnFromISR:
    ; restore Context
    movf    FSR_TMP,W
    movwf   FSR
    swapf   STATUS_TMP,W
    movwf   STATUS
    swapf   W_TMP,F
    swapf   W_TMP,W

    bcf     INTCON,INTF
    retfie

DataPack:
    ; check packet address
    movlw   0x7F
    andwf   LAST_TOKEN_ADDR,W
    xorwf   DEVICE_ADDRESS,W
    btfss   STATUS,Z
    goto    ReturnFromISR           ; address does not match, discard packet

    ; if still processing send NAK
    btfss   AF_BIT_BUSY
    goto    DP_Ack

#if INTERRUPT_OUT_ENDPOINT == 1
    ; As we use the same buffer to receive control and interrupt transfer,
    ; if host send a setup packet while device is decoding a previous data 
    ; from a out interrupt, the device discard it. If you need send control
    ; messages just after out interrupts, you may put a delay between them.
    ; Currently, decoding time takes 254us.
    btfss   LAST_TOKEN_PID,2
    return
#endif

DP_Nak:
    movlw   USB_PID_NAK
    call    SendHandshake           ; send NAK
    goto    ReturnFromISR           ; And return
DP_Ack:
    movlw   USB_PID_ACK
    call    SendHandshake           ; if it's free or a Setup packet send ACK

    ; set RX_LEN
    movlw   RX_BUFFER
    subwf   FSR,W
    movwf   RX_LEN
    movwf   RXINPUT_LEN
    
    ; if it's a zero length packet, just return.
    movf    RX_LEN,W
    xorlw   0x03
    btfsc   STATUS,Z
    goto    ReturnFromISR

DP_PrepareDataToDecoding:
    ; tells MainLoop to decode data
    bsf     AF_BIT_BUSY
    bsf     AF_BIT_DECODING
    bcf     AF_BIT_PID_OUT
    btfsc   LAST_TOKEN_PID,2
    bsf     AF_BIT_PID_OUT

#if INTERRUPT_OUT_ENDPOINT == 1    
    ; if EP is not zero, set transfer type to interrupt
    bcf     AF_BIT_INTERRUPT
    rlf     LAST_TOKEN_ADDR,W
    xorwf   LAST_TOKEN_ADDR,F
    btfss   LAST_TOKEN_ADDR,7
    bsf     AF_BIT_INTERRUPT
#endif

    movlw   RX_BUFFER
    movwf   SEEK                    ; source

    movlw   RXINPUT_BUFFER
    movwf   SEEK2                   ; destiny

; copy RX_BUFFER to RXINPUT_BUFFER
DP_PDTD_CopyBuffer:
    movf    SEEK,W
    movwf   FSR
    movf    INDF,W
    movwf   TMP

    movf    SEEK2,W
    movwf   FSR
    movf    TMP,W
    movwf   INDF

    incf    SEEK,F
    incf    SEEK2,F
    decfsz  RX_LEN,F
    goto    DP_PDTD_CopyBuffer

    goto    ReturnFromISR

;********************************************************
; FSR must contain buffer address to send.
; W must contain the length of payload data.
SendTXBuffer:
    addlw   0x03                    ; TX_PAYLOAD_LEN += PID + CRC16 (3 bytes)
    movwf   PAYLOAD_LEN

    ; prepare latch
    bsf     USB_DMINUS              ; USB_DPLUS will by 0 due to R-M-W (we're in EOP)       

    ; set RB0/RB1 Output
    bsf     STATUS,RP0
    movlw   0xFC
    andwf   TRISB,F
    bcf     STATUS,RP0
  
    movlw   0x07
    movwf   COUNT

    bcf     STATUS,C
    rlf     PAYLOAD_LEN,F
    rlf     PAYLOAD_LEN,F
    rlf     PAYLOAD_LEN,W
    addlw   0x08                    ; 8 bits of Sync Pattern
#if INTERRUPT_IN_ENDPOINT == 1
    addwf   ADDITIONAL_BITS,W
#else
    addwf   TX_EXTRA_BITS,W
#endif
    sublw   0xFF                    ; 255 - 8 - (TX_PAYLOAD_LEN*8) - AdditionalBits    
    movwf   TMR0
                                    
    nop                             ; stabilize TRM0 value

    ; TMR0 written, two (next) cycles inhibited.
    nop    
    movlw   B'00110000'             ; enable TIMER0 int

    ; the next four cycles takes 1 bit time.
    movwf   INTCON
    movlw   0x03
    goto    $+D'1'                  ; here, 1 bit time elapsed. TRM0 += 1.

    ; These two cycles makes T0IF verification at the last cycle of bit time,
    ; so we can jump to the EOP with only one excessive instruction cycle (166ns)
    ; in most cases. Sometimes trash bits, at the end of the package, 
    ; may occurs (see below).
    goto    $+D'1'

; send Sync
STXB_SyncLoop:            
    xorwf   USB_PORT,F
    decfsz  COUNT,F
    goto    STXB_SyncLoop
    
    goto    $+D'1'
    goto    $+D'1'

    ; send TX_Buffer (doing NRZI encode)    
    btfss   INDF,0
    xorwf   USB_PORT,F
    btfsc   INTCON,T0IF
    goto    GenEop
    
    btfss   INDF,1
    xorwf   USB_PORT,F
    btfsc   INTCON,T0IF
    goto    GenEop

STXB_SendByte:
    btfss   INDF,2
    xorwf   USB_PORT,F
    btfsc   INTCON,T0IF
    goto    GenEop
    
    btfss   INDF,3
    xorwf   USB_PORT,F
    btfsc   INTCON,T0IF
    goto    GenEop
    
    btfss   INDF,4
    xorwf   USB_PORT,F
    btfsc   INTCON,T0IF
    goto    GenEop
    
    btfss   INDF,5
    xorwf   USB_PORT,F
    btfsc   INTCON,T0IF
    goto    GenEop
    
    btfss   INDF,6
    xorwf   USB_PORT,F
    btfsc   INTCON,T0IF
    goto    GenEop
    
    ; We can't check for T0IF here because FSR needs to be
    ; incremented to take next bit in buffer. Due this, sometimes,
    ; one trash bit may be present before EOP. In fact, it's not a
    ; problem, because hosts just ignore extra bits in package. ;)
    btfss   INDF,7
    xorwf   USB_PORT,F
    incf    FSR,F
    nop

    btfss   INDF,0
    xorwf   USB_PORT,F
    btfsc   INTCON,T0IF
    goto    GenEop
    
    ; Same about trash bit here, but this time due to 'goto STXB_SendByte'.
    btfss   INDF,1
    xorwf   USB_PORT,F
    goto    STXB_SendByte

GenEop:
    movlw   0xFC
GenEop_01:
    andwf   USB_PORT,F
    bcf     INTCON,T0IE             ; disable TIMER0 int
    goto    GenEop_02
GenEop_02:
    movlw   0x02
    goto    $+D'1'
    nop
    xorwf   USB_PORT,F

    ; set RB0/RB1 Input
    bsf     STATUS,RP0
    movlw   0x03
    iorwf   TRISB,F
    bcf     STATUS,RP0
    return

SendHandshake:
    movwf   PID                     ; save handshake PID to send (from W)

    ; prepare latch
    bsf     USB_DMINUS              ; USB_DPLUS will by 0 due to R-M-W (we're in EOP)

    ; set RB0/RB1 Output
    bsf     STATUS,RP0
    movlw   0xFC
    andwf   TRISB,F
    bcf     STATUS,RP0              ; back to bank 0

    movlw   0x07
    movwf   COUNT

    movlw   0x03    
SH_SyncLoop:                        ; send Sync    
    xorwf   USB_PORT,F
    decfsz  COUNT,F
    goto    SH_SyncLoop
    
    goto    $+D'1'
    goto    $+D'1'

    ; send handshake PID
    btfss   PID,0
    xorwf   USB_PORT,F
    goto    $+D'1'
    
    btfss   PID,1
    xorwf   USB_PORT,F
    goto    $+D'1'

    btfss   PID,2
    xorwf   USB_PORT,F
    goto    $+D'1'
    
    btfss   PID,3
    xorwf   USB_PORT,F
    goto    $+D'1'

    btfss   PID,4
    xorwf   USB_PORT,F
    goto    $+D'1'

    btfss   PID,5
    xorwf   USB_PORT,F
    goto    $+D'1'

    btfss   PID,6
    xorwf   USB_PORT,F
    goto    $+D'1'

    btfss   PID,7
    xorwf   USB_PORT,F
    goto    GenEop                  ; 2 cycles
    

    END