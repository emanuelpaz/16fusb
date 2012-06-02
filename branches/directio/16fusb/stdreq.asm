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

    ; Local labels to export
    global  GetDescriptor
    global  GetStatus
    global  GetConfiguration
    global  GetInterface
    global  SetAddress

    ; (usb.asm)
    extern  RXDATA_BUFFER

    ; (isr.asm)
    extern  TX_BUFFER
#if INTERRUPT_OUT_ENDPOINT == 1
    extern  RXINPUT_BUFFER
#endif
    extern  FRAME_NUMBER
    extern  DEVICE_ADDRESS
    extern  NEW_DEVICE_ADDRESS


LOCAL_OVERLAY   UDATA_OVR   0x4A+(INTERRUPT_IN_ENDPOINT*D'16')+(INTERRUPT_OUT_ENDPOINT*D'14')

COUNT               RES     D'1'        ; Counter
GEN                 RES     D'1'        ; General
GEN2                RES     D'1'        ; General
#if INTERRUPT_OUT_ENDPOINT == 0
                    RES     D'6'        ; Space reserved just to get RXINPUT_BUFFER below
RXINPUT_BUFFER      RES     D'13'       ; Copy of RX_BUFFER
#endif


CONFIG_TOTAL_LEN    EQU (D'9'+D'9'+(INTERRUPT_IN_ENDPOINT*D'7')+(INTERRUPT_OUT_ENDPOINT*D'7')+(HID*D'9'))

cd_frm_index        =   3
tx_offset           =   3
additional_frames   =   HID + INTERRUPT_IN_ENDPOINT + INTERRUPT_OUT_ENDPOINT


cd_verify_end   macro
#if tx_offset == 8
    return
GCD_Frame#v(cd_frm_index):
cd_frm_index += 1
tx_offset = 0
#endif
    endm

; EP1 IN Macro
int_ep_in  macro
    movlw   D'7'
    movwf   TX_BUFFER+tx_offset     ; bLength
    cd_verify_end
tx_offset+=1;
    movlw   0x05
    movwf   TX_BUFFER+tx_offset     ; bDescriptorType
    cd_verify_end
tx_offset+=1;
    movlw   0x81
    movwf   TX_BUFFER+tx_offset     ; bEndPointAddress
    cd_verify_end
tx_offset+=1;
    movlw   0x03
    movwf   TX_BUFFER+tx_offset     ; bmAttributes
    cd_verify_end
tx_offset+=1;
    movlw   0x08
    movwf   TX_BUFFER+tx_offset     ; wMaxPacketSize low
    cd_verify_end
tx_offset+=1;
    movlw   0x00
    movwf   TX_BUFFER+tx_offset     ; wMaxPacketSize high
    cd_verify_end
tx_offset+=1;
    movlw   INT_EP_IN_INTERVAL
    movwf   TX_BUFFER+tx_offset     ; bInterval
    cd_verify_end
tx_offset+=1;
    endm

; EP1 OUT Macro
int_ep_out  macro 
    movlw   D'7'
    movwf   TX_BUFFER+tx_offset     ;bLength
    cd_verify_end
tx_offset+=1;
    movlw   0x05
    movwf   TX_BUFFER+tx_offset     ;bDescriptorType
    cd_verify_end
tx_offset+=1;
    movlw   0x01
    movwf   TX_BUFFER+tx_offset     ;bEndPointAddress
    cd_verify_end
tx_offset+=1;
    movlw   0x03
    movwf   TX_BUFFER+tx_offset     ;bmAttributes
    cd_verify_end
tx_offset+=1;    
    movlw   0x08
    movwf   TX_BUFFER+tx_offset     ;wMaxPacketSize low
    cd_verify_end
tx_offset+=1;
    movlw   0x00
    movwf   TX_BUFFER+tx_offset     ;wMaxPacketSize high
    cd_verify_end
tx_offset+=1;
    movlw   INT_EP_OUT_INTERVAL
    movwf   TX_BUFFER+tx_offset     ;bInterval
    cd_verify_end
tx_offset+=1;
    endm



STANDARD_REQUEST    CODE

GetDescriptor:
; Check for Get Device Descriptor
    movf    RXDATA_BUFFER+3,W
    xorlw   DESCRIPTOR_TYPE_DEVICE
    btfsc   STATUS,Z
    goto    GetDeviceDescriptor
