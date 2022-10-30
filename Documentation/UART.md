# UART  
The UART is in module 0x84.  
Pressing SELECT will go back to the bootloader.  
Look in ATmega8U2/16U2/32U2 for the USART pinout on PORTD.  
  
By default standard baudrates will be used but special USART settings can be used, by changing ee232.  
Unfortunately RTS and CTS are not available in the CDC ACM spec and cannot be accessed from PC software.  
  
UART Pinout:  
  
D0 - I   DCD  
D1 - I   RI  
D2 - I   RX  
D3 - O TX  
D4 - O DTR  
D5 - I   DSR  
D6 - O RTS  Done in hardware on ATmega32U2  
D7 - I   CTS  Done in hardware on ATmega32U2  
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
  
