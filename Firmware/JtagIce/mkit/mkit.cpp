//Terminal interface for the JTAG ICE mkI
//Copyright 2010 2011
//Rikus Wessels
//GPL2
//This is somewhat crude but it helped a lot with testing my mki clone.
//originally it consisted only of the hex mode.
//The device descriptors changed, it is no longer AVR060 compatible, more like the mkii's.

#include <windows.h>
#include <stdio.h>
#include <conio.h>
#include "RCom.h"

typedef unsigned char  u8;
typedef unsigned short u16;
typedef unsigned long  u32;
typedef signed long  s32;

u8 sign[] = "S  ";
u8 sync[] = "           ";
u8 buf[600];

void PrintHelp();

//-----------------------------------------------------------------------------
//device descriptors


unsigned char desc_m16[126] = { 0xA0, //command
0xCF,0xAF,0xFF,0xFF,0xFE,0xFF,0xFF,0xFF,
0x00,0x00,0x00,0x00,0x00,0x2F,0x00,0x00, // this
0x87,0x26,0xFF,0xEF,0xFE,0xFF,0x3F,0xFA, // and this swapped as did the ucExt ones....
0x00,0x00,0x00,0x00,0x00,0x2F,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x31, 0x57, 0x00,   0x80,0,   0x00, 0x80, 0x1F, 0x00, 0x00, 0x00,
 0x20, 0x20 }; //EOP

unsigned char desc_m162[126] = { 0xA0, //command
0xF7,0x6F,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0xF3,0x66,0xFF,0xFF,0xFF,0xFF,0xFF,0xFA,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x02,0x18,0x00,0x30,0xF3,0x0F,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x02,0x18,0x00,0x20,0xF3,0x0F,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x04, 0x57, 0x00,   0x80,0,   0x04, 0x80, 0x1F, 0x00, 0x00, 0x8B,
 0x20, 0x20 }; //EOP

unsigned char desc_m169[126] = { 0xA0, //command
0xFF,0xFF,0xFF,0xF0,0xDF,0x3C,0xBB,0xE0,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0xB6,0x6D,0x1B,0xE0,0xDF,0x3C,0xBA,0xE0,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x43,0xDA,0x00,0xFF,0xF7,0x0F,0x00,0x00,0x00,0x00,0x4D,0x07,0x37,0x00,0x00,0x00,0xF0,0xF0,0xDE,0x7B,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x43,0xDA,0x00,0xFF,0xF7,0x0F,0x00,0x00,0x00,0x00,0x4D,0x05,0x36,0x00,0x00,0x00,0xE0,0xF0,0xDE,0x7B,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x31, 0x57, 0x00,   0x80,0,   0x04, 0x80, 0x1F, 0x00, 0x00, 0xFE,
 0x20, 0x20 }; //EOP

unsigned char desc_m323[126] = { 0xA0, //command
0xCF,0xAF,0xFF,0xFF,0xFE,0xFF,0xFF,0xFF,
0x00,0x00,0x00,0x00,0x00,0x2F,0x00,0x00,
0x87,0x26,0xFF,0xEF,0xFE,0xFF,0x3F,0xFA,
0x00,0x00,0x00,0x00,0x00,0x2F,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x31, 0x57, 0x00,   0x80,0,   0x00, 0x00, 0x3F, 0x00, 0x00, 0x00,
 0x20, 0x20 }; //EOP

unsigned char desc_m32[126] = { 0xA0, //command
0xFF,0x6F,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0xFF,0x66,0xFF,0xFF,0xFF,0xFF,0xBF,0xFA,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x31, 0x57, 0x00,   0x80,0,   0x04, 0x00, 0x3F, 0x00, 0x00, 0x00,
 0x20, 0x20 }; //EOP

unsigned char desc_m64[126] = { 0xA0, //command
0xCF,0x2F,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0xCF,0x27,0xFF,0xFF,0xFF,0xFF,0xFF,0xFE,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x3E,0xB5,0x1F,0x37,0xFF,0x1F,0x21,0x2F,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x3E,0xB5,0x0F,0x27,0xFF,0x1F,0x21,0x27,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x22, 0x68, 0x00,   0x00,0x1, 0x08, 0x00, 0x7E, 0x00, 0x00, 0x9D,
 0x20, 0x20 }; //EOP

