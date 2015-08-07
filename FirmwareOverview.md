# Overview #
The development of such a firmware really isn't a trivial thing, especially taking into account the limitations of a simple microcontroller, such as the PIC16F628/628A, especially with regard to its speed.

A PIC16F628/628A can work with frequencies up to 20MHz. However, each instruction cycle takes four clock cycles. This means that, in fact, with a 20MHz crystal we have our PIC running on 5MHz (20 / 4 = 5). Doing a little overclock, with a 24MHz crystal, we can run programs on 6MHz (or 6Mips). Since the speed of the USB low-speed is 1.5 Mbps, we can obtain a total of four instructions (6 / 4 = 1.5) to treat each bit of data during transfer. That is, each bit of the USB bus takes the time of four instructions of our PIC.

As it's not hard to see, with only four instructions to encode/decode the NRZI, insert/remove the bit stuffing and even check the end of packet (EOP), the work becomes impossible. Fortunately using a few more tricks we can work around this problem, as we shall see.

The default endpoint, EP0, treats every control transfer messages. Although this transfer type is more used to the device setup, we can use it for general purposes too. Additionally, it's possible to use IN and OUT interrupt transfer enabling respectives endpoints on config file (def.inc). Interrupt endpoints are EP1 IN and EP1 OUT.  If you're afraid about using a device driver (libusb in our case), you may enable HID option, write your own Report Descriptor or use the default one.

In general the firmware, which was written in assembly, can be divided into two parts: ISR and MainLoop.

# ISR operations #

  * Waits for data transfer starts with the Sync Pattern;
  * Receives and immediately save the package (still coded and bit stuffing) in an input buffer (RX\_BUFFER);
  * Checks in the address field if the package is really for device;
  * Checks the packet type (Token or Data);
  * If it's a OUT or SETUP token, saves the PID of the package to know the origin of the data that will come in the next packet;
  * Sends acknowledgment packet (ACK) to the host;
  * Sends a non-acknowledgment (NAK) if the device is not free and require a resend later.
  * Copy data in RX\_BUFFER to RXINPUT\_BUFFER;
  * Report MainLoop through ACTION\_FLAG that there are data to be decoded in RXINPUT\_BUFFER;
  * If the packet is an IN Token, verifies through ACTION\_FLAG if the answer is ready, encodes (in NRZI) and sends the entire contents of TX\_BUFFER for control transfers or INT\_TX\_BUFFER for interrupt transfers, that must have been previously prepared (with bit stuff or CRC) for another routine inserted in MainLoop;
  * Set ACTION\_FLAG free when there's no more data to prepare/send;

# Main Loop operations #
  * Checks ACTION\_FLAG and transfers the execution flow to proper treatment;
  * Decodes data in RXINPUT\_BUFFER to RXDATA\_BUFFER;
  * Calls VendorRequest (vendor/class), if it’s not a standard request, and ProcessOut to transfer control for the custom code (functionalities);
  * Calls Main label to transfer control for custom code to do something periodically;
  * Insert bit stuffing and CRC16 on device response (TX\_BUFFER);
  * Take care of all standard requests;