; Check for Get Configuration Descriptor
    movf    RXDATA_BUFFER+3,W
    xorlw   DESCRIPTOR_TYPE_CONFIGURATION
    btfsc   STATUS,Z
    goto    GetConfigurationDescriptor

    return

GetDeviceDescriptor:
    movf    FRAME_NUMBER,W
    xorlw   0x01
    btfsc   STATUS,Z
    goto    GDD_Frame1

    movf    FRAME_NUMBER,W
    xorlw   0x02
    btfsc   STATUS,Z
    goto    GDD_Frame2

GDD_Frame0:                             ; first 8 bytes of Device Descriptor
    movlw   D'18'                       ; bLength
    movwf   TX_BUFFER+1

    movlw   DESCRIPTOR_TYPE_DEVICE      ; bDescriptorType
    movwf   TX_BUFFER+2

    movlw   0x10                        ; bcdUSB MN
    movwf   TX_BUFFER+3
    movlw   0x01                        ; bcdUSB JJ
    movwf   TX_BUFFER+4

    movlw   DEVICE_CLASS                ; bDeviceClass
    movwf   TX_BUFFER+5

#ifdef  DEVICE_SUB_CLASS                ; bDeviceSubClass
    movlw   DEVICE_SUB_CLASS
    movwf   TX_BUFFER+6
#else
    clrf    TX_BUFFER+6
#endif

#ifdef  DEVICE_PROTOCOL                 ; bDeviceProtocol
    movlw   DEVICE_PROTOCOL
    movwf   TX_BUFFER+7
#else
    clrf    TX_BUFFER+7
#endif

    movlw   0x08                        ; bMaxPacketSize
    movwf   TX_BUFFER+8

    return

GDD_Frame1:                             ; second 8 bytes of Device Descriptor
    movlw   DEVICE_VENDOR_ID_LOW        ; idVendor low
    movwf   TX_BUFFER+1
    movlw   DEVICE_VENDOR_ID_HIGH       ; idVendor high
    movwf   TX_BUFFER+2

    movlw   DEVICE_ID_LOW               ; idProduct low
    movwf   TX_BUFFER+3
    movlw   DEVICE_ID_HIGH              ; idProduct high
    movwf   TX_BUFFER+4

    movlw   DEVICE_VERSION_LOW          ; bcdDevice low
    movwf   TX_BUFFER+5
    movlw   DEVICE_VERSION_HIGH         ; bcdDevice high
    movwf   TX_BUFFER+6

#ifdef  VENDOR_NAME_INDEX               ; iManufacturer
    movlw   VENDOR_NAME_INDEX           
    movwf   TX_BUFFER+7
#else
    clrf    TX_BUFFER+7                 
#endif

#ifdef  DEVICE_NAME_INDEX               ; iProduct
    movlw   DEVICE_NAME_INDEX
    movwf   TX_BUFFER+8
#else
    clrf    TX_BUFFER+8
#endif               
   
    return

GDD_Frame2:                             ; last 2 bytes of Device Descriptor
#ifdef  SERIAL_INDEX                                     
    movlw   SERIAL_INDEX                ; iSerialNumber
    movwf   TX_BUFFER+1
#else
    clrf    TX_BUFFER+1
#endif    

    movlw   0x01                        ; bNumConfigurations
    movwf   TX_BUFFER+2

    return

GetConfigurationDescriptor:
    movf    FRAME_NUMBER,W
    xorlw   0x01
    btfsc   STATUS,Z
    goto    GCD_Frame1

    movf    FRAME_NUMBER,W
    xorlw   0x02
    btfsc   STATUS,Z
    goto    GCD_Frame2

    while  additional_frames > 0
    movf    FRAME_NUMBER,W
    xorlw   #v(additional_frames+2)
    btfsc   STATUS,Z
    goto    GCD_Frame#v(additional_frames+2)
additional_frames-=1
    endw

