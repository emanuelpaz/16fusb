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
    ;   Filename:      stdreq.asm                                         *
    ;   Date:                                                             *
    ;   Author:        Emanuel Paz                                        *
    ;                                                                     *
    ;**********************************************************************
    ;                                                                     *
    ;   Files required: header.inc                                        *
    ;                                                                     *
    ;**********************************************************************
    ;                                                                     *
    ;   Notes: Implementation of all mandatory standard requests          *
    ;          required by USB 1.1 specification.                         *
    ;                                                                     *
    ;**********************************************************************


    include    "header.inc"

    global     GetDescriptor, GetStatus, GetConfiguration, GetInterface, SetAddress

    extern     SetFreeAndReturn, SetReadyAndReturn, ComposeNullAndReturn
    extern     InsertStuff, PreInitTXBuffer, DoCrc

STANDARD_REQUEST   CODE
GetDescriptor:
    movlw   TX_BUFFER+1             ;Initial Address of data
    movwf   FSR

    movf    RXDATA_BUFFER+3,W
    sublw   0x01
    btfsc   STATUS,Z
    goto    GetDeviceDescriptor

    movf    RXDATA_BUFFER+3,W
    sublw   0x02
    btfsc   STATUS,Z
    goto    GetConfigDescriptor

    goto    SetFreeAndReturn        ;If not recognized, set it free and return

GetDeviceDescriptor:
    movlw   0x01
    subwf   FRAME_NUMBER,W
    btfsc   STATUS,Z
    goto    DD_Frame1
    movlw   0x02
    subwf   FRAME_NUMBER,W
    btfsc   STATUS,Z
    goto    DD_Frame2

DD_Frame0:                          ;First 8 bytes of Device Descriptor
    call    PreInitTXBuffer

    movlw   D'18'                   ;bLength
    movwf   TX_BUFFER+1

    movlw   0x01                    ;bDescriptorType
    movwf   TX_BUFFER+2

    movlw   USBVL                   ;bcdUSB MN
    movwf   TX_BUFFER+3
    movlw   USBVH                   ;bcdUSB JJ
    movwf   TX_BUFFER+4

    movlw   DEVCLASS                ;bDeviceClass
    movwf   TX_BUFFER+5

    movlw   DEVSUBCLASS             ;bDeviceSubClass
    movwf   TX_BUFFER+6

    movlw   DEVPROTOCOL             ;bDeviceProtocol
    movwf   TX_BUFFER+7

    movlw   0x08                    ;bMaxPacketSize
    movwf   TX_BUFFER+8

    call    DoCrc

    call    InsertStuff
    goto    SetReadyAndReturn

DD_Frame1:                          ;Second 8 bytes of Device Descriptor
    call    PreInitTXBuffer

    movlw   VIDL                    ;idVendor low
    movwf   TX_BUFFER+1
    movlw   VIDH                    ;idVendor high
    movwf   TX_BUFFER+2

    movlw   PIDL                    ;idProduct low
    movwf   TX_BUFFER+3
    movlw   PIDH                    ;idProduct high
    movwf   TX_BUFFER+4

    movlw   DEVICEVL                ;bcdDevice low
    movwf   TX_BUFFER+5
    movlw   DEVICEVH                ;bcdDevice high
    movwf   TX_BUFFER+6

    movlw   INDEXMANU               ;iManufacturer
    movwf   TX_BUFFER+7

    movlw   INDEXPROD
    movwf   TX_BUFFER+8             ;iProduct

    call    DoCrc

    call    InsertStuff
    goto    SetReadyAndReturn

DD_Frame2:                          ;Last 2 bytes of Device Descriptor
    movlw   DATA1PID                ;DATA1 PID
    movwf   TX_BUFFER

    movlw   INDEXSER                ;iSerialNumber
    movwf   TX_BUFFER+1

    movlw   NUMCONFIG               ;bNumConfigurations
    movwf   TX_BUFFER+2

    movlw   0x02
    movwf   COUNT
    call    DoCrc

    movlw   D'5'
    movwf   TX_LEN

    call    InsertStuff

    bcf     PENDING_BYTES,0
    goto    SetReadyAndReturn

GetConfigDescriptor:
    movlw   0x01
    subwf   FRAME_NUMBER,W
    btfsc   STATUS,Z
    goto    CD_Frame1
    movlw   0x02
    subwf   FRAME_NUMBER,W
    btfsc   STATUS,Z
    goto    CD_Frame2

