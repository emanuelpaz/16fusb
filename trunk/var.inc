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
;    Filename:        var.inc                                         *
;    Date:                                                            *
;    Author:          Emanuel Paz                                     *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Files required:                                                  *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Notes: General and specific purpose global variables.            *
;                                                                     *
;**********************************************************************


VARIABLES   UDATA_OVR   0x20
W_TMP                   RES     D'1'    ;File to save W.
STATUS_TMP              RES     D'1'    ;File to save STATUS.

TMP                     RES     D'1'    ;General purpose file.
GEN1                    RES     D'1'    ;General purpose file.
GEN2                    RES     D'1'    ;General purpose file.

COUNT                   RES     D'1'    ;Counter file level one.
COUNT2                  RES     D'1'    ;Counter file level two.
COUNT3                  RES     D'1'    ;Counter file level three.

SEEK1                   RES     D'1'    ;Index file level one.
SEEK2                   RES     D'1'    ;Index file level two.

NCHANGE_COUNT           RES     D'1'    ;Number of no change level in NRZI. (bit stuffing)

ACTION_FLAG             RES     D'1'    ;What main loop must do.
LAST_TOKEN_PID          RES     D'1'    ;The last Token PID received.
ADDITIONAL_BITS         RES     D'1'    ;Number of additional bits (stuffing bits) to send.
FRAME_NUMBER            RES     D'1'    ;Frame number of a transaction with data larger than 8 bytes.
PENDING_BYTES           RES     D'1'    ;A bit (0) that signals if there are pending bytes to send.
                                        ;Used in transactions with data larger than 8 bytes.

crcHi                   RES     D'1'    ;High byte of CRC.
crcLo                   RES     D'1'    ;Low byte of CRC.

DEVICE_ADDRESS          RES     D'1'    ;Current device address.
NEW_DEVICE_ADDRESS      RES     D'1'    ;Address designated by host.

TOTAL_LEN               RES     D'1'    ;Saves the number of bytes to transfer in data phase (wLength).

RX_LEN                  RES     D'1'    ;Number of bytes received in RX_BUFFER.
RX_BUFFER               RES     D'13'   ;NRZI data received from host, with bit stuffing.

RXDATA_LEN              RES     D'1'    ;Number of received bytes decoded.
RXDATA_BUFFER           RES     D'10'   ;Received bytes decoded.

TX_LEN                  RES     D'1'    ;Number of bytes to send in TX_BUFFER.
TX_BUFFER               RES     D'13'   ;Tranmission Buffer. Contains data (not coded) to send.