GCD_Frame0:                                 ; first 8 bytes of Configuration Descriptor
    movlw   D'9'                            ; bLength
    movwf   TX_BUFFER+1

    movlw   DESCRIPTOR_TYPE_CONFIGURATION   ; bDescriptorType
    movwf   TX_BUFFER+2

    movlw   CONFIG_TOTAL_LEN                ; wTotalLenght L
    movwf   TX_BUFFER+3                       
    clrf    TX_BUFFER+4                     ; wTotalLenght H

    movlw   0x01
    movwf   TX_BUFFER+5                     ; bNumInterfaces                          
    movwf   TX_BUFFER+6                     ; bConfigurationValue
    clrf    TX_BUFFER+7                     ; iConfiguration

#if DEVICE_MAX_POWER == 0                   ; bmAttributes
    movlw   0xC0
#else
    movlw   0x80
#endif
    movwf   TX_BUFFER+8

    return

GCD_Frame1:                             ; second 8 bytes of Configuration Descriptor
    movlw   ((DEVICE_MAX_POWER+1)/2)    ; bMaxPower
    movwf   TX_BUFFER+1

    movlw   D'9'                        ; bLength
    movwf   TX_BUFFER+2

    movlw   DESCRIPTOR_TYPE_INTERFACE   ; bDescriptorType
    movwf   TX_BUFFER+3

    clrf    TX_BUFFER+4                 ; bInterfaceNumber
    clrf    TX_BUFFER+5                 ; bAlternateSetting

    movlw   INTERRUPT_IN_ENDPOINT+INTERRUPT_OUT_ENDPOINT
    movwf   TX_BUFFER+6                 ; bNumEndPoints

#if HID == 0
    movlw   INTERFACE_CLASS    
#else 
    movlw   HID_INTERFACE_CLASS
#endif
    movwf   TX_BUFFER+7                 ; bInterfaceClass

#ifdef  INTERFACE_SUB_CLASS             ; bInterfaceSubClass
    movlw   INTERFACE_SUB_CLASS
    movwf   TX_BUFFER+8
#else
    clrf    TX_BUFFER+8
#endif

    return

GCD_Frame2:                             ; last 2 bytes of Configuration Descriptor
#ifdef  INTERFACE_PROTOCOL              ; bInterfaceProtocol
    movlw   INTERFACE_PROTOCOL                   
    movwf   TX_BUFFER+1
#else
    clrf    TX_BUFFER+1
#endif

#ifdef  INTERFACE_NAME_INDEX            ; iInterface
    movlw   INTERFACE_NAME_INDEX
    movwf   TX_BUFFER+2
#else
    clrf    TX_BUFFER+2
#endif


#if HID == 1
    movlw   D'9'
    movwf   TX_BUFFER+3                 ; bLength

    movlw   DESCRIPTOR_TYPE_HID         ; bDescriptorType
    movwf   TX_BUFFER+4

    movlw   0x10                        ; bcdHID low
    movwf   TX_BUFFER+5

    movlw   0x01                        ; bcdHID high
    movwf   TX_BUFFER+6

    clrf    TX_BUFFER+7                 ; bCountryCode

    movwf   TX_BUFFER+8                 ; bNumDescriptors

    return

GCD_Frame3:
    movlw   DESCRIPTOR_TYPE_REPORT      ; bDescriptorType
    movwf   TX_BUFFER+1

    movlw   HID_REPORT_SIZE             ; wDescriptorLength low
    movwf   TX_BUFFER+2

    clrf    TX_BUFFER+3                 ; wDescriptorLength high

tx_offset = 4
cd_frm_index += 1

#endif

#if INTERRUPT_IN_ENDPOINT == 1
    int_ep_in
#endif

#if INTERRUPT_OUT_ENDPOINT == 1
    int_ep_out
#endif

    return

GetStatus:
#if DEVICE_MAX_POWER == 0
    movlw   0x01
    movwf   TX_BUFFER+1                 ; self Powered
#else
    clrf    TX_BUFFER+1                 ; bus Powered
#endif

    clrf    TX_BUFFER+2                 ; no remote wakeup

    return

GetConfiguration:
    movlw   0x01
    movwf   TX_BUFFER+1

    return

GetInterface:
    clrf    TX_BUFFER+1

    return

SetAddress:
    movf    RXINPUT_BUFFER+3,W
    movwf   NEW_DEVICE_ADDRESS
    bcf     NEW_DEVICE_ADDRESS,7

    return

    END