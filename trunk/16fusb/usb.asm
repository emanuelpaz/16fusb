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
;    Filename:        usb.asm                                         *
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

    ; Local labels to export
#if INTERRUPT_IN_ENDPOINT == 1
    global  PrepareIntTxBuffer
#endif

    ; (isr.asm)
    extern  TX_EXTRA_BITS
    extern  FRAME_NUMBER
    extern  DEVICE_ADDRESS
    extern  NEW_DEVICE_ADDRESS
    extern  ACTION_FLAG
    extern  TX_LEN
    extern  TX_BUFFER
#if INTERRUPT_IN_ENDPOINT == 1
    extern  INT_TX_BUFFER
#endif    

    ; (func.asm)
    extern  DoCrc
    extern  InsertStuff
    extern  PreInitTXBuffer

    ; (stdreq.asm)
    extern  GetDescriptor
    extern  GetStatus
    extern  GetConfiguration
    extern  GetInterface
    extern  SetAddress

    ; (main.asm)
    extern  Init
    extern  Main

    ; (setup.asm)
    extern  VendorRequest
    extern  ProcessOut
#if HID == 1
    extern  GetReportDescriptor
#endif


USB_SHARED_INTERFACE    UDATA_SHR

RXDATA_LEN      RES     D'1'        ; Number of received bytes decoded.

    global  RXDATA_LEN


USB_VARIABLES  UDATA    0x41+(INTERRUPT_IN_ENDPOINT*D'16')

CTRL_TOTAL_LEN  RES     D'1'        ; Total of bytes to transfer in data phase (wLength)
RXDATA_BUFFER   RES     D'8'        ; Received bytes decoded (EP0 e EP1 OUT).
#if INTERRUPT_OUT_ENDPOINT == 1
RXINPUT_LEN     RES     D'1'        ; Length of RXINPUT
RXINPUT_BUFFER  RES     D'13'       ; Copy of RX_BUFFER
#endif

    global  CTRL_TOTAL_LEN
    global  RXDATA_BUFFER


LOCAL_OVERLAY   UDATA_OVR   0x4A+(INTERRUPT_IN_ENDPOINT*D'16')+(INTERRUPT_OUT_ENDPOINT*D'14')

GEN                 RES     D'1'    ; General
GEN2                RES     D'1'    ; General
SEEK                RES     D'1'    ; Index level one
SEEK2               RES     D'1'    ; Index level two
COUNT               RES     D'1'    ; Counter level one
COUNT2              RES     D'1'    ; Counter level two
COUNT3              RES     D'1'    ; Counter file level three
NCHANGE_COUNT       RES     D'1'    ; Number of no change level in NRZI (bit stuffing)

#if INTERRUPT_OUT_ENDPOINT == 0
RXINPUT_LEN         RES     D'1'    ; Length of RXINPUT
RXINPUT_BUFFER      RES     D'13'   ; Copy of RX_BUFFER
#endif

    global  RXINPUT_LEN
    global  RXINPUT_BUFFER

#define     BYTE        RXINPUT_BUFFER
#define     REQTYPE     RXINPUT_BUFFER
#define     STUFFING    GEN,0

 
RESET_VECTOR    CODE    0x00
    ; enable only RB0 int
    movlw   B'00010000'
    movwf   INTCON
    
    ; and goto Start
    goto    Start
    nop


USB_MAIN_LOOP   CODE
; ---------------- Initial Setup (Start) ----------------
Start:
    call    Init

    bsf     STATUS,RP0
    bcf     STATUS,RP1

    ; adjust RB0 edge (on rise) and disable pull-up resistors
    ; and make Prescaler 1:4    
    movlw   B'11000001'
    movwf   OPTION_REG

    ; make RB0, RB1 and RB2 input
    movlw   B'00000111'
    iorwf   TRISB,F

    bcf     STATUS,RP0

    ; disable USART (because we use RB1 for I/O)    
    bcf     RCSTA,SPEN

    ; set ActionFlag Free
    clrf    ACTION_FLAG

    ; initial device address (0 NRZI coded)
    movlw   USB_NRZI_ZERO_ADDR
    movwf   DEVICE_ADDRESS
    movwf   NEW_DEVICE_ADDRESS

 #if INTERRUPT_IN_ENDPOINT == 1
    ; initialize data toggle for EP1
    movlw   USB_PID_DATA0
    movwf   INT_TX_BUFFER
#endif    

    ; enable interrupts
    bsf     INTCON,GIE
; ---------------- Initial Setup (End) ----------------

MainLoop:
    btfss   USB_EOPCHK              ; checks for Reset
    call    CheckReset

    call    Main

    ; select BANK 0
    bcf     STATUS,RP0
    bcf     STATUS,RP1

    btfss   AF_BIT_BUSY             ; if it's free don't check below
    goto    MainLoop

    btfsc   AF_BIT_DECODING         ; checks for decode mode
