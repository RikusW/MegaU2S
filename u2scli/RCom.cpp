// vim:ts=4 sts=0 sw=4
//-----------------------------------------------
// RCom rs232 wrapper for Linux and Windows
// 

#ifndef WIN32
// LINUX XXX!!!

#define BROKEN_LINUX_READ


#include "RCom.h"

#include <stdio.h>
#include <sys/ioctl.h>
#include <sys/types.h> // open
#include <sys/stat.h> // open
#include <fcntl.h>  // open
#include <unistd.h> // close
#include <string.h> // strncpy
#include <termios.h>
#include <stdlib.h> // atol


int RCom::Open(const char *p)
{
	hCom = open(p,O_RDWR | O_NOCTTY | O_SYNC);
	if(hCom == -1) {
		hCom = 0;
		printf("open %s fail\n",p);
		return 1;
	}
	return 0;
}
int RCom::Open(int i)
{
	char p[11];
	if(i < COM1 || i > COM4)
		i = COM1;
	strncpy(p,"/dev/ttyS0",11);
	p[9] = ('0' - COM1) + i;
	printf("%s\n",p); //DBG
	return Open(p);
}
int RCom::Close()
{
	int i = 1;
	if(hCom) {
		i = close(hCom); //XXX
		hCom = 0;
	}
	return i; //XXX
}

void RCom::SetTimeout(int to)
{
	if(hCom) {
		struct termios tty;
		tcgetattr(hCom, &tty);
		tty.c_cc[VTIME] = to;
		tcsetattr(hCom, TCSANOW, &tty);
	}
	timeout = to;
}

//eg "115200" or "115200 8N1" - 8N1 is default
int RCom::SetBaudRate(const char *p)
{
	uint t;
	int spd;
	char buf[100],*b;
	struct termios tty;
	
	// string parsing
	b = buf;
	strncpy(buf,p,98);
	buf[98] = buf[99] = 0;
	while(*b && *b!=' ') b++;
	*b++=0;
	if(!*b) {
		b = &buf[50];
		strncpy(b,"8N1",4);
	}

	// get old settings
	tcgetattr(hCom, &tty);

	// baudrate
	switch(atol(buf)) {
	case 300:	spd = B300;		break;
	case 600:	spd = B600;		break;
	case 1200:	spd = B1200;	break;
	case 2400:	spd = B2400;	break;
	case 4800:	spd = B4800;	break;
	case 9600:	spd = B9600;	break;
	case 19200:	spd = B19200;	break;
	case 38400:	spd = B38400;	break;
	case 57600:	spd = B57600;	break;
	case 115200:spd = B115200;	break;
	case 230400:spd = B230400;	break;
	case 460800:spd = B460800;	break;
	case 921600:spd = B921600;	break;
	default:	spd = -1;		break;
	}
	printf("spd = %s = %i\n",buf,spd); //DBG
	printf("bits = %s = ",b); //DBG

	if (spd != -1) {
		cfsetspeed(&tty, (speed_t)spd);
		//cfsetospeed(&tty, (speed_t)spd);
		//cfsetispeed(&tty, (speed_t)spd);
	}
  
	// data bits
	switch (b[0]) {
	case '5': t = CS5; break;
	case '6': t = CS6; break;
	case '7': t = CS7; break;
	default:  t = CS8; break;
	}
	tty.c_cflag = (tty.c_cflag & ~CSIZE) | t;
	printf("%x\n",t); //DBG

	/* Set into raw, no echo mode */
	tty.c_iflag =  IGNBRK;
	tty.c_lflag = 0;
	tty.c_oflag = 0;
	tty.c_cflag |= CLOCAL | CREAD;
	tty.c_cc[VMIN] = 1;
	tty.c_cc[VTIME] = timeout;

	// parity
	tty.c_cflag &= ~(PARENB | PARODD);
	if (b[1] == 'E')
		tty.c_cflag |= PARENB;
	else if (b[1] == 'O')
		tty.c_cflag |= (PARENB | PARODD);

	// stop bit/s
	if (b[2] == '2')
		tty.c_cflag |= CSTOPB;
	else
		tty.c_cflag &= ~CSTOPB;

	// apply settings
	tcsetattr(hCom, TCSANOW, &tty);

	return 1;
}


#include <poll.h>

bool RCom::CanRead(int to)
{
	pollfd p;
	p.fd = hCom;
	p.events = POLLIN;
	return poll(&p,1,to) > 0;
}

int RCom::Read(unsigned char *buf, int cnt)
{
#ifdef BROKEN_LINUX_READ
	int to = timeout;
	int i,r,o;
	for(i = cnt, o = 0; i > 0 && to;  i -= r, o += r, to--) {
		if(CanRead(100)) {
			r = read(hCom,buf+o,i);
		}else{
			return o;
		}
	}
	return o;
#else	
	return read(hCom,buf,cnt);
#endif	
}
int RCom::Write(unsigned char *buf, int cnt)
{
	int i = write(hCom,buf,cnt);
	return i;
}

