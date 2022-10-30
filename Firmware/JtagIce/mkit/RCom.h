// vim:ts=4 sts=0 sw=4

#define COM1 1
#define COM2 2
#define COM3 3
#define COM4 4

//-----------------------------------------------
// RCom Linux

#ifndef _WIN32

#include <unistd.h>
#include <sys/ioctl.h>

// see /usr/include/asm/termios.h
//set
#define RCOM_DTR TIOCM_DTR
#define RCOM_RTS TIOCM_RTS

//get
#define RCOM_DSR TIOCM_DSR
#define RCOM_CTS TIOCM_CTS

#define RCOM_RI TIOCM_RI
#define RCOM_CD TIOCM_CD

// used for set/clear break
#define RCOM_BREAK 0x100000

class RCom
{
public:
	RCom() { hCom = 0; };
	~RCom() { Close(); };

	int Open(const char *p);
	int Open(int i);
	int Close();

	int SetBaudRate(const char *p);
	int Read(unsigned char *buf, int cnt);//  { return read(hCom,buf,cnt);  } //XXX
	int Write(unsigned char *buf, int cnt);// { return write(hCom,buf,cnt); } //XXX

	int SetLines(int f);
	int ClrLines(int f);
	int GetLines() { int b = 0; ioctl(hCom,TIOCMGET,&b); return b; }

	int SetDtr() { int b = RCOM_DTR; return ioctl(hCom,TIOCMBIS,&b); }
	int ClrDtr() { int b = RCOM_DTR; return ioctl(hCom,TIOCMBIC,&b); }
	int SetRts() { int b = RCOM_RTS; return ioctl(hCom,TIOCMBIS,&b); }
	int ClrRts() { int b = RCOM_RTS; return ioctl(hCom,TIOCMBIC,&b); }
	int SetBreak() { int b = 0; return ioctl(hCom,TIOCSBRK,&b); } //check
	int ClrBreak() { int b = 0; return ioctl(hCom,TIOCCBRK,&b); } //check return
	
	int hCom;
};

#endif

// RCom Linux
//-----------------------------------------------
// RCom Windows

#ifdef _WIN32 

//set
#define RCOM_DTR 1
#define RCOM_RTS 2

//get
#define RCOM_DSR MS_DSR_ON
#define RCOM_CTS MS_CTS_ON

#define RCOM_RI MS_RING_ON
#define RCOM_CD MS_RLSD_ON

// used for set/clear break
#define RCOM_BREAK 0x100000

class RCom
{
public:
	RCom() { hCom = 0; };
	~RCom() { Close(); };

	int Open(const char *p);
	int Open(int i);
	int Close();
	
	int SetBaudRate(const char *p);
	DWORD Read(unsigned char *buf, int cnt);
	DWORD Write(unsigned char *buf, int cnt);

	int SetLines(int f);
	int ClrLines(int f);
	int GetLines() { DWORD b; GetCommModemStatus(hCom,&b); return b; };

	int SetDtr()   { return EscapeCommFunction(hCom,SETDTR);   };
	int ClrDtr()   { return EscapeCommFunction(hCom,CLRDTR);   };
	int SetRts()   { return EscapeCommFunction(hCom,SETRTS);   };
	int ClrRts()   { return EscapeCommFunction(hCom,CLRRTS);   };
	int SetBreak() { return EscapeCommFunction(hCom,SETBREAK); };
	int ClrBreak() { return EscapeCommFunction(hCom,CLRBREAK); };
	
	HANDLE hCom;
};

#endif

// RCom Windows
//-----------------------------------------------

