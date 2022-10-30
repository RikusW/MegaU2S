# U2S Settings  
## !!IMPORTANT!! The last 16 bytes eeprom is reserved for the U2S settings  
  
eesel (0x00) is used to select the default startup value.  
Valid values for eesel are:  
0x81 Bootloader  
0x82 ISP programmer  
0x83 JTAGICE mki clone  
0x84 Serial Port  
0x8F Arduino bootloader, you need to have a Sketch loaded first.  
  
0x00 to 0x0F will go to the application and pass along this value.  
  
Bitflags:  
0x80 will enter the bootloader code.  
0x40 will prevent usb setup, don't use with 0x80. Only use it if doing usb\_setup in the application.  
0x20 will prevent the led flashing.  
0x10 will prevent line\_variable init, DON'T set this bit, used when jumping into the bootloader.  
---
eesck (0x01) is the default sck speed during ISP programming.  
This is the same value as used in AVRStudio.  
U2S is using a 8MHz clock so 460KHz is actually 500KHz. eeoscp (0x02) oscillator prescaler value.  
---
eeoscc (0x03) oscillator divider value.  
These are the same values as used in AVRStudio, for the clock generator.  
The clock setup source will explain it best:  
  
SetupEClk: //for Timer0 OC0A  
ldi r16,0  
out TCNT0,r16  
lds r16,oscc  
out OCR0A,r16  
  
ldi r17,0xFF  
lds r16,oscp  
andi r16,7  
brne secon  
ldi r17,0  
secon:  
ori r16,(1&LT &LT WGM02)  
out TCCR0B,r16  
  
andi r17,(1&LT &LT COM0A0)|(1&LT &LT WGM01)|(1&LT &LT WGM00)  
out TCCR0A,r17  
cbi DDRB,7 //OC0A=B7  
breq secoff  
sbi DDRB,7 //OC0A=B7  
secoff:  
ret  
---
eerst (0x04) the reset polarity, 1=AVR 0=AT89, leave at 1.  
---
eesmv (0x05) the STK500 firmware minor version, change this to the proper value to prevent AVRStudio from complaining. (default 0x0A for AS4.18)  
---
eeadl (0x06) the Arduino bootloader timeout = (256-eeadl) * 12800us  
---
This is the assembly code definition of the eeprom variables.  
The last 16 is reserved for bootloader firmware. (0x00 to 0x0F)  
Those marked xx SHOULD NOT be changed.  
These values are directly mapped to parameters 0x90-0x9E. (0x10E-0x11C in SRAM)  
  
.eseg  
.org EEPROMEND-0xF  
eesel:   .db    0x81 // Select default module  
eeshw:   .db    0x02 xx 90 stk HW version  
eesjv:   .db    0x02 xx 91 stk major version  
eesmv:   .db    0x0A // 92 stk minor version  
eeadl:   .db    0xB0 // 93 1s Arduino delay -> (256-eeadl) * 12800us <<====  
eevtg:   .db    51   xx 94 Bootloader VTG  
eevad:   .db    0    xx 95 VAD  
eeoscp:  .db    0x00 // 96 clkgen  
eeoscc:  .db    0x00 // 97 clkgen  
eesck:   .db    0x02 // 98 sck duration 1==125kHz  
ee232:   .db    0x00 // 99 rs232 mode <<====  
ee0A:    .db    0xFF xx 9A topcard  
ee0B:    .db    0xFF xx 9B reserved value <<====  
ee0C:    .db    0x00 xx 9C ?status?  
ee0D:    .db    0xFF xx 9D ?data?  
eerst:   .db    0x01 xx 9E ext rst 1=AVR // fix for avrdude  

