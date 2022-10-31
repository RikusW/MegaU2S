// vim:ts=4 sts=0 sw=4

#include "rtypes.h" 

#define COM1 1
#define COM2 2
#define COM3 3
#define COM4 4

//-----------------------------------------------

class RCom
{
public:
	RCom() { hCom = 0; timeout = 20; };
	~RCom() { Close(); };

	int Open(const char *p);
	int Open(int i);
	int Close();

	void SetTimeout(int);
	int SetBaudRate(const char *p);
	int Read(u8 *buf, int cnt);
	int Write(u8 *buf, int cnt);
	bool CanRead(int);

	int SetLines(int f);
	int ClrLines(int f);
	int GetLines();

	int SetDtr();
	int ClrDtr();
	int SetRts();
	int ClrRts();
	int SetBreak();
	int ClrBreak();

#ifdef WIN32
	void *hCom;
#else
	int hCom;
#endif
	int timeout;
};

//-----------------------------------------------
// RCom Linux

#ifndef WIN32

// see /usr/include/asm/termios.h
#define RCOM_DTR TIOCM_DTR //set
#define RCOM_RTS TIOCM_RTS

#define RCOM_DSR TIOCM_DSR //get
#define RCOM_CTS TIOCM_CTS

#define RCOM_RI TIOCM_RI
#define RCOM_CD TIOCM_CD

// used for set/clear break
#define RCOM_BREAK 0x100000

#endif

// RCom Linux
//-----------------------------------------------
// RCom Windows

#ifdef WIN32 

#define RCOM_DTR 1 //set
#define RCOM_RTS 2

#define RCOM_DSR MS_DSR_ON //get
#define RCOM_CTS MS_CTS_ON

#define RCOM_RI MS_RING_ON
#define RCOM_CD MS_RLSD_ON

// used for set/clear break
#define RCOM_BREAK 0x100000

#endif

// RCom Windows
//-----------------------------------------------