ML_Decode:
    call    DecodeData
ML_ProcSetupOut:
    btfss   AF_BIT_PID_OUT          ; checks for process setup/out
    goto    ProcessSetup            ; it's SETUP
    call    ProcessOut              ; it's OUT
#if INTERRUPT_OUT_ENDPOINT == 1    
    btfsc   AF_BIT_DECODING         ; checks pending decoding (from SETUP)
    goto    ML_Decode
#endif
    bcf     AF_BIT_BUSY             ; set it free
#if INTERRUPT_OUT_ENDPOINT == 1
    btfsc   AF_BIT_INTERRUPT        ; if it's an interrupt transfer, 
    goto    MainLoop                ; don't compose empty packet.
#endif
    goto    ComposeNullAndReturn
   

; decode RXINPUT_BUFFER to RXDATA_BUFFER
DecodeData:
    ; select BANK 0
    bcf     STATUS,RP0
    bcf     STATUS,RP1

    decf    RXINPUT_LEN,W           ; ignore PID on decoding
    movwf   COUNT                   ; number of bytes to decode
   
    movlw   RXINPUT_BUFFER+1        ; ignore PID on decoding
    movwf   SEEK                    ; source
    clrf    RXDATA_LEN
    movlw   RXDATA_BUFFER
    movwf   SEEK2                   ; destiny

    movlw   0x01
    movwf   GEN2                    ; roles as "last nrzi bit"

    movlw   0x06                    ; if DATA1
    btfsc   RXINPUT_BUFFER,6   
    movlw   0x04                    ; if DATA0
    movwf   NCHANGE_COUNT
    bcf     STUFFING
   
    movlw   0x08
    movwf   COUNT3                  ; controls number bits in destiny

DD_CopyLoop:                        ; controlled by COUNT
    movf    SEEK,W
    movwf   FSR
    movf    INDF,W
    movwf   BYTE                    ; put the byte to decode in BYTE
   
    movf    SEEK2,W
    movwf   FSR
   
    movlw   0x08                    ; decode 8 bits
    movwf   COUNT2

    btfss   STUFFING                ; stuffing bit is in bit 0?
    goto    DD_CP_DecodeBit
    bcf     STUFFING  
    movf    BYTE,W
    movwf   GEN2
    rrf     BYTE,F                  ; discard the stuffing bit
    decf    COUNT2,F    

DD_CP_DecodeBit:                    ; controlled by COUNT2
    movf    BYTE,W
    xorwf   GEN2,F
    comf    GEN2,F

    btfss   GEN2,0
    goto    DD_CP_DB_ResetNChange
    decfsz  NCHANGE_COUNT,F
    goto    DD_CP_DB_SaveLastBit

    ; six consecutives bits found
    rrf     BYTE,F                  ; discard the stuffing bit
    decfsz  COUNT2,F                ; the stuffing bit is in the next byte?
    goto    DD_CP_DB_ResetNChange
    bsf     STUFFING                ; get the stuffing bit in next byte
    incf    COUNT2,F

DD_CP_DB_ResetNChange:
    movlw   0x06
    movwf   NCHANGE_COUNT

DD_CP_DB_SaveLastBit:
    rrf     GEN2,F
    rrf     INDF,F
    movf    BYTE,W
    movwf   GEN2

DD_CP_DB_VerifyDestEnd:
    decfsz  COUNT3,F
    goto    DD_CP_DB_VerifyEnd
    incf    RXDATA_LEN,F
    movf    RXDATA_LEN,W
    subwf   RXINPUT_LEN,W
    xorlw   0x03                    ; discard PID and CRC16 (3 bytes)
    btfsc   STATUS,Z
    goto    DD_CP_End
    incf    SEEK2,F
    movf    SEEK2,W
    movwf   FSR
    movlw   0x08
    movwf   COUNT3

DD_CP_DB_VerifyEnd:
    rrf     BYTE,F
    decfsz  COUNT2,F
    goto    DD_CP_DecodeBit

DD_CP_DB_End:
    incf    SEEK,F
    decfsz  COUNT,F
    goto    DD_CopyLoop

DD_CP_End:
    bcf     AF_BIT_DECODING         ; put in process mode
    btfsc   AF_BIT_PID_OUT          ; data from SETUP?
    return                          ; if data is from OUT, return.

; if data is from SETUP
DD_CP_End_Setup:
    clrf    FRAME_NUMBER            ; reset frame number
    movlw   USB_PID_DATA0
    movwf   TX_BUFFER
    
    ; put setup's wLenght in CTRL_TOTAL_LEN
    movf    RXDATA_BUFFER+6,W
    movwf   CTRL_TOTAL_LEN

    return

