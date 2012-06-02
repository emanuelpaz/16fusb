    #include    "../16fusb/def.inc"

;---------------------------------------------------------------------
; Device Descriptor values.

;DEVICE_VENDOR_ID_HIGH  SET     0x04    ; idVendor
;DEVICE_VENDOR_ID_LOW   SET     0xD8    ; idVendor
;DEVICE_ID_HIGH         SET     0x06    ; idProduct
;DEVICE_ID_LOW          SET     0x28    ; idProduct

;DEVICE_VERSION_HIGH    SET     0x01    ; bcdDevice
;DEVICE_VERSION_LOW     SET     0x00    ; bcdDevice

;DEVICE_CLASS           SET     0xFF    ; bDeviceClass
;DEVICE_SUB_CLASS       SET     0x00    ; bDeviceSubClass
;DEVICE_PROTOCOL        SET     0x00    ; bDeviceProtocol
;VENDOR_NAME_INDEX      SET     0x00    ; iManufacturer
;DEVICE_NAME_INDEX      SET     0x00    ; iProduct
;SERIAL_INDEX           SET     0x00    ; iSerialNumber

;---------------------------------------------------------------------
; Configuration Descriptor/Interface Descriptor values

; Max power (mA) drained by device from the bus. Set it to zero
; if device is self powered.
;DEVICE_MAX_POWER       SET     D'100'      ; bMaxPower

;INTERFACE_CLASS        SET     0xFF        ; bInterfaceClass
;INTERFACE_SUB_CLASS    SET     0x00        ; bInterfaceSubClass
;INTERFACE_PROTOCOL     SET     0x00        ; bInterfaceProtocol
;INTERFACE_NAME_INDEX   SET     0x00        ; iInterface

;---------------------------------------------------------------------
; Interrupt endpoints.

;INTERRUPT_IN_ENDPOINT       SET     1       ; comment out to enable IN endpoint.
;INT_EP_IN_INTERVAL          SET     0x08    ; IN endpoint bInterval

;INTERRUPT_OUT_ENDPOINT      SET     1       ; comment out to enable OUT endpoint.
;INT_EP_OUT_INTERVAL         SET     0x08    ; OUT endpoint bInterval

;---------------------------------------------------------------------
; HID Interface 
;  INTERRUPT_IN_ENDPOINT shall be enabled.
;  INTERRUPT_OUT_ENDPOINT enabled is optional.

;HID                        SET      1       ; comment out to enable HID interface.
;HID_REPORT_SIZE            SET      D'25'   ; set the HID Report Descriptor size here.