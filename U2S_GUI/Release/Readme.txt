USART Setup notes

The radio buttons will be save to eeprom.
When using baud override the baud will be saved to eeprom too,
in the locations used for VTG/VAD, so AS4/5/6 might complain
about wrong voltages in STK500/bootloader mode.

When using setup override, use this app to do the setup.
Alternatively setup the uart from app code and then go to mode 84.


Unfortunately the rs232 variable is reset while changing modes.
The only solution so far is to store it into eeprom...
(Thats why the radio box settings are saved into eeprom)

