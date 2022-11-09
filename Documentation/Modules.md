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
  
Look on [here](../Applications/U2S_Debug) for template project.  

# STK500
The [STK500](STK500.md) is in module 0x82

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
  
# UART  
The UART is in module 0x84.  
Pressing SELECT will go back to the bootloader.  
Look in ATmega8U2/16U2/32U2 for the USART pinout on PORTD.  
  
By default standard baudrates will be used but special USART settings can be used, by changing ee232.  
Unfortunately RTS and CTS are not available in the CDC ACM spec and cannot be accessed from PC software.  
  
UART Pinout:  
  
D0 - I DCD  
D1 - I RI  
D2 - I RX  
D3 - O TX  
D4 - O DTR  
D5 - I DSR  
D6 - O RTS  Done in hardware on ATmega32U2  
D7 - I CTS  Done in hardware on ATmega32U2  
Pullups are on and DTR is high by default. (PORTD = 0xB7  DDRD = 0x58)  
  
Parameter ee232 in U2Settings.asm bit meanings:  
  
Bit0 non standard baud will be enabled. (This can be saved in eeprom.)  
   115200 will become 125000, all bauds will be scaled by the same amount. (Baud * 1.085)  
  
Bit1 will override the UBRR setting.  
   (This could be saved in eeprom but changing 04/05 in eeprom will interfere with STK500 operation.)  
   Low byte of UBRR in parameter 0x94 and high byte in 0x95.  
   
Bit2 will enable hardware flow control. (This can be saved in eeprom.)  
   This will use the AVR USART RTS/CTS flow control lines, but RTS/CTS is not accessible from PC software...  
  
Bit3 will entirely override USART setup.  
   Use Debug mode to change the registers to anything you like, before changing to UART mode.  
   This bit must be set in eeprom then use SetMode(0x80); <setup USART registers> SetMode(0x84);  
   (Changing modes resets the variable in ram so eeprom must be used for storing ee232 unfortunately.)  
  
It is much easier to simply use the new U2S\_GUI to change these modes.  
  
