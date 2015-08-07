# Driver #

For communication between a USB device and the host computer, obviously, we need an application and a driver on the operating system to interface with this device. In the 16FUSB case, the driver used for both Windows and Linux is the libusb. The libusb is a driver/library that provides access to USB devices for user-level applications. With libusb is possible to exchange messages between your application and the USB hardware without the need to write a specific driver for your device. Its API is very straightforward and easy to use. Don't miss http://www.libusb.org/  to understand more about the project.<br><br>


<h3>Windows environment</h3>

<h4>For both runtime and development environment:</h4>
<ul><li><b>Download the 16FUSB device driver:</b> <br><a href='http://16fusb.googlecode.com/files/16FUSB_driver-libusb-win32-1.2.6.0.zip'>http://16fusb.googlecode.com/files/16FUSB_driver-libusb-win32-1.2.6.0.zip</a><br></li></ul>

<ul><li><b>Install the device driver:</b> <br>Press <b>Win+R</b>, type <b>'hdwwiz'</b> and click <b>'Next'</b>. Choose <b>'Install the hardware that I manually select form a list (Advanced)'</b> and click <b>'Next'</b> again. Just leave the option <b>'Show All Devices'</b> and go <b>'Next'</b> button. Click <b>'Have Disk'</b> button and browse to the folder you extracted the driver then choose <b>'16FUSB'</b> and click <b>'Next'</b>. Windows will warn you about driver verification. Choose <b>'Install Driver Anyway'</b> to authorize driver install. Click on the <b>'Finish'</b> to close the wizard.<br></li></ul>

<h4>For development environment only:</h4>

<ul><li>Copy the include file 'lusb0_usb.h' (found in the device driver package) into the Microsoft SDK's include directory.<br>
</li><li>Copy the file 'libusb.lib' (also found in the device driver package) into Microsoft SDK's lib directory or into your IDE lib directory.<br>
</li><li>Install the filter driver <a href='http://sourceforge.net/projects/libusb-win32/files/libusb-win32-releases/'>libusb -win32-filter-devel-xxxx.exe</a>. The version of the filter driver must match the version of device driver. This step is optional.