ProcessSetup:
    movlw   0x60
    andwf   RXDATA_BUFFER,W         ; REQTYPE will be zero if it's a standard request
    movwf   REQTYPE

    btfss   RXDATA_BUFFER,7         ; checks the transfer direction
    goto    PS_HostToDevice

PS_DeviceToHost:
    call    PreInitTXBuffer

    movf    REQTYPE,F
    btfsc   STATUS,Z                ; is it standard request?
    goto    PS_DTH_StandardRequest    
    
    call    VendorRequest           ; it's class/vendor request
    goto    PS_DTH_End    
    
PS_DTH_StandardRequest:
; Check for Get Descriptor request
    movf    RXDATA_BUFFER+1,W
    xorlw   GET_DESCRIPTOR
    btfss   STATUS,Z
    goto    PS_DTH_NoDescriptor
#if HID == 1
; Check for Get Report Descriptor
    movf    RXDATA_BUFFER+3,W
    xorlw   DESCRIPTOR_TYPE_REPORT
    btfsc   STATUS,Z
    call    GetReportDescriptor
#endif
; Check for others descriptors
    call    GetDescriptor
PS_DTH_NoDescriptor:
; Check for Get Status request
    movf    RXDATA_BUFFER+1,F
    btfsc   STATUS,Z
    call    GetStatus
; Check for Get Configuration request
    movf    RXDATA_BUFFER+1,W
    xorlw   GET_CONFIGURATION
    btfsc   STATUS,Z
    call    GetConfiguration
; Check for Get Interface request
    movf    RXDATA_BUFFER+1,W
    xorlw   GET_INTERFACE
    btfsc   STATUS,Z
    call    GetInterface

PS_DTH_End:
    ; select BANK 0
    bcf     STATUS,RP0
    bcf     STATUS,RP1

#if INTERRUPT_IN_ENDPOINT == 1
    clrw
#endif
    call    DoCrc
#if INTERRUPT_IN_ENDPOINT == 1
    clrw
#endif
    call    InsertStuff
    goto    SetReadyAndReturn

PS_HostToDevice:
    movf    REQTYPE,F
    btfsc   STATUS,Z                ; is it standard request?
    goto    PS_HTD_StandardRequest

    call    VendorRequest           ; it's class/vendor request
    goto    PS_HTD_End

PS_HTD_StandardRequest:
    ; Check for Set Address request
    movf    RXDATA_BUFFER+1,W
    xorlw   SET_ADDRESS
    btfsc   STATUS,Z
    call    SetAddress

PS_HTD_End:
    ; select BANK 0
    bcf     STATUS,RP0
    bcf     STATUS,RP1

    movf    CTRL_TOTAL_LEN,F
    btfsc   STATUS,Z
    goto    ComposeNullAndReturn_
    bcf     AF_BIT_BUSY
    goto    MainLoop

; Prepare buffer with zero length data packet
ComposeNullAndReturn:
    ; select BANK 0
    bcf     STATUS,RP0
    bcf     STATUS,RP1
ComposeNullAndReturn_:
    movlw   USB_PID_DATA1           ; DATA1 PID
    movwf   TX_BUFFER
                  
    clrf    TX_BUFFER+1             ; CRC16
    clrf    TX_BUFFER+2
    
    clrf    TX_LEN                  ; zero length
    clrf    TX_EXTRA_BITS
    bcf     AF_BIT_PEND_BYTES

SetReadyAndReturn:
    bcf     AF_BIT_BUSY
    bsf     AF_BIT_TX_READY
    goto    MainLoop
        
CheckReset:
    ; select BANK 0
    bcf     STATUS,RP0
    bcf     STATUS,RP1

    movlw   0x3                     ; for 15 instructions (2.5us)
    movwf   COUNT
CR_Loop:
    btfsc   USB_EOPCHK
    return
    decfsz  COUNT,F
    goto    CR_Loop    
ResetDevice:                        ; SE0 for more than 2.5us, host is sending a reset
    movlw   USB_NRZI_ZERO_ADDR      ; initial device address (0 NRZI coded)
    movwf   DEVICE_ADDRESS
    movwf   NEW_DEVICE_ADDRESS
    return   
    

#if INTERRUPT_IN_ENDPOINT == 1
PrepareIntTxBuffer:
    ; select BANK 0
    bcf     STATUS,RP0
    bcf     STATUS,RP1

    ; data toggle
    movlw   USB_PID_DATA0
    btfss   INT_TX_BUFFER,3
    movlw   USB_PID_DATA1
    movwf   INT_TX_BUFFER

    movlw   0x01
    call    DoCrc
    movlw   0x01
    call    InsertStuff
    bsf     AF_BIT_INT_TX_READY

    return
#endif

    END