# Bootloader  
The bootloader is in module 0x81 inside the boot section.  
It supports both ISP and HVPP (stk500pp) protocols.  
avrdude must use stk500pp, stk500v2 won't work.  
Pressing the Select button while in this module will execute the application.  
  
The Arduino bootloader is in module 0x8F.  
The first Arduino Sketch must be loaded using module 0x81.  
It basically uses module 0x81 and adds a timeout of about 1 second.  
The Arduino Core will use this module to load the next Sketch,  
or to reset the Sketch when opening the console.  

# Debug Module  
It supports accessing any memory location including register, IO and SRAM.  
  
It has the following commands:  
 - data Read (address )  
 - Write ( address, data )  
 - WriteBit ( address, and\_mask, or\_mask )  
  
This will allow a C program on the PC to access the IO registers on the AVR.  
You'll be able to access AVR registers from within Visual studio as if using AVR Studio and a debugger.  
  
This cannot actually debug a program on the AVR itself.  
  
Look on [here](../U2S_Debug) for template project.  

# JTAGICE mkI+  
The JTAGICE mki is in module 0x83.  
Pressing SELECT will go back to the bootloader.  
There must be a supported AVR connected for it to work.  
The target AVR must be connected __BEFORE__ entering this module.  
 1. Connect the target then the USB cable or,  
 2. Connect the target then select the JTAGICE module.  
  
Supported devices for AVRStudio 4.18: ATmega16(L),  ATmega162(L), ATmega169(L or V), ATmega32(L), ATmega323(L), ATmega64(L), ATmega128(L)  
Now supports new ATmegas too, will need custom PC side software, or a hack modifying data structures in the dll.  
  
The Jtag pinout:  
B0 - Reset  
B1 - TCK  
B2 - TDI  
B3 - TDO  
B7 - TMS  
  
