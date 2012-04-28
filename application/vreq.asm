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
;**********************************************************************	


    #include    "def.inc"

    ;From MAIN_VARIABLES (main.asm) -----------------------------------
    extern      RXDATA_BUFFER

    ;From ISR_VARIABLES (isr.asm) -------------------------------------
    extern      TX_BUFFER

    ;From ISR_SHARED_INTERFACE (isr.asm) ------------------------------
    extern      FRAME_NUMBER

    	
    ;Local labels to export
    global      VendorRequest



VENDOR_REQUEST  CODE

VendorRequest:

    ;Custom code goes here

    return

	END