int RCom::SetLines(int f)
{
	int b = f & (RCOM_DTR | RCOM_RTS);

	if(b) {
		ioctl(hCom,TIOCMBIS,&b);
	}

	if(f & RCOM_BREAK) {
		ioctl(hCom,TIOCSBRK,&b);
	}

	return 0;
}

int RCom::ClrLines(int f)
{
	int b = f & (RCOM_DTR | RCOM_RTS);

	if(b) {
		ioctl(hCom,TIOCMBIC,&b);
	}
	
	if(f & RCOM_BREAK) {
		ioctl(hCom,TIOCCBRK,&b);
	}

	return 0;
}

int RCom::GetLines() { int b = 0; ioctl(hCom,TIOCMGET,&b); return b; }
int RCom::SetDtr() { int b = RCOM_DTR; return ioctl(hCom,TIOCMBIS,&b); }
int RCom::ClrDtr() { int b = RCOM_DTR; return ioctl(hCom,TIOCMBIC,&b); }
int RCom::SetRts() { int b = RCOM_RTS; return ioctl(hCom,TIOCMBIS,&b); }
int RCom::ClrRts() { int b = RCOM_RTS; return ioctl(hCom,TIOCMBIC,&b); }
int RCom::SetBreak() { int b = 0; return ioctl(hCom,TIOCSBRK,&b); } //check
int RCom::ClrBreak() { int b = 0; return ioctl(hCom,TIOCCBRK,&b); } //check return


#endif

// RCom Linux
//-----------------------------------------------
// RCom Windows

#ifdef _WIN32

#include <windows.h>
#include <stdio.h>
#include "RCom.h"

int RCom::Open(const char *p)
{
	hCom = CreateFile(p,GENERIC_READ|GENERIC_WRITE,0,NULL,OPEN_EXISTING,0,NULL);
	if (hCom == INVALID_HANDLE_VALUE)
	{
		//dwError = GetLastError();    // handle error 
		printf("Cannot open %s\n",p);
		return 1;
	}
	return 0;
}

int RCom::Open(int i)
{
	char p[5];
	if(i < COM1 || i > COM4)
		i = COM1;
	strncpy(p,"COMX",5);
	p[3] = '0' + i;
	return Open(p);
}

int RCom::Close()
{
	int i = 1; // OK if already closed
	if(hCom) {
		i = CloseHandle(hCom);
		hCom = 0;
	}
	return !i;
}

void RCom::SetTimeout(int to)
{
	if(hCom) {
		COMMTIMEOUTS ct;
		ct.ReadIntervalTimeout = 100;
		ct.ReadTotalTimeoutMultiplier = 50;
		ct.ReadTotalTimeoutConstant = 150;
		ct.WriteTotalTimeoutMultiplier = 0;
		ct.WriteTotalTimeoutConstant = 0;
		SetCommTimeouts(hCom,&ct);
	}
	timeout = to;
}


int RCom::SetBaudRate(const char *p)
{
	UINT t;
	int spd;
	DCB dcb;
	char buf[100],*b;
	
	// string parsing
	b = buf;
	strncpy(buf,p,98);
	buf[98] = buf[99] = 0;
	while(*b && *b!=' ') b++;
	*b++=0;
	if(!*b) {
		b = &buf[50];
		strncpy(b,"8N1",4);
	}

	// get old settings
	if (GetCommState(hCom, &dcb)) {
		printf("GetCommState fail\n"); //XXX
		return false;
	}

	// baudrate
	switch(atol(buf)) {
	case 300:	spd = CBR_300;		break;
	case 600:	spd = CBR_600; 		break;
	case 1200:	spd = CBR_1200;		break;
	case 2400:	spd = CBR_2400;		break;
	case 4800:	spd = CBR_4800;		break;
	case 9600:	spd = CBR_9600;		break;
	case 19200:	spd = CBR_19200;	break;
	case 38400:	spd = CBR_38400;	break;
	case 57600:	spd = CBR_57600;	break;
	case 115200:spd = CBR_115200;	break;
	case 230400:spd =     230400;	break; //untested
	case 460800:spd =     460800;	break; //untested
	case 921600:spd =     921600;	break; //untested

	default:	spd = -1;			break;
	}
	printf("spd = %s = %i\n",buf,spd); //DBG
	printf("bits = %s\n",b); //DBG

	if (spd != -1) {
		dcb.BaudRate = spd;
	}
	
	// data bits
	switch (b[0]) {
	case '5': t = 5; break;
	case '6': t = 6; break;
	case '7': t = 7; break;
	default:  t = 8; break;
	}
	dcb.ByteSize = t;
	//printf("bits = %x\n",t);

	// parity
	switch(b[1]) {
	case 'N': t = NOPARITY; break;
	case 'O': t = ODDPARITY; break;
	case 'E': t = EVENPARITY; break;
	case 'M': t = MARKPARITY; break;
	case 'S': t = SPACEPARITY; break;
	}
	dcb.Parity = t;

	// stop bit/s
	dcb.StopBits = ONESTOPBIT;
	if (b[2] == '2')
		dcb.StopBits = TWOSTOPBITS;

	// apply settings
	if (SetCommState(hCom, &dcb)) {
		printf("SetCommState fail\n");
		return false;
	}

	return 1;
};

