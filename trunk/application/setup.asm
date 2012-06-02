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
;    Filename:        setup.asm                                       *
;    Date:                                                            *
;    Author:          Emanuel Paz                                     *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Notes: All vendor/class of control transfer requests goes here.  *
;                                                                     *
;**********************************************************************	

    #include    "def.inc"

    ; Local labels to export
    global  VendorRequest
#if HID == 1
    global  GetReportDescriptor
#endif

    ; (usb.asm)
    extern  RXDATA_BUFFER
    extern  RXDATA_LEN

    ; (isr.asm)
    extern  TX_BUFFER
    extern  FRAME_NUMBER
    extern  ACTION_FLAG
#if INTERRUPT_IN_ENDPOINT == 1
    extern  INT_TX_BUFFER
    extern  INT_TX_LEN
    ; (usb.asm)
    extern  PrepareIntTxBuffer
#endif


LOCAL_OVERLAY   UDATA_OVR   0x4A+(INTERRUPT_IN_ENDPOINT*D'16')+(INTERRUPT_OUT_ENDPOINT*D'14')

    ; Local temporary variables goes here



VENDOR_REQUEST    CODE

VendorRequest:

    ; Custom code goes here

    return


#if HID == 1
GetReportDescriptor:
    #include rpt_desc.inc
#endif

	END