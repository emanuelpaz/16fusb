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
;    Filename:        def.inc                                         *
;    Date:                                                            *
;    Author:          Emanuel Paz                                     *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Notes: Default definitions. Do not edit! Edit "def.inc" in       *
;           application directory instead.                            *
;                                                                     *
;                                                                     *
;**********************************************************************
	
    list        p=16F628
    processor   16F628
    errorlevel  -302

    #include    <P16F628.INC>


;====================================================================
;   The port and pins below cannot be reassigned. Don't change it.
;   These 'defines' are just for a better readability of the code.

#define USB_PORT    PORTB
#define USB_DPLUS   PORTB,0
#define USB_DMINUS  PORTB,1
#define USB_EOPCHK  PORTB,2

;====================================================================
;   ActionFlag definition (state of device).

#define AF_BIT_BUSY             ACTION_FLAG,0   ; Busy (bit 0): 0=free; 1=busy
#define AF_BIT_DECODING         ACTION_FLAG,1   ; Mode (bit 1): 0=processing; 1=decoding
#define AF_BIT_INTERRUPT        ACTION_FLAG,2   ; Transfer type (bit 2): 0=control; 1=interrupt
#define AF_BIT_PEND_BYTES       ACTION_FLAG,3   ; Pending Bytes (bit 3): 0=no pending; 1=pending
#define AF_BIT_INT_TX_READY     ACTION_FLAG,5
#define AF_BIT_TX_READY         ACTION_FLAG,6
#define AF_BIT_PID_OUT          ACTION_FLAG,7   ; PID (bit 7): 0=SETUP; 1=OUT

;====================================================================
;   Descriptors constant values.
    
    CONSTANT    DESCRIPTOR_TYPE_DEVICE          =   0x01
    CONSTANT    DESCRIPTOR_TYPE_CONFIGURATION   =   0x02
	CONSTANT    DESCRIPTOR_TYPE_STRING          =   0x03
	CONSTANT    DESCRIPTOR_TYPE_INTERFACE       =   0x04
	CONSTANT    DESCRIPTOR_TYPE_ENDPOINT        =   0x05

    CONSTANT    DESCRIPTOR_TYPE_HID             =   0x21
    CONSTANT    DESCRIPTOR_TYPE_REPORT          =   0x22

;====================================================================
;   Standard request constant values.

    CONSTANT    CLEAR_FEATURE		            =   0x01
    CONSTANT    GET_CONFIGURATION	            =   0x08
    CONSTANT    GET_DESCRIPTOR		            =   0x06
    CONSTANT    GET_INTERFACE		            =   0x0A
    CONSTANT    GET_STATUS		                =   0x00
    CONSTANT    SET_ADDRESS		                =   0x05
    CONSTANT    SET_CONFIGURATION	            =   0x09
    CONSTANT    SET_FEATURE		                =   0x03
    CONSTANT    SET_INTERFACE		            =   0x0B

;====================================================================
;   Data and Handshake PID constants.

    CONSTANT    USB_PID_ACK                     =   0xD2
    CONSTANT    USB_PID_NAK                     =   0x5A

    CONSTANT    USB_PID_DATA0                   =   0xC3
    CONSTANT    USB_PID_DATA1                   =   0x4B

;====================================================================
;   NRZI coded Data, Initial address ,Handshake and Token PIDs constants.
;   All values are based in state of D+ after Sync.

    CONSTANT    USB_NRZI_ZERO_ADDR              =   0x2A
    CONSTANT    USB_NRZI_PID_DATA0              =   0xEB
    CONSTANT    USB_NRZI_PID_DATA1              =   0x93
    CONSTANT    USB_NRZI_PID_ACK                =   0xE4
    CONSTANT    USB_NRZI_PID_NAK                =   0x9C
    CONSTANT    USB_NRZI_PID_SETUP              =   0xB1
    CONSTANT    USB_NRZI_PID_IN                 =   0x8D
    CONSTANT    USB_NRZI_PID_OUT                =   0xF5

;====================================================================
;   Other constants

    CONSTANT    HID_INTERFACE_CLASS             =   0x03

    CONSTANT    con_a0                          =   0xA0
    CONSTANT    con_01                          =   0x01    

;====================================================================
; Device Descriptor default values.

DEVICE_CLASS            SET     0xFF        ; bDeviceClass

DEVICE_VENDOR_ID_HIGH   SET     0x04        ; idVendor
DEVICE_VENDOR_ID_LOW    SET     0xD8        ; idVendor

DEVICE_ID_HIGH          SET     0x06        ; idProduct
DEVICE_ID_LOW           SET     0x28        ; idProduct

DEVICE_VERSION_HIGH     SET     0x01        ; bcdDevice
DEVICE_VERSION_LOW      SET     0x00        ; bcdDevice


;====================================================================
; Configuration Descriptor/Interface Descriptor default values.

DEVICE_MAX_POWER        SET     D'100'      ; bMaxPower
INTERFACE_CLASS         SET     0xFF        ; bInterfaceClass

;====================================================================
; Interrupt endpoints defaults (disabled).

INTERRUPT_IN_ENDPOINT   SET     0
INT_EP_IN_INTERVAL      SET     0x08        ; IN endpoint bInterval

INTERRUPT_OUT_ENDPOINT  SET     0
INT_EP_OUT_INTERVAL     SET     0x08        ; OUT endpoint bInterval

;---------------------------------------------------------------------
; HID Interface

HID                     SET     0


    


    





