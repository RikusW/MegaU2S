// vim:ts=4 sts=0 sw=4
// g++ u2s.cpp RCom.cpp -o ss

#include <windows.h>
#include <stdio.h>
#include <string.h>

#include "U2S.h"
#include "RCom.h"
#include "command.h"


RCom rc;
u8 seq = 0;
u16 rxsize;
u8 buf[300];
u8 *msg = &buf[5];

//=============================================================================

u8 U2S::Connect(const char *c, u8 mode)
{
	if(rc.Open(c)) {
		return 0;
	}

	rc.SetBaudRate("115200 8N1");

	COMMTIMEOUTS ct;
	ct.ReadIntervalTimeout = 350;
	ct.ReadTotalTimeoutMultiplier = 100;
	ct.ReadTotalTimeoutConstant = 350;
	ct.WriteTotalTimeoutMultiplier = 0;
	ct.WriteTotalTimeoutConstant = 0;
	SetCommTimeouts(rc.hCom,&ct);
	
	rc.SetDtr(); //exit Arduino Sketch

	//Exit dW and jtag modes
	char buf[3];
	buf[0] = 0x4D; //M
	buf[1] = 0x4D;
	buf[2] = 0x4D;
	rc.Write((char*)buf,3);

	SelectMode(mode);

	return 1;
}

void U2S::Disconnect()
{
	rc.Close();
}

//-------------------------------------
// Packet handling

/*
char *tohex = "0123456789ABCDEF";

void PrintBuf(char *p, int s)
{
	for(int i=0; i<s; i++) {
		putchar(tohex[(p[i] >> 4) & 0xF]);
		putchar(tohex[p[i] & 0xF]);
		putchar(' ');
	}
	putchar('\n');
}*/

void U2S::SendMsg()
{
	int i;
	u8 xorsum;
	u16 sz=0;

	sz = msg - &buf[5];
	msg = &buf[5];

	buf[0] = MESSAGE_START;
	buf[1] = seq++;
	buf[2] = (sz >> 8) & 0xFF;
	buf[3] = sz & 0xFF;
	buf[4] = TOKEN;

	sz += 5;
	xorsum = 0;
	for(i=0; i<sz; i++) {
		xorsum ^= buf[i];
	}
	buf[sz++] = xorsum;

//	putchar('\n');
//	PrintBuf(buf,sz);
	rc.Write((char*)buf,sz);
	sz = 0;
}

u8 *U2S::GetMsg()
{
	do {
		rc.Read((char*)buf,1);
	}while(buf[0] != MESSAGE_START);

	rc.Read((char*)buf+1,4);
	if(buf[4] != TOKEN) {
		return 0; //fail
	}
	//seq check ?

	rxsize = ((buf[2] << 8) | buf[3]) + 1; //+1 for checksum
	rc.Read((char*)&buf[5],rxsize);

	//do checksum check here ?

//	PrintBuf(buf,rxsize+6);
//	msg = &buf[5];
	return msg;
}

//=============================================================================
// STK

u8 U2S::SignOn()
{
	*msg++ = CMD_SIGN_ON;
	SendMsg();
	GetMsg();
	return !strncmp((char*)&msg[3],"STK500_2",8);
}

void U2S::SetParameter(u8 a, u8 v)
{
	*msg++ = CMD_SET_PARAMETER;
	*msg++ = a;
	*msg++ = v;
	SendMsg();
	GetMsg();
}

u8 U2S::GetParameter(u8 a)
{
	*msg++ = CMD_GET_PARAMETER;
	*msg++ = a;
	SendMsg();
	GetMsg();
	return msg[2]; // error handling ???!!!
}

void U2S::SetAddress(u32 a)
{
	*msg++ = CMD_LOAD_ADDRESS;
	*msg++ = (u8)((a >> 24) & 0xFF); // |= 0x80 for ATmega2560
	*msg++ = (u8)((a >> 16) & 0xFF);
	*msg++ = (u8)((a >>  8) & 0xFF);
	*msg++ = (u8)((a >>  0) & 0xFF);
	SendMsg();
	GetMsg();
}

// STK
//=============================================================================
// ISP programming

