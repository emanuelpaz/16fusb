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
;    Filename:        init.asm                                        *
;    Date:                                                            *
;    Author:          Emanuel Paz                                     *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Notes: Anything to do after the processor reset and before       *
;           accepting interrupts goes here.                           *
;                                                                     *
;**********************************************************************

    #include    "def.inc"

    global      InitSetup



INIT_SETUP     CODE

InitSetup:

    ;by DirectIO module    
    bcf     T1CON,T1OSCEN
    movlw   B'00000111'
    movwf   CMCON
    clrf    CCP1CON

    clrf    PORTA
    clrf    PORTB
    
    return

    END
	