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
;   Filename:      stdreq.asm                                         *
;   Date:                                                             *
;   Author:        Emanuel Paz                                        *
;                                                                     *
;**********************************************************************
;                                                                     *
;   Notes: Implementation of all mandatory standard requests          *
;          required by USB 1.1 specification.                         *
;                                                                     *
;**********************************************************************


   #include     "def.inc"

    ;From MAIN_VARIABLES (main.asm) -----------------------------------
    extern      RXDATA_BUFFER

    ;From ISR_VARIABLES (isr.asm) -------------------------------------
    extern      TX_BUFFER

    ;From ISR_SHARED_INTERFACE (isr.asm) ------------------------------
    extern      FRAME_NUMBER, DEVICE_ADDRESS, NEW_DEVICE_ADDRESS



LOCAL_OVERLAY           UDATA_OVR   0x4F

COUNT                   RES     D'1'    ;Counter file
GEN                     RES     D'1'    ;General purpose file
GEN2                    RES     D'1'    ;General purpose file

    global     GetDescriptor, GetStatus, GetConfiguration
    global     GetInterface, SetAddress



STANDARD_REQUEST   CODE

GetDescriptor:
    movf    RXDATA_BUFFER+3,W
    sublw   0x01
    btfsc   STATUS,Z
    goto    GetDeviceDescriptor

    movf    RXDATA_BUFFER+3,W
    sublw   0x02
    btfsc   STATUS,Z
    goto    GetConfigDescriptor

    return

GetDeviceDescriptor:
    movlw   0x01
    subwf   FRAME_NUMBER,W
    btfsc   STATUS,Z
    goto    GDD_Frame1
    movlw   0x02
    subwf   FRAME_NUMBER,W
    btfsc   STATUS,Z
    goto    GDD_Frame2

GDD_Frame0:                         ;First 8 bytes of Device Descriptor
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

    return

GDD_Frame1:                         ;Second 8 bytes of Device Descriptor
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
   
    return

GDD_Frame2:                         ;Last 2 bytes of Device Descriptor
    movlw   DATA1PID                ;DATA1 PID
    movwf   TX_BUFFER

    movlw   INDEXSER                ;iSerialNumber
    movwf   TX_BUFFER+1

    movlw   NUMCONFIG               ;bNumConfigurations
    movwf   TX_BUFFER+2

    return

GetConfigDescriptor:
    movlw   0x01
    subwf   FRAME_NUMBER,W
    btfsc   STATUS,Z
    goto    GCD_Frame1
    movlw   0x02
    subwf   FRAME_NUMBER,W
    btfsc   STATUS,Z
    goto    GCD_Frame2

GCD_Frame0:                         ;First 8 bytes of Configuration Descriptor
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

    return

GCD_Frame1:                         ;Second 8 bytes of Configuration Descriptor
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

    return

GCD_Frame2:                         ;Last 2 bytes of Configuration Descriptor
    movlw   DATA1PID                ;DATA0 PID
    movwf   TX_BUFFER

    movlw   INTERPROTOCOL           ;bInterfaceProtocol
    movwf   TX_BUFFER+1

    movlw   INDEXINTER
    movwf   TX_BUFFER+2             ;iInterface

    return

GetStatus:
    movlw   0x00                    ;Bus Powered/No RemoteWakeup
    movwf   TX_BUFFER+1
    movwf   TX_BUFFER+2

    return

GetConfiguration:
    movlw   0x01
    movwf   TX_BUFFER+1

    return

GetInterface:
    clrf    TX_BUFFER+1

    return

SetAddress:
    movlw   0x08
    movwf   COUNT
    movf    RXDATA_BUFFER+2,W
    movwf   GEN
    movlw   0x01
    movwf   GEN2
SA_encodeAddrInNrzi:
    btfsc   GEN,0
    goto    $+3
    movlw   0x01
    xorwf   GEN2,F

    bcf     STATUS,C
    btfsc   GEN2,0
    bsf     STATUS,C
    rrf     NEW_DEVICE_ADDRESS,F
    rrf     GEN,F
    decfsz  COUNT,F
    goto    SA_encodeAddrInNrzi
    bcf     NEW_DEVICE_ADDRESS,7

    return

    END