u8 U2S::EnterProgmodeIsp()
{
	*msg++ = CMD_ENTER_PROGMODE_ISP; // used the values for ATmega16U2
	*msg++ = 200; // timeout	1 byte  XML: timeout  Command time-out (in ms) 
	*msg++ = 100; // stabDelay	1 byte  XML: stabDelay  Delay (in ms) used for pin stabilization 
	*msg++ =  25; // cmdexeDelay1 byte  XML: cmdexeDelay  Delay (in ms) in connection with the 
	*msg++ =  32; // synchLoops	1 byte  XML: synchLoops  Number of synchronization loops 
	*msg++ =   0; // byteDelay	1 byte  XML: byteDelay  Delay (in ms) between each byte in the
	*msg++ = 0x53; // pollValue	1 byte  XML: pollValue  Poll value: 0x53 for AVR, 0x69 for AT89xx 
	*msg++ = 0x03; // pollIndex 0 = no polling, 3 = AVR, 4 = AT89xx 
	*msg++ = 0xAC; // cmd1  1 byte    Command Byte # 1 to be transmitted 
	*msg++ = 0x53; // cmd2  1 byte    Command Byte # 2 to be transmitted 
	*msg++ = 0x00; // cmd3  1 byte    Command Byte # 3 to be transmitted 
	*msg++ = 0x00; // cmd4  1 byte    Command Byte # 4 to be transmitted 
	SendMsg();
	GetMsg();
	return msg[1] == STATUS_CMD_OK;
}

void U2S::LeaveProgmodeIsp()
{
	*msg++ = CMD_LEAVE_PROGMODE_ISP;
	*msg++ = 1;
	*msg++ = 1;
	SendMsg();
	GetMsg();
}

void U2S::ChipErase()
{
	*msg++ = CMD_CHIP_ERASE_ISP;
	*msg++ = 55; //XML: eraseDelay  Delay (in ms) to ensure that the erase of the device is finished 
	*msg++ =  1; //XML: pollMethod  Poll method, 0 = use delay 1= use RDY/BSY command 
	*msg++ = 0xAC;
	*msg++ = 0x80;
	*msg++ = 0x00;
	*msg++ = 0x00;
	SendMsg();
	GetMsg();
}

//This only works in the bootloader.
//Do a SetAddress first, using byte addressing, page aligned. 
void U2S::ErasePages(u8 n) //number of pages (0 is 256 pages)
{
	*msg++ = 0x1F; //U2S extended command
	*msg++ = 0xA3; //prevent accidental erasing
	*msg++ = n;
	SendMsg();
	GetMsg();
}
//---------------------------
// Flash
//#define CMD_PROGRAM_FLASH_ISP               0x13

void U2S::ReadFlash(u8 **buf, u16 u)
{
	if(u > 256) {
		u = 256;
	}
	*msg++ = CMD_READ_FLASH_ISP;
	*msg++ = (u8)((u >> 8) & 0xFF);
	*msg++ = (u8)((u >> 0) & 0xFF);
	*msg++ = 0x20;
	SendMsg();
	GetMsg();
	*buf = &msg[2];
}


//---------------------------
// EEProm
//#define CMD_PROGRAM_EEPROM_ISP              0x15

void U2S::ReadEeprom(u8 **buf, u16 u)
{
	if(u > 256) {
		u = 256;
	}
	*msg++ = CMD_READ_EEPROM_ISP;
	*msg++ = (u8)((u >> 8) & 0xFF);
	*msg++ = (u8)((u >> 0) & 0xFF);
	*msg++ = 0xA0;
	SendMsg();
	GetMsg();
	*buf = &msg[2];
}

//---------------------------

void U2S::WriteFuse(u8 a, u8 v)
{
	*msg++ = a == WF_LOCK ? CMD_PROGRAM_LOCK_ISP : CMD_PROGRAM_FUSE_ISP;
	*msg++ = 0xAC;
	*msg++ = a;
	*msg++ = 0;
	*msg++ = v;
	SendMsg();
	GetMsg();
}

//---------------------------

u8 U2S::ReadFuse(u8 a)
{
	*msg++ = a == RF_LOCK ? CMD_READ_LOCK_ISP : CMD_READ_FUSE_ISP;
	*msg++ = 4;
	*msg++ = 0x50 | ((a>>4)&0x0F);
	*msg++ = a & 0x0F;
	*msg++ = 0;
	*msg++ = 0;
	SendMsg();
	GetMsg();
	return msg[2];
}

u8 U2S::ReadSig(u8 a)
{
	*msg++ = CMD_READ_SIGNATURE_ISP;
	*msg++ = 4;
	*msg++ = 0x30;
	*msg++ = 0;
	*msg++ = a;
	*msg++ = 0;
	SendMsg();
	GetMsg();
	return msg[2];
}

u8 U2S::ReadCal(u8 a)
{
	*msg++ = CMD_READ_OSCCAL_ISP;
	*msg++ = 4;
	*msg++ = 0x38;
	*msg++ = 0;
	*msg++ = a;
	*msg++ = 0;
	SendMsg();
	GetMsg();
	return msg[2];
}

