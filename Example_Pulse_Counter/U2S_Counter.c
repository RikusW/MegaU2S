// U2S Pulse Counter
// GPLv2 2011/07 Rikus Wessels
// rikusw gmail

#include <avr/io.h>
#include <util/delay.h>
#include <avr/interrupt.h>
#include "usb_lib.h"


volatile u8 readflag = 0;
volatile u16 count = 0,t;

void prints(char *s)
{
	while(*s) {
		usb_putc_nf(*s);
		s++;
	}
	usb_flush();
}

void print_u16(u16 u)
{
	u8 n;

	for(n = 0; u >= 10000; u-=10000, n++);
	usb_putc_nf('0' + n);
	for(n = 0; u >= 1000; u-=1000, n++);
	usb_putc_nf('0' + n);
	for(n = 0; u >= 100; u-=100, n++);
	usb_putc_nf('0' + n);
	for(n = 0; u >= 10; u-=10,n++);
	usb_putc_nf('0' + n);
	usb_putc_nf('0' + u);
	usb_putc_nf(0x0A);
	usb_putc(0x0D);
}

ISR(TIMER0_COMPA_vect)
{
	readflag = 1;
	count = TCNT1;
	TCNT1 = 0;
}

int main(int i, char **p) // ignore p
{
	CLKPR = (1<<CLKPCE);
	CLKPR = 0; //16MHz

	usb_init();

	PORTB = 0;
	DDRB = (1<<DDC6); //B6 out

	sei();
	TCNT0 = 0;
	TCCR0A = (1<<WGM01); // CTC
	OCR0A = 156; //10ms intervals ==> 15,625Hz * 0.01s
	TIMSK0 = (1<<OCIE0A);

	TCCR1A = 0;
	TCCR1B = (1<<CS12)|(1<<CS11)|(1<<CS10); // external T1

//-------------------------------------------------------------------

	while(1) {
		while(!usb_rxready()) {
			if(select_pressed()) {
				led_on();
				while(select_pressed());
				select_mode(0x81); // goto the bootloader
			}
			if(readflag) {
				readflag = 0;
				t = count;
				print_u16(t);
			}
		}

		switch(usb_getc()) {

		case 'i': //identify
			prints("U2S Pulse Counter\r\n"); 
			break;

		case 's':
		case 'S': //start
			TCNT1 = 0;
			TCCR0B = (1<<CS02)|(1<<CS00); // clk/1024 ==> 15,625 Hz
			PORTB |= (1<<PORTB6);
			prints("Start\r\n");
			break;

		case 'p':
		case 'P': //Stop
			TCCR0B = 0;
			PORTB &= ~(1<<PORTB6);
			prints("Stop\r\n");
			break;
		}
	}
	return 0;
}



