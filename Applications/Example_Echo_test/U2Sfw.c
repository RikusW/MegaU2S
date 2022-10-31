// GPLv2 2010 Rikus Wessels
// rikusw gmail


#include <avr/io.h>
#include <util/delay.h>
#include "usb_lib.h"


int main(int i, char **p) // ignore p
{
	u8 u;
	i &= 0x0F; // the select value from the bootloader

	usb_init();

	while(1) {
		while(!usb_rxready()) {
			if(select_pressed()) {
				led_on();
				while(select_pressed());
				select_mode(0x81); // goto the bootloader
			}
		}

		u = usb_getc();
		usb_putc_nf(u+i);
		usb_putc_nf('\r');
		usb_putc('\n');
		if(u == 'q') {
			select_mode(0x81);
		}
	}
	return 0;
}



