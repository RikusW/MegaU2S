This is the full source code for my U2S dev board.

This is free for personal or non-profit use, for commercial use contact me.
Rikus Wessels ---> rikusw - gmail - com

It is provided as is, no support guaranteed.
Though you might get lucky and get some help from me on #avr on freenode.net

To create these hex files first erase the ATmega32U2, set the lock to EF fuses FC DA 7F (E H L)
then uncheck the erase before programming box
and load BL32U2.eep, BL32U2, Jtag and UART hex files.
It can then be downloaded from the AVR to get a single hex file.
(Or you can manually copy and paste it together)
The fully built hex files for 16U2 and 32U2 are provided as well.
