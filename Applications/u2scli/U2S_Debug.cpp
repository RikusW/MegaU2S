

//#include <windows.h>
#include <stdio.h>
#include "U2S_Debug.h"




int main()
{
	if(!u2s.Connect("/dev/ttyACM0",0x80)) {
		printf("failed to connect\n");
		return 1;
	}

	u8 s = PINC;

	PORTB |= 0x40;

	DDRB |= 0x40;

	s = PORTB;

	s = PINB;

	DDRB &= ~0x40;

	PORTB &= ~0x40;

	PORTB = 0x40;

	PORTB = 0;

	DDRB = 0;

	u2s.Disconnect();
	return 0;
}


