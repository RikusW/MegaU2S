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
