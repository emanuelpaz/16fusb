;**********************************************************************
;   16FUSB - USB 1.1 implemetation for PIC16F628/628A                 *
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
;    Filename:        action.inc                                      *
;    Date:                                                            *
;    Author:          Emanuel Paz                                     *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Files required:                                                  *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Notes: Here, we can check for some state in whatever we want     *
;           and call the apropiated procedure. This code runs in      *
;           main loop.                                                *
;                                                                     *
;     Example using a state in ACTION_FLAG:                           * 
;	    movlw 	<SOME_STATE>                                  *
;	    subwf 	ACTION_FLAG,W                                 *
;	    btfsc 	STATUS,Z                                      *
;	    call 	<Some_Proc>                                   *
;                                                                     *
;**********************************************************************


