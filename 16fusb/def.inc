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
;    Filename:        const.inc                                       *
;    Date:                                                            *
;    Author:          Emanuel Paz                                     *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Notes:                                                           *
;       Definitions.                                                  *
;                                                                     *
;**********************************************************************
	
    list        p=16F628
    processor   16F628
    errorlevel  -302

    #include    <P16F628.INC>


;====================================================================
;   Device Descriptor values.

    CONSTANT    USBVH               =   0x01    ;bcdUSB
    CONSTANT    USBVL               =   0x10    ;bcdUSB

    CONSTANT    DEVCLASS            =   0xFF    ;bDeviceClass
    CONSTANT    DEVSUBCLASS         =   0x00    ;bDeviceSubClass
    CONSTANT    DEVPROTOCOL         =   0x00    ;bDeviceProtocol

    CONSTANT    VIDH                =   0x04    ;idVendor
    CONSTANT    VIDL                =   0xD8    ;idVendor

    CONSTANT    PIDH                =   0x06    ;idProduct
    CONSTANT    PIDL                =   0x28    ;idProduct

    CONSTANT    DEVICEVH            =   0x01    ;bcdDevice
    CONSTANT    DEVICEVL            =   0x00    ;bcdDevice

    CONSTANT    INDEXMANU           =   0x00    ;iManufacturer
    CONSTANT    INDEXPROD           =   0x00    ;iProduct
    CONSTANT    INDEXSER            =   0x00    ;iSerialNumber

    CONSTANT    NUMCONFIG           =   0x01    ;bNumConfigurations

;====================================================================
;   Configuration Descriptor/Interface Descriptor values

    CONSTANT    CONFIGVAL           =   0x01    ;bConfigurationValue
    CONSTANT    INDEXCONF           =   0x00    ;iConfiguration
    CONSTANT    CONFATTRS           =   0x80    ;bmAttributes
    CONSTANT    MAXPOWER            =   D'100'  ;bMaxPower

    CONSTANT    ALTSETTING          =   0x00    ;bAlternateSetting
    CONSTANT    INTERCLASS          =   0xFF    ;bInterfaceClass
    CONSTANT    INTERSUBCLASS       =   0x00    ;bInterfaceSubClass
    CONSTANT    INTERPROTOCOL       =   0x00    ;bInterfaceProtocol
    CONSTANT    INDEXINTER          =   0x00    ;iInterface

;====================================================================
;   Data and Handshake PID constants.

    CONSTANT    ACKPID              =   0xD2
    CONSTANT    NAKPID              =   0x5A
    CONSTANT    DATA0PID            =   0xC3
    CONSTANT    DATA1PID            =   0x4B
    
;====================================================================
;   NRZI coded Data, Initial address ,Handshake and Token PIDs constants.
;   All values are based in state of D+ after Sync.

    CONSTANT    NRZIDATA0           =   0xEB
    CONSTANT    NRZIDATA1           =   0x93

    CONSTANT    NRZIACKPID          =   0xE4
    CONSTANT    NRZINAKPID          =   0x9C

    CONSTANT    NRZISETUPPID        =   0xB1
    CONSTANT    NRZIINPID           =   0x8D
    CONSTANT    NRZIOUTPID          =   0xF5
    
    CONSTANT    NRZIINITIALADDR     =   0x2A
    
;====================================================================
;   Action Flag definition (state of device).

    CONSTANT    AF_FREE             =   0x90
    CONSTANT    AF_DECODE_DATA      =   0x91
    CONSTANT    AF_PROC_OUT         =   0x92
    CONSTANT    AF_PROC_SETUP       =   0x93
    CONSTANT    AF_TX_BUFF_READY    =   0x94   

;====================================================================
;   Other constants

    CONSTANT    con_a0              =   0xA0
    CONSTANT    con_01              =   0x01