unsigned char desc_m128[126] = { 0xA0, //command
0xCF,0x2F,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0xCF,0x27,0xFF,0xFF,0xFF,0xFF,0xFF,0xFE,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x3E,0xB5,0x1F,0x37,0xFF,0x1F,0x21,0x2F,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x3E,0xB5,0x0F,0x27,0xFF,0x1F,0x21,0x27,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x22, 0x68, 0x3B,   0x00,0x1, 0x08, 0x00, 0xFE, 0x00, 0x00, 0x9D,
 0x20, 0x20 }; //EOP

unsigned char desc_unk[126] = { 0xA0, //command
0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFE,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x22, 0x68, 0x3B,   0x00,0x1, 0x08, 0x00, 0xFE, 0x00, 0x00, 0xFF,
 0x20, 0x20 }; //EOP

//device descriptors
//-----------------------------------------------------------------------------
//support functions


RCom rc;

void DoWrite(unsigned char c)
{
	rc.Write(&c,1);
}

void DoWriteEOP(unsigned char c)
{
	rc.Write(&c,1); c = 0x20;
	rc.Write(&c,1); c = 0x20;
	rc.Write(&c,1);
}

char *tohex="0123456789ABCDEF";
void puthex(char c)
{
	printf("--%c%c--\n",tohex[(c>>4)&0xF],tohex[c&0xF]);
}

void printhex(char c)
{
	printf("%c%c ",tohex[(c>>4)&0xF],tohex[c&0xF]);
}

char ishex(char c)
{
	if(c>='0' && c<='9') {
		return c-'0';
	}
	if(c>='a' && c<='f') {
		return c-'a'+0xA;
	}
	return 0x7F;
}


u8 gethexchar()
{
	u8 c;
	while((c=ishex(_getch())) > 15);
	return c;
}

u8 WriteHexChar(const char *p)
{
	u8 t;
	printf("%s (h):",p);
	DoWrite(t = gethexchar());
	printf("\n");
	return t;
}


u8 gethex()
{
	unsigned char c,r;
	while((c=ishex(_getch())) > 15);
	r = c << 4;
	while((c=ishex(_getch())) > 15);
	r|= c;
	return r;
}

u8 WriteHex(const char *p)
{
	u8 t;
	printf("%s (hh):",p);
	DoWrite(t = gethex());
	printf("\n");
	return t;
}


void WriteHex()
{
	DoWrite(gethex());
}

void SetIR(char c)
{
	u8 e;
	DoWrite(0xC0);
	DoWrite(c);
	DoWrite(0x00); //idle
	DoWrite(0x20);
	DoWrite(0x20);
	rc.Read(&e,1); //ReadFile(rc.hCom,&e,1,&d,0); //41
	if(e!=0x41) {
		printf("SetIR error1\n");
		return;
	}
	rc.Read(&e,1); //ReadFile(rc.hCom,&e,1,&d,0); //41
	if(e!=0x41) {
		printf("SetIR error2\n");
		return;
	}
	printf("SetIR=%c ok\n",tohex[c&0xF]);
}

void ReadDR(char bits)
{
	DoWrite(0xC1);
	DoWrite(0x01);
	DoWrite(bits);
	DoWrite(0x01);
	DoWrite(0x00);
	DoWrite(0x20);
	DoWrite(0x20);
}

void WriteDR(char bits, char idle)
{
	DoWrite(0xC1);
	DoWrite(0x00);
	DoWrite(bits);
	DoWrite(0x00);
	DoWrite(idle);
	while(bits > 0) {
		bits -= 8;
		WriteHex();
	}
	if(bits == 0) {
		DoWrite(0x00); //stupid mki bug....
	}
	DoWrite(0x20);
	DoWrite(0x20);
}

void WriteI(unsigned short s)
{
	DoWrite(0xC1);
	DoWrite(0x00);
	DoWrite(0x10);
	DoWrite(0x00);
	DoWrite(0x01);

	DoWrite((s>>8)&0xFF);
	DoWrite(s&0xFF);
	DoWrite(0x01); //stupid mki bug....

	DoWrite(0x20);
	DoWrite(0x20);
}

