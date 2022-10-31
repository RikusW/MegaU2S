// vim:ts=4 sts=0 sw=4
// u2s cli for controlling its modes

#include <stdio.h>
#include <string.h>

#include "U2S.h"

U2S u2s;

u8 gethexnibble(u8 x)
{
	if(x >= '0' && x <= '9') {
		return x - '0';
	}
	if(x >= 'a' && x <= 'f') {
		return x - 'a' + 10;
	}
	if(x >= 'A' && x <= 'F') {
		return x - 'A' + 10;
	}
	return 0;
}

u8 gethex(char *p)
{
	u8 r;
	r = gethexnibble(p[0]);
	r <<= 4;
	r |= gethexnibble(p[1]);
	return r;
}

int main (int argc, char *argv[])
{
	u8 mode;
	bool unlock = false;
	char *port = "/dev/ttyACM0";

	if(argc <= 1) {
		printf("Commandline tool to set U2S modes\n");
		printf("Usage: u2scli XX\n");
		printf("Usage: u2scli XX /dev/ttyACMx\n");
		return 1;
	}

	if(argc >= 3) {
		port = argv[2];
	}

	mode = gethex(argv[1]);
	printf("Setting mode to %02X\n",mode);


	if(argc > 3) {
		if(!strcmp("unlock",argv[3])) {
			unlock = true;
			mode = 0x81;
		} else {
			printf("Too many parameters\n");
		}
		return 1;
	}

	u2s.Connect(port,mode);
	if(unlock) {
		u2s.ModUnlock(); //allow updating of existing fw modules
	}
	u2s.Disconnect();

	return 0;
}


