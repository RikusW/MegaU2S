# USB Driver  
## Installing the driver and connecting  
Give Windows the atmegau2\_cdc\_x64.inf when installing the device, it should work on both 32 and 64 bit Windows.  
  
It usually will be COM3 or COM4, if not use "Device Manager" to set it to that.  
It will be listed under "Ports (COM & LPT)" as "ATmegaU2 CDC (COMx)"  
In AVRStudio click on the Con(nect) button and select STK500 and COM3/4.  
AVRStudio 4.18 can use both ISP and HVPP protocols with the bootloader.  
  
In Linux it will automatically be listed as /dev/ttyACM0 (or 1/2/3/4....).  
Avrdude works with the STK500 ISP/HVPP programmer mode. (stk500v2/stk500pp)  
  
To use Avrdude with the bootloader use stk500pp, and NOT stk500v2.  
This is due to Avrdude using SPI\_MULTI and not the proper ISP commands.  
Also apply the avrdude.conf patch on the Supporting Software page,  
this is required when writing to eeprom in bootloader mode.  
  
## A few notes on USB  
When resetting the board while an application is connected will cause it to enumerate as the next available com port. Close the application first to prevent this.  
  
Use usb\_putc\_nf instead of usb\_putc, flushing byte by byte will slow down USB to about 1kb/s instead of 67kb/s. (Look inside Supporting Software U2Sfw for more details.)  
  
When not using interrupt based endpoint 0 handling make sure that usb\_getc or usb\_task is called regularly otherwise usb enumeration will fail.  
  