void U2S::GetSerial(u8 *buf) // [10]
{
	//SetToBL(); ???
	for(u8 o = 0x07; o<=0x0B; o++) { // sig(0x0E 0x17) ---- ???(0x18 0x1D)
		*buf++ = ReadCal(o);
		*buf++ = ReadSig(o);
	}
}

//46 39 38 32 31 31 15 01 20 23 - 17 01 12 00 13 00
//46 39 38 32 31 31 15 01 0d 23 - 17 01 12 00 13 00


// ISP programming
//=============================================================================
// CUSTOM - usable from 0x80 0x81 0x82

#define CMD_CUSTOM 0xFF


void U2S::SelectMode(u8 u)
{
	if((GetMode() & 0x8F) == u) {
		return;
	}
	*msg++ = CMD_CUSTOM;
	*msg++ = 0x00;
	*msg++ = u; // sel passed to app
	SendMsg();
	GetMsg();
}

u8 U2S::GetMode() //eg: 0x81 for bootloader 0x82 for programmer
{
	*msg++ = CMD_CUSTOM;
	*msg++ = 0x01;
	SendMsg();
	GetMsg();
	return msg[2];
}

u8 U2S::GetVersion() //currently 1
{
	*msg++ = CMD_CUSTOM;
	*msg++ = 0x02;
	SendMsg();
	GetMsg();
	return msg[2];
}

u16 U2S::GetAppSize()
{
	u16 u;
	*msg++ = CMD_CUSTOM;
	*msg++ = 0x03;
	SendMsg();
	GetMsg();
	u = msg[2];
	u <<= 8;
	u |=msg[1];
	return u;
}

u8 U2S::ModUnlock()
{
	*msg++ = CMD_CUSTOM;
	*msg++ = 0x04;
	*msg++ = 0x5C;
	SendMsg();
	GetMsg();
	return msg[1];
}


// CUSTOM
//=============================================================================
//SPI can only be used from 0x82 the ISP programmer

/*
Hardware SPI
0 - 2MHz  (1843.2) 8MHz (7.3728MHz Stk500) This may work if everything is just right.
1 - 500kHz (460.8) This is the most stable setting. About the same speed as 2MHz.
2 - 125kHz (115.2) Use this if the clock is below 2MHz.
3 - 62.5kHz (57.6)

Software SPI  8MHz / ((24*u + 30) clocks)
4 - ~63kHz
5 - ~53kHz
6 - ~46kHz
7 - ~40kHz
0x4C - ~4314Hz (3998Hz) Don't use for flashing, it takes forever.
0xFE - ~1305Hz (1210Hz)
*/
// Should be called before SpiOn else the default speed will be used.
void U2S::SpiSetSpeed(u8 u)
{
	SetParameter(PARAM_SCK_DURATION, u);
}

bool U2S::SpiOn()
{
	SelectMode(0x82);
	*msg++ = 0xF0;
	SendMsg();
	GetMsg();
	return !msg[1]; //STATUS_CMD_OK
}

void U2S::SpiOff()
{
	*msg++ = 0xF1;
	SendMsg();
	GetMsg();
}

// Used when the target is out of sync, pulses sck once.
void U2S::SpiPulse()
{
	*msg++ = 0xF2;
	SendMsg();
	GetMsg();
}
/*
u8 U2S::SpiDetect()
{
	*msg++ = 0xF3;
	SendMsg();
	GetMsg();
	return !msg[1]; //STATUS_CMD_OK
}*/

void U2S::SpiTx(u8 *buf,u8 nr)
{
	nr = nr > 255 ? 255 : nr;
	*msg++ = CMD_SPI_MULTI;
	*msg++ = nr;
	*msg++ = nr;
	*msg++ = 0;

	u8 u,*p = buf;
	for(u=0; u < nr; u++) {
		*msg++ = *p++;
	}
	SendMsg();
	u8 *m = GetMsg();
	p = buf;
	for(u=0; u < nr; u++) {
		*p++ = *m++;
	}

}

//SPI
//=============================================================================
//DB

/*
regmap map[] = // for ATmega16U2
{
	{ 0x23, "PINB" },
	{ 0x24, "DDRB" },
	{ 0x25, "PORTB" },

	{ 0x26, "PINC" },
	{ 0x27, "DDRC" },
	{ 0x28, "PORTC" },

	{ 0x29, "PIND" },
	{ 0x2A, "DDRD" },
	{ 0x2B, "PORTD" },

	{ 0, 0 } //end
};*/


