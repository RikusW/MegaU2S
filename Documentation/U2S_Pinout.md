# U2S Pinout  
On all pinheaders pin 1 is on the left.  
  
Voltage select jumper:  

| 1: 5V | 2: Vcc | 3: 3V3 |
|---|---|---|

The 3V3 setting use the internal 3V3 regulator and can only give 85mA MAX, so take care.  
Or use an external 3V3 regulator connected to pins 1 + 2 + Gnd.  
Solder jumpered 1-2 by default.  
  
Programming select jumper:  

| 1: Out from PB0 | 2: To ISP pinout 5 | 3: In to cpu reset |
|---|---|---|

Solder jumpered 1-2 by default.  
  
ISP pinout:  

| 2: Vcc | 4: MOSI | 6: Gnd |
|---|---|---|
| 1: MISO | 3: SCK | 5: Reset |

Look in the ATmega32U2 datasheet for the SPI pinout. ATmega8U2/16U2/32U2  
  
Port header D/B  

| 2: Bit1 | 4: Bit3 | 6: Bit5 | 8: Bit7 | 10: Vcc |
|---|---|---|---|---|
| 1: Bit0 | 3: Bit2 | 5: Bit4 | 7: Bit6 | 9: Gnd |

The ISP and port headers use the same pinout as the STK500.  
