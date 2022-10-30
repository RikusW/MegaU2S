// JtagIce wrapper for the U2S board
// Copyright 2010 2011 Rikus Wessels
// Version 20110421

#if 0
#include <m16U2def.inc>
#else
#include <m32U2def.inc>
#endif

//-------------------------------------------------------------------
//User adjustable JTAG pinout

#define JPIN PINB
#define JDDR DDRB
#define JPORT PORTB
#define JRST 0
#define JTCK 1
#define	JTDI 2
#define JTDO 3
#define JTMS 7

//-------------------------------------------------------------------
// variables from the U2S bootloader

.dseg
conf_nr:		.BYTE 1
line_flags:		.BYTE 1 // 1=coding 2=status 4=break
line_coding:	.BYTE 7
line_status:	.BYTE 2
line_break:		.BYTE 2
sel:			.BYTE 1

//-------------------------------------------------------------------

.cseg
.org THIRDBOOTSTART - 0xC80

JTStart:
	rjmp	JTEnd

JTEntry:
	ldi		r16,(JTApp-JTEntry)
	mov		r5,r16
	ret

//-------------------------------------------------------------------

#define U2S
#define SETUPBAUD() /##/ignored
#define SETUPSERIAL() /##/ignored

#define getc    usb_getc
#define putc    usb_putc
#define putc_nf usb_putc_nf
#define flush   usb_flush
#define peek    usb_peek

#include "JtagIce.asm"

//-------------------------------------------------------------------
//USB CDC

usb_peek:
	call	FLASHEND   //usb_task
	jmp		FLASHEND-5 //usb_peek

usb_getc:
	jmp		FLASHEND-4 //usb_getc

usb_putc_nf:
	jmp		FLASHEND-3 //usb_putc_nf

usb_putc:
	rcall	usb_putc_nf

usb_flush:
	lds		r16,UEINTX
	andi	r16,~((1<<TXINI) | (1<<FIFOCON))
	sts		UEINTX,r16
	ret

Delay:	// r16 = delay in ms
	jmp		FLASHEND-7

//-------------------------------------

DelayU: //4us at 8MHz
#if 0
	jmp		FLASHEND-8
#else
	push	r17 // there is enough space here, so put it in
DUloop:
	dec		r16 // this will eliminate a jmp + rjmp
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
#endif

//-------------------------------------------------------------------

// build magic to match U2S bootloader and modules
#define BUILDML 0x5A
#define BUILDMH 0xA5

.org THIRDBOOTSTART-0x583
.db	BUILDML, BUILDMH, LOW(JTEnd-JTEntry), HIGH(JTEnd-JTEntry), 0, 0x3

JTEnd:

