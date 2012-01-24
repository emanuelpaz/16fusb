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
;    Filename:        vreq.asm                                        *
;    Date:                                                            *
;    Author:          Emanuel Paz                                     *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Files required: header.inc, cvar.inc                             *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Notes: All custom (vendor) requests goes here.                   *
;                                                                     *
;**********************************************************************	


    include     "header.inc"
    include     "cvar.inc"
	
    global      VendorRequest

    extern      SetFreeAndReturn, SetReadyAndReturn, ComposeNullAndReturn
    extern      PreInitTXBuffer, DoCrc, InsertStuff

VENDOR_REQUEST  CODE

VendorRequest:

    ;DirectIO implementation
    include "dio.inc"

	END