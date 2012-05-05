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
;    Filename:        vreq.asm                                        *
;    Date:                                                            *
;    Author:          Emanuel Paz                                     *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Notes: All vendor/class requests goes here.                      *
;                                                                     *
;           DirectIO implementation. This code can be used to handle  *
;           8 bits data via PIC's io pins. More details in API doc.   *
;                                                                     *
;**********************************************************************	


    #include    "def.inc"

    ;From MAIN_VARIABLES (main.asm) -----------------------------------
    extern      RXDATA_BUFFER

    ;From ISR_VARIABLES (isr.asm) -------------------------------------
    extern      TX_BUFFER

    ;From ISR_SHARED_INTERFACE (isr.asm) ------------------------------
    extern      FRAME_NUMBER


LOCAL_OVERLAY           UDATA_OVR   0x4F

TMP                     RES     D'1'    ;General purpose file

    	
    ;Local labels to export
    global      VendorRequest



VENDOR_REQUEST  CODE

VendorRequest:
;DirectIO Vendor request implementation
    btfss   RXDATA_BUFFER,7
    goto    Vreq_HostToDevice

VReq_DeviceToHost:
    movlw   0x01
    subwf   RXDATA_BUFFER+1,W
    btfsc   STATUS,Z
    goto    DirectIO_Read

    return

Vreq_HostToDevice:
    movlw   0x01
    subwf   RXDATA_BUFFER+1,W
    btfsc   STATUS,Z
    goto    DirectIO_Write

    return

DirectIO_Write:
    btfsc   RXDATA_BUFFER+2,0
    goto    DIO_WriteByte
    btfsc   RXDATA_BUFFER+2,1
    goto    DIO_WriteLowNibble
    btfsc   RXDATA_BUFFER+2,2
    goto    DIO_WriteHighNibble
    btfsc   RXDATA_BUFFER+2,3
    goto    DIO_WriteCtrl

   return

DirectIO_Read:
    btfsc   RXDATA_BUFFER+2,0
    goto    DIO_ReadByte
    btfsc   RXDATA_BUFFER+2,1
    goto    DIO_ReadLowNibble
    btfsc   RXDATA_BUFFER+2,2
    goto    DIO_ReadHighNibble
    btfsc   RXDATA_BUFFER+2,3
    goto    DIO_ReadCtrl
    btfsc   RXDATA_BUFFER+2,4
    goto    DIO_ReadStatus

    return

DIO_WriteByte:
    ;Put data port in output mode
    bsf     STATUS,RP0
    movlw   B'00000111'
    andwf   TRISB,F
    movlw   B'11111000'
    andwf   TRISA,F
    bcf     STATUS,RP0

    ;Put value in RB3-RB7
    movlw   B'00000111'
    andwf   PORTB,W
    movwf   TMP
    movlw   B'11111000'
    andwf   RXDATA_BUFFER+4,W       ;wIndex Lo
    iorwf   TMP,W
    movwf   PORTB

    ;Put the last bits values in RA0-RA2
    movlw   B'11111000'
    andwf   PORTA,W
    movwf   TMP
    movlw   B'00000111'
    andwf   RXDATA_BUFFER+4,W       ;wIndex Lo
    iorwf   TMP,W
    movwf   PORTA
    
    return

DIO_WriteLowNibble:
    ;Put low nibble in output mode
    bsf     STATUS,RP0
    bcf     TRISB,3
    movlw   B'11111000'
    andwf   TRISA,F
    bcf     STATUS,RP0

    btfss   RXDATA_BUFFER+4,3       ;wIndex Lo
    bcf     PORTB,3
    btfsc   RXDATA_BUFFER+4,3
    bsf     PORTB,3

    ;Put the last bits values in RA0-RA2
    movlw   B'11111000'
    andwf   PORTA,W
    movwf   TMP
    movlw   B'00000111'
    andwf   RXDATA_BUFFER+4,W       ;wIndex Lo
    iorwf   TMP,W
    movwf   PORTA

    return

DIO_WriteHighNibble:
    ;Put high nibble in output mode
    bsf     STATUS,RP0
    movlw   B'00001111'
    andwf   TRISB,F
    bcf     STATUS,RP0

    ;Put value in RB4-RB7
    movlw   B'00001111'
    andwf   PORTB,W
    movwf   TMP
    movlw   B'11110000'
    swapf   RXDATA_BUFFER+4,F       ;wIndex Lo
    andwf   RXDATA_BUFFER+4,W
    iorwf   TMP,W
    movwf   PORTB

    return

DIO_WriteCtrl:
    ;Put RA3-RA4 in output mode
    bsf     STATUS,RP0
    movlw   B'11100111'
    andwf   TRISA,F
    bcf     STATUS,RP0

    ;Put value in RA3-RA4
    movlw   B'11100111'
    andwf   PORTA,W
    movwf   TMP
    movlw   B'00011000'
    rlf     RXDATA_BUFFER+4,F       ;wIndex Lo
    rlf     RXDATA_BUFFER+4,F
    rlf     RXDATA_BUFFER+4,F
    andwf   RXDATA_BUFFER+4,W
    iorwf   TMP,W
    movwf   PORTA

    return

DIO_ReadByte:
    ;Put data port in input mode
    bsf     STATUS,RP0
    movlw   B'11111000'
    iorwf   TRISB,F
    movlw   B'00000111'
    iorwf   TRISA,F
    bcf     STATUS,RP0

    movf    PORTA,W
    andlw   B'00000111'
    movwf   TMP
    movf    PORTB,W
    andlw   B'11111000'
    iorwf   TMP,F

    goto    DIO_PrepareAnswer

DIO_ReadLowNibble:
    ;Put low nibble in input mode
    bsf     STATUS,RP0
    movlw   B'00001000'
    iorwf   TRISB,F
    movlw   B'00000111'
    iorwf   TRISA,F
    bcf     STATUS,RP0

    movf    PORTA,W
    andlw   B'00000111'
    movwf   TMP
    movf    PORTB,W
    andlw   B'00001000'
    iorwf   TMP,F

    goto    DIO_PrepareAnswer

DIO_ReadHighNibble:
    ;Put high nibble in input mode
    bsf     STATUS,RP0
    movlw   B'11110000'
    iorwf   TRISB,F
    bcf     STATUS,RP0

    movf    PORTB,W
    andlw   B'11110000'
    movwf   TMP
    swapf   TMP,F

    goto    DIO_PrepareAnswer

DIO_ReadCtrl:
    ;Put RA3-RA4 in input mode
    bsf     STATUS,RP0
    movlw   B'00011000'
    iorwf   TRISA,F
    bcf     STATUS,RP0

    movf    PORTA,W
    andlw   B'00011000'
    movwf   TMP
    rrf     TMP,F
    rrf     TMP,F
    rrf     TMP,F
    bcf     TMP,7
    bcf     TMP,6
    bcf     TMP,5

    goto    DIO_PrepareAnswer

DIO_ReadStatus:
    clrf    TMP
    btfsc   PORTA,5
    bsf     TMP,0

    goto DIO_PrepareAnswer

;Prapare TX_BUFFER
;TMP must have the byte with answer.
DIO_PrepareAnswer:
    movf    TMP,W                   ;Data read from pins
    movwf   TX_BUFFER+1
    
    return

	END