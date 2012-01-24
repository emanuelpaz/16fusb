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
;    Filename:        out.asm                                         *
;    Date:                                                            *
;    Author:          Emanuel Paz                                     *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Files required: header.inc, cvar.inc                             *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Notes: The function ProcessOut in this file can be treated as    *
;           a callback for Out packages sended by Host.               *
;                                                                     *
;**********************************************************************


    include     "header.inc"
    include     "cvar.inc"    
    
    global      ProcessOut

    extern      SetFreeAndReturn, SetReadyAndReturn, ComposeNullAndReturn
    extern      PreInitTXBuffer, DoCrc, InsertStuff

PROCESS_OUT     CODE
ProcessOut:

    
    goto    SetFreeAndReturn

    END