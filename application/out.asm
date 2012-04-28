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
;    Filename:        out.asm                                         *
;    Date:                                                            *
;    Author:          Emanuel Paz                                     *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Notes: The function ProcessOut in this file can be treated as    *
;           a callback for Out packages sended by Host.               *
;                                                                     *
;**********************************************************************


    #include     "def.inc"

    ;From MAIN_VARIABLES (main.asm) -----------------------------------
    extern      RXDATA_BUFFER

    ;Local labels to export
    global      ProcessOut



PROCESS_OUT     CODE

ProcessOut:
    
    ;Custom code goes here
    
    return
    
    END