//extended instruction used in the U2S mki clone
void WriteDRD3(char bits, char idle)
{
	DoWrite(0xD3);
	DoWrite(bits);
	DoWrite(0x01);
	DoWrite(idle);
	DoWrite(0x20);
	DoWrite(0x20);
	while(bits > 0) {
		bits -= 8;
		WriteHex();
	}
}

u32 ReadData(u8 *p,s32 max)
{
	u8 e = 0;
	s32 d;

	do{
	d = rc.Read(&e,1); //ReadFile(rc.hCom,&e,1,&d,0); //41
	}while(d == 0);
	if(e!=0x41) {
		printf("ReadData error1 %x\n",e);

		rc.Read(&e,1); //ReadFile(rc.hCom,&e,1,&d,0); //41
		if(e!=0x41) {
		printf("ReadData error1 retry failed.\n");
		}
		return 0;
	}

	Sleep(10);
	max++; //the checksum...
	d = rc.Read(p,max); //ReadFile(rc.hCom,p,max,&d,0); //41
	if(d!=max) {
		printf("ReadData failed to read everything %d %d\n",d,max);
		return 0;
	}
	max = d;

	rc.Read(&e,1); //ReadFile(rc.hCom,&e,1,&d,0); //41
	if(e!=0x41) {
		printf("ReadData error2\n");
		return 0;
	}
	return max-1;
}

u8 GetParameter(u8 u)
{
	u8 e;

	DoWrite(0x71); //GetParameterarameter
	DoWrite(u);
	DoWrite(0x20);
	DoWrite(0x20);


	rc.Read(&e,1); //ReadFile(rc.hCom,&e,1,&d,0); //41
	if(e!=0x41) {
		printf("ReadData error1\n");
		return 0;
	}
	rc.Read(&u,1); //ReadFile(rc.hCom,&u,1,&d,0);

	rc.Read(&e,1); //ReadFile(rc.hCom,&e,1,&d,0); //41
	if(e!=0x41) {
		printf("ReadData error2\n");
		return 0;
	}
	return u;
}

//support functions
//-----------------------------------------------------------------------------
//init

