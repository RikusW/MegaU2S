# Selecting Modules  
When only the RESET button was pressed without using the SELECT button, the default eeprom value (eesel - which is shipped as 0x81) will be used.  
Be aware that if some application is still connected to the CDC serial port when pressing reset it will enumerate as the next available port, eg: COM4 or /dev/ttyACM1 instead of COM3 or /dev/ttyACM0.  
  
Using the SELECT switch will override the default eesel value stored in eeprom.  
The select value is equal the the number of times RESET is released while holding down SELECT.  
Pressing only reset (rR) will load the select value from eeprom.  
  
Fully describing the button presses is a bit awkward so I use a shorthand form:  
R = Reset button released --- r = Reset button pressed and held down  
S = Select button released --- s = Select button pressed and held down  
  
Examples:  
0x01 rs Rr SR  (app) press reset,  press select,  release reset,  press reset,  release select,  release reset  
0x81 rs RS (bootloader)  press reset,  press select,  release reset,  release select  
  
  
App modes for custom loaded firmware, will be passed to main as argc and also r24 if you are using assembler.  
  
eeprom - rR (would have been 0x00)  
0x00 sS -- only from bootloader mode, a shortcut. (Press and release the Select button)  
0x01 rs Rr SR (same as -> sr Rr SR)  
0x02 rs Rr Rr SR  
0x03 rs Rr Rr Rr SR  
0x04 rs Rr Rr Rr Rr SR   
........  
0x0F (up to fifteen! times)  
  
Loadable modules:  
  
0x80 -- Debug mode, can only be selected with PC software.  
0x81 rs RS  --  Bootloader mode  (Vtg = 4v8)  (same as -> sr RS)  
0x82 rs Rr RS  --  STK500 mode  (Vtg = 5v2)  
0x83 rs Rr Rr RS  --  JTAGICE mkI mode  
0x84 rs Rr Rr Rr RS  --  UART mode  
0x85 rs Rr Rr Rr Rr RS -- DebugWire -- still needs to be implemented.  
........  
0x8E -- rescue mode if you are somehow locked out of the bootloader.  
0x8F -- Arduino bootloader, activated from the Arduino Core files. A wrapper for Bootloader mode, with a timeout added.  

## Changing the default mode  
NEW: U2S\_GUI will now allow changing default modes.  
One of the .eep files in U2Settings.tgz can be loaded to change the default startup mode. U2Settings\_APP\_NoUSB.eep can be use if your firmware contains its own USB code.  
  
This can also be used if your custom app code have overwritten the eeprom settings by accident. Use the Select button to enter bootloader mode first. (rs RS)  
  
avrdude terminal mode can be used as well. Add [bl32u2\_avrdude\_conf\_patch.txt](bl32u2\_avrdude\_conf\_patch.txt) to /etc/avrdude.conf, then use ->  avrdude -p bl32u2 -c stk500pp -P /dev/ttyACM0 -t  
  
read eep 0x3f0 0x10 -- will read the settings  
03f0 81 02 02 0a b0 30 00 00 00 02 00 ff ff 00 ff 01 \|... .0..........\|  
  
write eep 0x3f0 0x82 -- will change the default mode to STK500  