CD_Frame0:                          ;First 8 bytes of Configuration Descriptor
    call    PreInitTXBuffer

    movlw   D'9'                    ;bLength
    movwf   TX_BUFFER+1

    movlw   0x2                     ;bDescriptorType
    movwf   TX_BUFFER+2

    movlw   D'18'                   ;wTotalLenght L
    movwf   TX_BUFFER+3
    movlw   0x00                    ;wTotalLenght H
    movwf   TX_BUFFER+4

    movlw   0x01                    ;bNumInterfaces
    movwf   TX_BUFFER+5

    movlw   CONFIGVAL               ;bConfigurationValue
    movwf   TX_BUFFER+6

    movlw   INDEXCONF               ;iConfiguration
    movwf   TX_BUFFER+7

    movlw   CONFATTRS               ;bmAttributes
    movwf   TX_BUFFER+8

    call    DoCrc

    call    InsertStuff
    goto    SetReadyAndReturn

CD_Frame1:                          ;Second 8 bytes of Configuration Descriptor
    call    PreInitTXBuffer

    movlw   MAXPOWER                ;bMaxPower
    movwf   TX_BUFFER+1

    movlw   D'9'                    ;bLength
    movwf   TX_BUFFER+2

    movlw   0x04                    ;bDescriptorType
    movwf   TX_BUFFER+3

    movlw   0x00                    ;bInterfaceNumber
    movwf   TX_BUFFER+4

    movlw   ALTSETTING
    movwf   TX_BUFFER+5             ;bAlternateSetting

    movlw   0x00
    movwf   TX_BUFFER+6             ;bNumEndPoints

    movlw   INTERCLASS
    movwf   TX_BUFFER+7             ;bInterfaceClass

    movlw   INTERSUBCLASS
    movwf   TX_BUFFER+8             ;bInterfaceSubClass

    call    DoCrc

    call    InsertStuff
    goto    SetReadyAndReturn

CD_Frame2:                          ;Last 2 bytes of Configuration Descriptor
    movlw   DATA1PID                ;DATA0 PID
    movwf   TX_BUFFER

    movlw   INTERPROTOCOL           ;bInterfaceProtocol
    movwf   TX_BUFFER+1

    movlw   INDEXINTER
    movwf   TX_BUFFER+2             ;iInterface

    movlw   0x02
    movwf   COUNT
    call    DoCrc

    movlw   D'5'
    movwf   TX_LEN

    call    InsertStuff

    bcf     PENDING_BYTES,0
    goto    SetReadyAndReturn

GetStatus:
    call    PreInitTXBuffer
    
    movlw   TX_BUFFER+1             ;Initial Address of data
    movwf   FSR

    movlw   0x00                    ;Bus Powered/No RemoteWakeup
    movwf   TX_BUFFER+1
    movwf   TX_BUFFER+2
    
    call    DoCrc

    call    InsertStuff
    goto    SetReadyAndReturn

GetConfiguration:
    call    PreInitTXBuffer

    movlw   TX_BUFFER+1             ;Initial Address of data
    movwf   FSR

    movlw   0x01
    movwf   TX_BUFFER+1

    call    DoCrc

    call    InsertStuff    
    goto    SetReadyAndReturn

GetInterface:
    call    PreInitTXBuffer

    movlw   TX_BUFFER+1             ;Initial Address of data
    movwf   FSR

    clrf    TX_BUFFER+1

    call    DoCrc

    call    InsertStuff
    goto    SetReadyAndReturn

SetAddress:
    movlw   0x08
    movwf   COUNT
    movf    RXDATA_BUFFER+2,W
    movwf   GEN1
    movlw   0x01
    movwf   GEN2
SA_encodeAddrInNrzi:
    btfsc   GEN1,0
    goto    $+3
    movlw   0x01
    xorwf   GEN2,F

    bcf     STATUS,C
    btfsc   GEN2,0
    bsf     STATUS,C
    rrf     NEW_DEVICE_ADDRESS,F
    rrf     GEN1,F
    decfsz  COUNT,F
    goto    SA_encodeAddrInNrzi

    bcf     NEW_DEVICE_ADDRESS,7
    goto    ComposeNullAndReturn

    END