bool RCom::CanRead(int to)
{
/*	pollfd p;
	p.fd = hCom;
	p.events = POLLIN;
	return poll(&p,1,to) > 0;*/
	return true; //XXX
}

int RCom::Read(u8 *buf, int cnt)
{
	DWORD d;
	if(ReadFile(hCom,buf,cnt,&d,0))
		return d;
	else
		return -1;
}

int RCom::Write(u8 *buf, int cnt)
{
	DWORD d;
	if(WriteFile(hCom,buf,cnt,&d,0))
		return d;
	else
		return -1;

}

int RCom::SetLines(int f)
{
	if(f & RCOM_DTR)
		EscapeCommFunction(hCom,SETDTR);
	if(f & RCOM_RTS)
		EscapeCommFunction(hCom,SETRTS);
	if(f & RCOM_BREAK)
		EscapeCommFunction(hCom,SETBREAK);

	return 0;
}

int RCom::ClrLines(int f)
{
	if(f & RCOM_DTR)
		EscapeCommFunction(hCom,CLRDTR);
	if(f & RCOM_RTS)
		EscapeCommFunction(hCom,CLRRTS);
	if(f & RCOM_BREAK)
		EscapeCommFunction(hCom,CLRBREAK);

	return 0;
}

int RCom::GetLines() { DWORD b; GetCommModemStatus(hCom,&b); return b; };
int RCom::SetDtr()   { return EscapeCommFunction(hCom,SETDTR);   };
int RCom::ClrDtr()   { return EscapeCommFunction(hCom,CLRDTR);   };
int RCom::SetRts()   { return EscapeCommFunction(hCom,SETRTS);   };
int RCom::ClrRts()   { return EscapeCommFunction(hCom,CLRRTS);   };
int RCom::SetBreak() { return EscapeCommFunction(hCom,SETBREAK); };
int RCom::ClrBreak() { return EscapeCommFunction(hCom,CLRBREAK); };


#endif

//----------------------------------------------------------------------------
// TESTING CODE

#if 0

RCom c;

void ShowIt(int t)
{
	printf("%s %s - %s %s %s %s",
		t & RCOM_RTS ? "RTS":"rts",
		t & RCOM_DTR ? "DTR":"dtr",
		t & RCOM_CTS ? "CTS":"cts",
		t & RCOM_DSR ? "DSR":"dsr",
		t & RCOM_CD  ? "CD 12V":"cd  0V",
		t & RCOM_RI  ? "RI 0V":"ri 5V"
		);
}

// play with the modemlines
void TestIt()
{
	int i,j,t,ot;
	char ch;
	
	if(c.Open(COM1)) {
		printf("open COM1 fail\n");
		return;
	}

	c.ClrBreak();
redo:
	ch = getchar();
	switch(ch) {
	case 'B':
		c.SetBreak();
		break;
	case 'b':
		c.ClrBreak();
		break;
	case 'R':
		c.SetRts();
		break;
	case 'r':
		c.ClrRts();
		break;
	case 'D':
		c.SetDtr();
		break;
	case 'd':
		c.ClrDtr();
		break;
	case 'Q':
	case 'q':
		return;
	case 'g':
		ShowIt(c.GetLines());
		printf("\n");
		//printf("0x%x\n",c.GetLines());
	default:
		//printf("ch=%x\n",ch);
		goto redo;
	}

//	SetPriorityClass(GetCurrentProcess(),REALTIME_PRIORITY_CLASS);
//	SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_TIME_CRITICAL);
	t=ot=0;
	for(i=0; i<150; i++) {
		t = c.GetLines();
		if(t != ot)
		{
			ot = t;
			ShowIt(t);
			printf(" - %i\n",i);//,GetTickCount());
		}else
		for(j=0; j<20000; j++);
	}
//	SetPriorityClass(GetCurrentProcess(),NORMAL_PRIORITY_CLASS);
//	SetThreadPriority(GetCurrentThread(),THREAD_PRIORITY_NORMAL);
	goto redo;

	c.Close(); //???!!!
}

// query the modem
void TestIt2()
{
	int k;
	char buf[2000];
	for(int i=0; i<2000; i++) buf[i]=0;

	if(c.Open(COM2)) {
		printf("open COM2 fail\n");
		return 1;
	}
	
	c.SetBaudRate("115200 8N1");

	printf("==========\n");
//	c.Write("at+csq\r",7);
	c.Write("at+cgdcont?\r",12);

	while(1) {
		for(int j = c.Read(buf,100),i=0; i<j; i++) {
			if(buf[i] == '\r')
				buf[i] = '#';
//			if(buf[i] == 10)//'\n')
//				buf[i] = '!';
//			k = buf[i];
//			printf("%x~",k);
			printf("%c",buf[i]);
		}
		fflush(stdout);	//printf("\n");
	}

	c.Close(); //???!!!
}

int main(int argc, char *argv[])
{
	TestIt();
	return 0;
}

#endif


