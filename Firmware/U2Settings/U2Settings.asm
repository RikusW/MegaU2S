
#include <m32U2def.inc>

//-------------------------------------
.eseg
.org EEPROMEND-0xF

//(0x80 - bl mode) (0x40 no usb_setup - don't combine with 0x80) 0x20 no led flashing) (0x10 no var init - don't use)
//0x81 Bootloader
//0x82 STK500
//0x83 JTAGICE mkI
//0x84 UART
//0x85 debugWire - not finished

//0x01 App
//0x41 App No USB

//ee0B bit0 HVSP_Leave power 1-on / 0-off

eesel:	 .db	0x84 //c xx sel

eeshw:	 .db	0x02 //x 00 stk HW version
eesjv:	 .db	0x02 //x 01 stk major version
eesmv:	 .db	0x0A //c 02 stk minor version
eeadl:   .db	0xB0 //c 03 1s Arduino delay -> (256-eeadl) * 12800us <<====
eevtg:   .db	48   //x 04 VTG
eevad:   .db	0    //x 05 VAD
eeoscp:	 .db	0x00 //c 06 clkgen
eeoscc:	 .db	0x00 //c 07 clkgen
eesck:	 .db	0x02 //c 08 sck duration 1==125kHz
ee232:   .db	0x00 //c 09 rs232 mode <<====
ee0A:    .db	0xFF //x 0A topcard
ee0B:    .db	0xFE //x 0B reserved value <<====
ee0C:    .db	0x00 //x 0C ?status?
ee0D:    .db	0xFF //x 0D ?data?
eerst:   .db	0x01 //x 0E ext rst 1=AVR // fix for avrdude

//don't change //x lines only //c

//-------------------------------------
