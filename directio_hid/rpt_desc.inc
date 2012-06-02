;================================================================
; Edit the Report Descriptor here.


; The example descriptor below defines two vendor defined report: 
; One Input Report and one Output Report of 8 bits size data.
    movf    FRAME_NUMBER,W
    xorlw   0x01
    btfsc   STATUS,Z
    goto    GRD_Frame1

    movf    FRAME_NUMBER,W
    xorlw   0x02
    btfsc   STATUS,Z
    goto    GRD_Frame2

    movf    FRAME_NUMBER,W
    xorlw   0x03
    btfsc   STATUS,Z
    goto    GRD_Frame3

GRD_Frame0:
    movlw   0x06                    ; Usage Page
    movwf   TX_BUFFER+1

    movlw   0xA0                    ; vendor-defined low
    movwf   TX_BUFFER+2

    movlw   0xFF                    ; vendor-defined high
    movwf   TX_BUFFER+3

    movlw   0x09                    ; Usage 
    movwf   TX_BUFFER+4

    movlw   0x01                    ; vendor-defined
    movwf   TX_BUFFER+5

    movlw   0xA1                    ; Collection
    movwf   TX_BUFFER+6

    movlw   0x01                    ; application
    movwf   TX_BUFFER+7

    movlw   0x09                    ; Usage
    movwf   TX_BUFFER+8

    return

GRD_Frame1:
    movlw   0x03                    ; vendor-defined
    movwf   TX_BUFFER+1

    movlw   0x15                    ; Logical Minimum
    movwf   TX_BUFFER+2

    clrf    TX_BUFFER+3             ; 0

    movlw   0x26                    ; Logical Maximum
    movwf   TX_BUFFER+4

    movlw   0xFF                    ; 255
    movwf   TX_BUFFER+5

    clrf   TX_BUFFER+6              ; 0

    movlw   0x75                    ; Report Size
    movwf   TX_BUFFER+7

    movlw   0x08                    ; 8 bits
    movwf   TX_BUFFER+8

    return

GRD_Frame2:
    movlw   0x95                    ; Report Count
    movwf   TX_BUFFER+1

    movlw   0x01                    ; 1 byte
    movwf   TX_BUFFER+2

    movlw   0x81                    ; Input
    movwf   TX_BUFFER+3              

    movlw   0x02                    ; (Data, Variable, Absolute)
    movwf   TX_BUFFER+4

    movlw   0x09                    ; Usage
    movwf   TX_BUFFER+5              

    movlw   0x04
    movwf   TX_BUFFER+6             ; vendor-defined

    movlw   0x91                    ; Output
    movwf   TX_BUFFER+7              

    movlw   0x02                    ; (Data, Variable, Absolute)
    movwf   TX_BUFFER+8
   
    return

GRD_Frame3:
    movlw   0xC0                    ; End Collection
    movwf   TX_BUFFER+1
   
    return