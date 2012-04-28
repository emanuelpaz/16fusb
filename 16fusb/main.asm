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
;    Notes: This file contains the code of the main loop of the       *
;           the firmware. Main  loop  is  liable  for decode packets, *
;           check the ACTION_FLAG and, based in it's value, take the  *
;           flow to correct point. The main loop is also the glue     *
;           between core and the custom code.                         *
;                                                                     *
;**********************************************************************
 
    __config 0x3F0A
    #include    "def.inc"

    ;From ISR_SHARED_INTERFACE (isr.asm) ------------------------------
    extern      ADDITIONAL_BITS, FRAME_NUMBER, PENDING_BYTES, TX_LEN
    extern      DEVICE_ADDRESS, NEW_DEVICE_ADDRESS, ACTION_FLAG

    ;From ISR_VARIABLES (isr.asm) -------------------------------------
    extern      TX_BUFFER

    ;From func.asm ----------------------------------------------------
    extern      DoCrc, InsertStuff, PreInitTXBuffer

    ;From stdreq.asm --------------------------------------------------
    extern      GetDescriptor, GetStatus, GetConfiguration
    extern      GetInterface, SetAddress

    ;From vreq.asm ----------------------------------------------------
    extern      InitSetup, VendorRequest, ProcessOut


MAIN_SHARED_INTERFACE   UDATA_SHR

TOTAL_LEN               RES     D'1'    ;Number of bytes to transfer in data phase (wLength)

    global      TOTAL_LEN


MAIN_VARIABLES          UDATA_OVR   0x44

RXDATA_BUFFER           RES     D'10'   ;Received bytes decoded.

    global      RXDATA_BUFFER


LOCAL_OVERLAY           UDATA_OVR   0x4F

TMP                     RES     D'1'    ;Temporary file
GEN                     RES     D'1'    ;General purpose file
GEN2                    RES     D'1'    ;General purpose file
SEEK                    RES     D'1'    ;Index file level one
SEEK2                   RES     D'1'    ;Index file level two
COUNT                   RES     D'1'    ;Counter file level one
COUNT2                  RES     D'1'    ;Counter file level two
COUNT3                  RES     D'1'    ;Counter file level three
NCHANGE_COUNT           RES     D'1'    ;Number of no change level in NRZI (bit stuffing)
RXDATA_LEN              RES     D'1'    ;Number of received bytes decoded.
DECODING_PID            RES     D'1'    ;Token PID of data on decoding
RXINPUT_LEN             RES     D'1'    ;Length of RXINPUT
RXINPUT_BUFFER          RES     D'13'   ;Copy of RX_BUFFER

    ;These exports are only used by ISR
    global      DECODING_PID, RXINPUT_LEN, RXINPUT_BUFFER



RESET_VECTOR    CODE    0x0000
    ;Enable only RB0 int
    movlw   B'00010000'
    movwf   INTCON
    
    ;And goto Start
    goto    Start
    nop


MAIN_PROG       CODE
; ---------------- Initial Setup (Start) ----------------
Start:
    ;Adjust RB0 edge (on rise) and disable pull-up resistors
    ;and make Prescaler 1:4
    bsf     STATUS,RP0
    movlw   B'11000001'
    movwf   OPTION_REG

    ;Disable USART (because we use RB1 for I/O)
    bcf     STATUS,RP0
    bcf     RCSTA,SPEN

    ;Clear Registers
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

    call    InitSetup

    ;Make RB0, RB1 and RB2 input
    bsf     STATUS,RP0
    movlw   B'00000111'
    iorwf   TRISB,F
    bcf     STATUS,RP0

    ;Enable Interrupts
    bsf     INTCON,GIE
; ---------------- Initial Setup (End) ----------------

MainLoop:
    movlw   AF_DECODE_DATA
    subwf   ACTION_FLAG,W           ;Checks for DECODE_DATA
    btfsc   STATUS,Z
    call    DecodeData   

    movlw   AF_PROC_SETUP
    subwf   ACTION_FLAG,W           ;Checks for PROC_SETUP
    btfsc   STATUS,Z
    call    ProcessSetup
    
    movlw   AF_PROC_OUT
    subwf   ACTION_FLAG,W           ;Checks for PROC_OUT
    btfss   STATUS,Z
    goto    $+3
    call    ProcessOut
    call    ComposeNullAndReturn

    btfss   PORTB,2                 ;Checks for Reset
    call    CheckReset

    goto    MainLoop

;Decode RXINPUT_BUFFER to RXDATA_BUFFER
DecodeData:
    ;Select BANK 0
    bcf     STATUS,RP0
    bcf     STATUS,RP1

    movf    RXINPUT_LEN,W
    movwf   COUNT
   
    movlw   RXINPUT_BUFFER
    movwf   SEEK                    ;Source
    clrf    RXDATA_LEN
    movlw   RXDATA_BUFFER
    movwf   SEEK2                   ;Destiny

    movlw   0x01
    movwf   GEN2                    ;Roles as "last nrzi bit"

    movlw   0x06                    ;If DATA1
    btfsc   RXINPUT_BUFFER,6   
    movlw   0x04                    ;If DATA0
    movwf   NCHANGE_COUNT
   
    movlw   0x08
    movwf   COUNT3                  ;COUNT3 controls bits in destiny

