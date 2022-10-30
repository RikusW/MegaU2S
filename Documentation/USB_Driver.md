# USB Driver
## Installing on Windows 
Give Windows the [32 bit](files/atmegau2\_cdc.inf) or [32/64 bit](files/atmegau2\_cdc\_x64.inf) inf file if not auto installed, it was tested on both 32 and 64 bit Windows.  
It usually will be COM3 or COM4, if not use "Device Manager" to set it to that.  
It will be listed under "Ports (COM & LPT)" as "ATmegaU2 CDC (COMx)" or "Atmel Corp. at90usbkey sample firmware"  
In AVRStudio click on the Con(nect) button and select STK500 and COM3/4.  
AVRStudio 4.18 can use both ISP and HVPP protocols with the bootloader.  
For Atmel/Microchip studio install STK500 first.  
  
## Installing on Linux
Put [atmel.rules](files/atmel.rules) in /etc/udev/rules.d/
In Linux it will automatically be listed as /dev/ttyACM0 (or 1/2/3/4....).  
Avrdude works with the STK500 ISP/HVPP programmer mode. (stk500v2/stk500pp)  
  
To use Avrdude with the bootloader use stk500pp, and NOT stk500v2.  
This is due to Avrdude using SPI\_MULTI and not the proper ISP commands.  
Also apply the [bl32u2\_avrdude\_conf\_patch.txt](files/bl32u2_avrdude_conf_patch.txt) patch.  
This is required when writing to eeprom in bootloader mode.  
  
## A few notes on USB
When resetting the board while an application is connected will cause it to enumerate as the next available com port, close the application first to prevent this.  
  
The builtin bootloader CDC driver is also available from [application code](../Example_Echo_test).  
Use usb\_putc\_nf instead of usb\_putc, flushing byte by byte will slow down USB to about 1kb/s instead of 67kb/s.  
Look inside [U2S firmware](../Firmware/BL32U2) for more details.  
  
When not using interrupt based endpoint 0 handling make sure that usb\_getc or usb\_task is called regularly otherwise usb enumeration will fail.  
  