int main()
{
	u8 c,e,r,t;
	u32 d,f;
	WORD w;

	if(rc.Open("COM3")) {
		printf("Fail to open COM port\n");
		return 1;
	}
	rc.SetBaudRate("19200 8N1");
//	rc.SetBaudRate("115200 8N1");
//	rc.SetBaudRate("230400 8N1");

	COMMTIMEOUTS ct;
	ct.ReadIntervalTimeout = 100;
	ct.ReadTotalTimeoutMultiplier = 50;
	ct.ReadTotalTimeoutConstant = 150;
	ct.WriteTotalTimeoutMultiplier = 0;
	ct.WriteTotalTimeoutConstant = 0;
	SetCommTimeouts(rc.hCom,&ct);

	rc.Write(sync,10);
	d = rc.Read(buf,10); //	ReadFile(rc.hCom,buf,10,&d,0);
	if(!d) {
		Sleep(20);
		d = rc.Read(buf,10); //	ReadFile(rc.hCom,buf,10,&d,0);
		if(!d) {
			printf("No jtagice connected.\n");
			return 1;
		}
	}

	rc.Write(sign,3);
	d = rc.Read(buf,9); //	ReadFile(rc.hCom,buf,9,&d,0);
	buf[8]=0;
	printf("Sign string = %s\n",buf+1);
	if(strcmp("AVRNOCD",(char*)(buf+1))) {
		printf("Invalid sign string\n");
		return 1;
	}


	d  = ((u32)GetParameter(0xA7));
	d |= ((u32)GetParameter(0xA8)) << 8;
	d |= ((u32)GetParameter(0xA9)) << 16;
	d |= ((u32)GetParameter(0xAA)) << 24;
	printf("Jtag id: 0x%x\n",d);
	switch((d>>12) & 0xFFFF) {

	case 0x9403:
		printf("Detecting a ATmega16\n");
		rc.Write(desc_m16,126);
		break;

	case 0x9404:
		printf("Detecting a ATmega162\n");
		rc.Write(desc_m162,126);
		break;

	case 0x9405:
		printf("Detecting a ATmega169\n");
		rc.Write(desc_m169,126);
		break;

	case 0x9401:
		printf("Detecting a ATmega323\n");
		rc.Write(desc_m323,126);
		break;

	case 0x9502:
		printf("Detecting a ATmega32\n");
		rc.Write(desc_m32,126);
		break;

	case 0x9602:
		printf("Detecting a ATmega64\n");
		rc.Write(desc_m64,126);
		break;

	case 0x9702:
		printf("Detecting a ATmega128\n");
		rc.Write(desc_m128,126);
		break;

	case 0x9781:
		printf("Detecting a AT90CAN128\n");
		rc.Write(desc_m128,126);
		break;

	default:
		printf("Unknown device\n");
		rc.Write(desc_unk,126);
	}

//init
//-----------------------------------------------------------------------------
//mainloop

	while(1) {
		do{
			if(d = rc.Read(&c,1) == 1) {
				puthex(c);
			}
		}while(d);

		c = _getch();
		switch(c) {

		case ' ':
			printf("Get Synch\n");
			DoWrite(0x20);
			break;

		case '1':
			printf("Single Step\n");
			DoWriteEOP(0x31);
			break;

		case '2':
			printf("Reading PC\n");
			DoWriteEOP(0x32);
			break;

		case '3':
			printf("Writing PC\n");
			DoWrite(0x33); //write pc
			DoWrite(0x00); //msb
			WriteHex("MSB");
			WriteHex("LSB"); //lsb
			DoWrite(0x20);
			DoWrite(0x20);
			break;

		case 'B': case 'Q': //setparameter
			printf("Setting parameter, enter parameter number and value\n");
			DoWrite(0x42);
			WriteHex("Parameter");
			WriteHex("Value");
			DoWrite(0x20);
			DoWrite(0x20);
			break;

		case 'F':
			printf("Forced Stop\n");
			DoWriteEOP(0x46); //forced stop
			break;

		case 'G':
			printf("Go\n");
			DoWriteEOP(0x47); //go
			break;

		case 'R':
			printf("Reading Memory, counting start at 0, so  00->1 01->2 FF->0x100\n");
			DoWrite(0x52); //read memory  --Rttccaaaa--
			t = WriteHex("Type");
			c = WriteHex("Count");
			DoWrite(0x00); //msb
			WriteHex("MSB");
			WriteHex("LSB"); //lsb
			DoWrite(0x20);
			DoWrite(0x20);

			Sleep(20);

			d = c; d++;
			if(t==0x90 || t==0xA0 || t==0xB0) {
				d<<=1;
			}
			f = ReadData(buf,d);
			printf("read %d actual %d\n",d,f);
			for(f=0; f<d; f++) {
				if((f&0xF)==0) {
					printf("%c%c:  ",tohex[(f>>4)&0xF],tohex[f&0xF]);
				}
				printf("%c%c ",tohex[(buf[f]>>4)&0xF],tohex[buf[f]&0xF]);
				if((f&7)==7) {
					printf("- ");
				}
				if((f&0xF)==0xF) {
					printf("\n");
				}
			}//*/
			printf("\n");
			break;

		case 'S':
			DoWriteEOP(0x53); //signon
			break;

		case 'W':
			printf("Writing Memory, counting start at 0, so  00->1 01->2 FF->0x100\n");
			DoWrite(0x57); //write memory  --Wttccaaaa--
			e = WriteHex("Type");
			f = WriteHex("Count");
			DoWrite(0x00); //msb
			WriteHex("MSB");
			WriteHex("LSB"); //lsb
			DoWrite(0x20);
			DoWrite(0x20);
			d = rc.Read(&c,1); //	ReadFile(rc.hCom,&c,1,&d,0); //41
			if((d != 1) || (c != 0x41)) {
				printf("write error\n");
				break;
			}
			printf("-----writing-----\n");
			DoWrite('h'); //?h?
			if(e==0xA0 || e==0xB0) {
				d <<= 1;
			}
			do {
				WriteHex();
			}while(f--);
			printf("-----writing done-----\n");
			break;

		case 'q':
			printf("Querying parameter, enter parameter number\n");
			DoWrite(0x71); //GetParameter
			WriteHex("Parameter");
			DoWrite(0x20);
			DoWrite(0x20);
			break;

		case 'x':
			printf("Resetting target\n");
			DoWriteEOP(0x78); //reset
			break;

//=========================================================
//extended commands

		case 'I': // set IR  --i0 to if--
			printf("Enter IR value. (h):");
			SetIR(gethexchar());
			printf("\n");
			break;

		case '8':
			printf("--Forced Break--\n");
			SetIR(8); //Force break
			break;

		case '9':
			printf("--GO--\n");
			SetIR(9); //Go
			break;

//-----------------------------------------------
//IR=5
		case '{':
			printf("Entering Programming mode");
			DoWriteEOP(0xA3);
			break;

		case 'p':
			printf("reading programming instruction register\n");
			SetIR(5);
			ReadDR(0x0F);
			break;

		case 'P':
			printf("write programming instruction (hhhh)\n");
			SetIR(5);
			WriteDR(0x0F,1);
			break;

		case '}':
			printf("Leaving Programming mode");
			DoWriteEOP(0xA4);
			break;

//-----------------------------------------------
//IR=A
		case 'a': // read PC  --a--
			SetIR(0xA);
			ReadDR(0x10);
			break;

		case 'A': // write PC
			w = gethex();
			WriteI(0xE0F0 | ((w<<4)&0x0F00) | (w&0xF)); //LDI r31,xx
			w = gethex();
			WriteI(0xE0E0 | ((w<<4)&0x0F00) | (w&0xF)); //LDI r30,xx
			WriteI(0x9409); //IJMP

			/* This may or may not work
			d = gethex() << 8;
			d|= gethex();
			WriteI(0x940C); //JMP
			WriteI(0x940C); //JMP
			WriteI(d);*/
			break;

		case 'i': // execute instruction  --ihhhh--
			printf("Execute Instruction (hhhh)\n");
			SetIR(0xA);
			WriteDR(0x10,1);
			break;

//-----------------------------------------------
//IR=B
		case 'o': //read OCD register  --o0 to of--
			SetIR(0xB);
			printf("OCD registers 0=PSB0 1=PSB1 2=PDMSB 3=PDSB 8=BCR 9=BSR C=OCDR D=CSR\n");
			printf("--READING-- OCD register\n");
			DoWrite(0x52); //read mem
			DoWrite(0x90);
			DoWrite(0x00); //1 byte
			DoWrite(0x00);
			DoWrite(0x00);
			WriteHexChar("REG");
			DoWrite(0x20);
			DoWrite(0x20);

			Sleep(1);
			rc.Read(&c,1); //ReadFile(rc.hCom,&c,1,&d,0); //41
			rc.Read(&c,1); //ReadFile(rc.hCom,&c,1,&d,0);
			rc.Read(&e,1); //ReadFile(rc.hCom,&e,1,&d,0);
			printf("--0x%c%c%c%c--\n",tohex[(c>>4)&0xF],tohex[c&0xF],tohex[(e>>4)&0xF],tohex[e&0xF]);
			rc.Read(&c,1); //ReadFile(rc.hCom,&c,1,&d,0); //00 checksum...
			rc.Read(&c,1); //ReadFile(rc.hCom,&c,1,&d,0); //41
			break;

		case 'O': //write OCD register  --O0hhhh to Ofhhhh--
			SetIR(0xB);
			printf("OCD registers 0=PSB0 1=PSB1 2=PDMSB 3=PDSB 8=BCR 9=BSR C=OCDR D=CSR\n");
			printf("--WRITING-- OCD register\n");
			DoWrite(0xC1); //WriteDR
			DoWrite(0x00); //write
			DoWrite(0x15); //bits
			DoWrite(0x00); //write
			DoWrite(0x00); //idle

			printf("REG (h):");
			c = gethexchar();
			DoWrite(0x10|c); //0x10==write
			printf("\n");

			WriteHex("OCD MSB");
			WriteHex("OCD LSB");
			DoWrite(0x20);
			DoWrite(0x20);
			break;

//-----------------------------------------------
//experimental stuff

		case 'd': // read DR  --dhh-- hh=bits
			ReadDR(gethex());
			break;

		case 'D': // write DR  --Dhhxx...--
			WriteDR(gethex(),0);
			break;

		//this only works on my mki clone
		case 'C': // write DR  --Dhhxx...--
			WriteDRD3(gethex(),0);
			break;

		case 'j': // write DR  --jchhhh--
			printf("jchhhh\n");
			c = gethexchar();
			WriteDR(0x10,c);
			break;

		case 'J': // write DR  --jcc...--
			printf("Jcc...\n");
			WriteDR(gethex(),1);
			break;

//-----------------------------------------------

		case 'r':
			DoWrite(0x52); //read mem
			DoWrite(0x20); //type=sram
			DoWrite(0x1F); //count -- 1F is 20, Atmel use 0 based counting...
			DoWrite(0x00); //msb
			DoWrite(0x00);
			DoWrite(0x00); //lsb
			DoWrite(0x20);
			DoWrite(0x20);

			Sleep(10);
			ReadData(buf,0x20);
			#define HEX(xx) tohex[(buf[xx]>>4)&0xF],tohex[buf[xx]&0xF]
			printf("r0=%c%c   r8=%c%c  r16=%c%c  r24=%c%c\n",HEX(0),HEX( 8),HEX(16),HEX(24));
			printf("r1=%c%c   r9=%c%c  r17=%c%c  r25=%c%c\n",HEX(1),HEX( 9),HEX(17),HEX(25));
			printf("r2=%c%c  r10=%c%c  r18=%c%c  r26=%c%c\n",HEX(2),HEX(10),HEX(18),HEX(26));
			printf("r3=%c%c  r11=%c%c  r19=%c%c  r27=%c%c\n",HEX(3),HEX(11),HEX(19),HEX(27));
			printf("r4=%c%c  r12=%c%c  r20=%c%c  r28=%c%c\n",HEX(4),HEX(12),HEX(20),HEX(28));
			printf("r5=%c%c  r13=%c%c  r21=%c%c  r29=%c%c\n",HEX(5),HEX(13),HEX(21),HEX(29));
			printf("r6=%c%c  r14=%c%c  r22=%c%c  r30=%c%c\n",HEX(6),HEX(14),HEX(22),HEX(30));
			printf("r7=%c%c  r15=%c%c  r23=%c%c  r31=%c%c\n",HEX(7),HEX(15),HEX(23),HEX(31));
			printf("\n");
			break;

//-----------------------------------------------

		//for directly giving commands to the mki
		//cumbersome to use, but sometimes it is useful
		//originally this was all that was available...
		case 'h':
			printf("-----Entering hex mode-----\n");
			while((c=ishex(_getch())) <= 15) {
				r = c << 4;
				if((c=ishex(_getch())) > 15) {
					break;
				}
				r|= c;
				DoWrite(r);
				for(d=1;d;) {
					; //ReadFile(rc.hCom,&c,1,&d,0);
					if(d = rc.Read(&c,1) == 1) {
						puthex(c);
					}
				}
			}
			printf("------Leaving hex mode-----\n");
			break;

		//what?! is the other commands that difficult to use ?
		case 'H':
			PrintHelp();
			break;
		}

	}

//mainloop
//-----------------------------------------------------------------------------

	return 1;
}

void PrintHelp()
{
printf("\
----Most instructions only work in stopped mode, so stop it with F first----\n\
1 - SingleStep\n\
2 - Read PC\n\
3 - Write PC\n\
B - Set Parameter\n\
F - Force Break\n\
G - Go\n\
R - Read Memory\n\
S - Signon, JtagIce must respond with AVRNOCD\n\
W - Write Memory\n\
q - Query Parameter.\n\
Q - Set Parameter\n\
x - Resets the target\n\
{ - Enter programming mode\n\
} - Leave programming mode\n\
  - space, will return 0x41 (A) if in sync.\n\
\n\
=====Extended functionality=====\n\
\n\
I - Set IR\n\
8 - Force Break\n\
9 - Go\n\
p - Read programming data     (Read IR=5)  use { first!\n\
P - Write programming command (Write IR=5) use { first!\n\
a - Read IR=A - PC\n\
A - Set PC - buggy - do it twice if it doesn't work\n\
i - Execute instruction, enter four hex digits, msb first\n\
o - Read OCD register\n\
O - Write OCD register\n\
r - Display the registers\n\
h - Enter hex mode\n\
\n\n");
}


