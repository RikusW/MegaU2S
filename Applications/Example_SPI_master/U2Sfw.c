// GPLv2 2010 Rikus Wessels
// rikusw gmail


#include <avr/io.h>
#include <util/delay.h>
#include "usb_lib.h"

#define SPIPIN  PINB
#define SPIPORT PORTB
#define SCKBIT  1
#define MOSIBIT 2
#define MISOBIT 3
#define SPIDDR  DDRB



int main(int i, char **p) // ignore p
{
	u8 u;
	u8 t=0; //timer enabled ?

	usb_init();

	PORTB = (1<<PORTB4)|(1<<PORTB5);
	DDRB = (1<<DDB4)|(1<<SCKBIT)|(1<<MOSIBIT);
	TCCR1A = 0;
	TCCR1B = (1<<CS12)|(CS10); // 8MHz / 1024 = 128us per tick
	SPCR = (1<<SPE)|(1<<MSTR)|(1<<SPR1)|(1<<SPR0);
	SPSR = 0;

	while(1) {
		if(select_pressed()) {
			led_on();
			while(select_pressed());
			select_mode(0x81); // goto the bootloader
		}
		if(usb_rxready() || !(PINB & (1<<PINB5))) {
			if(usb_rxready()) {
				u = usb_getc();
			}else{
				u = 0;
			}

			u8 B = PINB;
			SPCR |= (1<<MSTR); // accidental /SS ??
			PORTB &= ~(1<<PORTB4); //SS
			SPDR = u;
			while(!(SPSR & (1<<SPIF)));
			u = SPDR;
			PORTB |= (1<<PORTB4);

			if(u && !(B & (1<<PINB5))) {
				usb_putc_nf(u);
				t = 1;
				TCNT1 = 0;
			}
		}

		if(t && ((TCNT1 > 80) || (PINB & (1<<PINB5)))) { //time out 10.24ms
			usb_flush();
			t = 0;
		}
	}
	return 0;
}