#define CMD_DB 0xFE

u8 U2S::ReadByte(u16 a)
{
	*msg++ = CMD_DB;
	*msg++ = 0x01; // multiple commands may be packed

	*msg++ = 0x00;
	*msg++ = (a >> 8) & 0xFF;
	*msg++ = a & 0xFF;

	SendMsg();
	GetMsg();
	return msg[2];
}

void U2S::ReadBytes(u16 a, u8 c, u8 *buf)
{
	u16 u;

	if(c > 70) { //256 buffer on stk
		return;
	}

	*msg++ = CMD_DB;
	*msg++ = c; // multiple commands may be packed

	for(u=0; u<c; u++,a++) {
		*msg++ = 0x00; //read
		*msg++ = (a >> 8) & 0xFF;
		*msg++ = a & 0xFF;
	}

	SendMsg();
	GetMsg();

	for(u=0; u<c; u++) {
		buf[u] = msg[2 + u];
//		buf[u] = msg[2 + (u * 2)];
	}
}

void U2S::WriteByte(u16 a, u8 c)
{
	*msg++ = CMD_DB;
	*msg++ = 0x01; //1

	*msg++ = 0x01;
	*msg++ = (a >> 8) & 0xFF;
	*msg++ = a & 0xFF;
	*msg++ = c;

	SendMsg();
	GetMsg();
}

void U2S::WriteBytes(u16 a, u8 c, u8 *buf)
{
	u16 u;

	*msg++ = CMD_DB;
	*msg++ = c; //count

	for(u=0; u<c; u++,a++) {
		*msg++ = 0x01; //write
		*msg++ = (a >> 8) & 0xFF;
		*msg++ = a & 0xFF;
		*msg++ = buf[c];
	}

	SendMsg();
	GetMsg();
}

void U2S::WriteBit(u16 a, u8 an, u8 o)
{
	*msg++ = CMD_DB;
	*msg++ = 0x01; //1

	*msg++ = 0x02;
	*msg++ = (a >> 8) & 0xFF;
	*msg++ = a & 0xFF;
	*msg++ = an; // and mask
	*msg++ = o;  // or  mask

	SendMsg();
	GetMsg();
}

void U2S::DoDelayM(u8 d) //1ms units
{
	*msg++ = CMD_DB;
	*msg++ = 0x01;

	*msg++ = 0x03;
	*msg++ = d;

	SendMsg();
	GetMsg();
//	return msg[2];
}


void U2S::DoDelayU(u8 d) //4us units
{
	*msg++ = CMD_DB;
	*msg++ = 0x01;

	*msg++ = 0x04;
	*msg++ = d;

	SendMsg();
	GetMsg();
//	return msg[2];
}

/*
PutMsgDB:
	ld		r16,X+
	cpi		r16,0xFE
	breq	PMDgo
	ldi		r16,STATUS_CMD_UNKNOWN
	st		Y+,r16
	ret
PMDgo:
	ld		r19,X+ //number
	st		Y+,rnull

PMDnext:
	ld		r16,X+
	subi	r19,1
	brcc	PMDs0
	st		Y+,rnull
	ret

PMDs0: //memr
	cpi		r16,0
	brne	PMDs1
	ld		r31,X+
	ld		r30,X+
	ld		r16,Z
	st		Y+,r16
	rjmp	PMDnext
PMDs1: //memw
	cpi		r16,1
	brne	PMDs2
	ld		r31,X+
	ld		r30,X+
	ld		r16,X+
	st		Z,r16
	rjmp	PMDnext
PMDs2: //memwb
	cpi		r16,2
	brne	PMDs3
	ld		r31,X+
	ld		r30,X+
	ld		r16,X+ //and mask
	ld		r17,X+ //or  mask
	ld		r18,Z
	and		r18,r16
	or		r18,r17
	st		Z,r18
	rjmp	PMDnext
PMDs3:
	cpi		r16,3 //Delay ms
	brne	PMDs4
	ld		r16,X+
	rcall	Delay0
	rjmp	PMDnext
PMDs4:
	cpi		r16,4 // Delay 4us
	brne	PMDnext
	ld		r16,X+
	rcall	DelayU
	rjmp	PMDnext


DelayU: //4us at 8MHz
	push	r17
DUloop:
	dec		r16
	breq	DUret
	ldi		r17,9
DUnext:
	dec		r17
	brne	DUnext
	rjmp	DUloop
DUret:
	pop		r17
	rcall	PC+1
	rjmp	PC+1
	rjmp	PC+1
	nop
	ret
*/

//DB
//=============================================================================