DD_CopyLoop:                        ;Controlled by COUNT
    movf    SEEK,W
    movwf   FSR
    movf    INDF,W
    movwf   TMP                     ;Put in TMP the byte to decode
   
    movf    SEEK2,W
    movwf   FSR
   
    movlw   0x08                    ;Decode 8 bits
    movwf   COUNT2

DD_CP_DecodeBit:                    ;Controlled by COUNT2
    movlw   0x01
    andwf   TMP,W
    movwf   GEN       
    xorwf   GEN2,F
    comf    GEN2,F

    btfss   GEN2,0
    goto    $+D'4'
    decfsz  NCHANGE_COUNT,F
    goto    $+D'4'
    goto    DD_RemoveBitStuff

    movlw   0x06
    movwf   NCHANGE_COUNT   

    rrf     GEN2,F
    rrf     INDF,F
    movf    GEN,W
    movwf   GEN2

DD_CP_DB_VerifyDestEnd:
    decfsz  COUNT3,F
    goto    DD_CP_DB_VerifyEnd

    incf    RXDATA_LEN,F
    movf    RXDATA_LEN,W
    subwf   RXINPUT_LEN,W
    sublw   0x02                    ;Skip CRC16 on decoding (2 bytes)
    btfsc   STATUS,Z
    goto    DD_CP_End

    incf    SEEK2,F
    movf    SEEK2,W
    movwf   FSR
    movlw   0x08
    movwf   COUNT3

DD_CP_DB_VerifyEnd:
    rrf     TMP,F
    decfsz  COUNT2,F
    goto    DD_CP_DecodeBit

DD_CP_DB_End:
    incf    SEEK,F
    decfsz  COUNT,F
    goto    DD_CopyLoop

DD_CP_End:
    btfss   DECODING_PID,2          ;Data from OUT?
    goto    DD_CP_End_Setup

;If data is from OUT
DD_CP_End_Out:
    movlw   AF_PROC_OUT
    movwf   ACTION_FLAG
    return

;If data is from SETUP
DD_CP_End_Setup:
    movlw   AF_PROC_SETUP
    movwf   ACTION_FLAG

    clrf    FRAME_NUMBER            ;Reset frame number
    movlw   DATA0PID
    movwf   TX_BUFFER
    
    ;Put setup's wLenght in TOTAL_LEN
    movf    RXDATA_BUFFER+6,W
    movwf   TOTAL_LEN

    return

DD_RemoveBitStuff:
    movlw   0x06
    movwf   NCHANGE_COUNT
   
    rrf     GEN2,F
    rrf     INDF,F

    decfsz  COUNT3,F
    goto    $+D'12'
    incf    RXDATA_LEN,F
    movf    RXDATA_LEN,W
    subwf   RXINPUT_LEN,W
    sublw   0x02                    ;Skip CRC16 on decoding (2 bytes)
    btfsc   STATUS,Z
    goto    DD_CP_End
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
    goto    DD_CP_DB_VerifyEnd
    goto    DD_CP_DB_End

ProcessSetup:
    movlw   0x060
    andwf   RXDATA_BUFFER,W         ;TMP will be zero if it's a standard request
    movwf   TMP

    btfss   RXDATA_BUFFER,7         ;Checks the transfer direction
    goto    PS_HostToDevice

PS_DeviceToHost:
    call    PreInitTXBuffer

    movf    TMP,F
    btfsc   STATUS,Z
    goto    PS_DTH_StandardRequest    
    
    call    VendorRequest
    goto    PS_DTH_End    
    
PS_DTH_StandardRequest:
    movf    RXDATA_BUFFER+1,W
    sublw   0x06
    btfsc   STATUS,Z
    call    GetDescriptor

    movf    RXDATA_BUFFER+1,F
    btfsc   STATUS,Z
    call    GetStatus

    movf    RXDATA_BUFFER+1,W
    sublw   0x08
    btfsc   STATUS,Z
    call    GetConfiguration

    movf    RXDATA_BUFFER+1,W
    sublw   0x0A
    btfsc   STATUS,Z
    call    GetInterface

PS_DTH_End:    
    call    DoCrc
    call    InsertStuff
    goto    SetReadyAndReturn

PS_HostToDevice:
    movf    TMP,F
    btfsc   STATUS,Z
    goto    PS_HTD_StandardRequest

    call    VendorRequest
    goto    PS_HTD_End

PS_HTD_StandardRequest:
    movf    RXDATA_BUFFER+1,W
    sublw   0x05
    btfsc   STATUS,Z
    call    SetAddress

PS_HTD_End:
    movf    TOTAL_LEN,F
    btfsc   STATUS,Z
    goto    ComposeNullAndReturn
    goto    SetFreeAndReturn


;Prepare buffer with zero length data packet
ComposeNullAndReturn:
    movlw   DATA1PID                ;DATA1 PID
    movwf   TX_BUFFER

    movlw   0x00                    ;CRC16
    movwf   TX_BUFFER+1
    movwf   TX_BUFFER+2
    
    clrf    TX_LEN                  ;Zero length
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