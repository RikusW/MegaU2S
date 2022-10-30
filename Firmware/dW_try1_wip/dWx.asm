
//dW.asm
//debugWire module
//Copyright 2011 Rikus Wessels
//rikusw --- gmail --- com

#if 0
#include <m16U2def.inc>
#else
#include <m32U2def.inc>
#endif

//-------------------------------------

#define INT_EP		0x01
#define TX_EP		0x03
#define RX_EP		0x04

//-------------------------------------

.dseg
conf_nr:		.BYTE 1
line_flags:		.BYTE 1 // 1=coding 2=status 4=break
line_coding:	.BYTE 7
line_status:	.BYTE 2
line_break:		.BYTE 2
select:			.BYTE 1

line_irq:		.BYTE 1
line_err:		.BYTE 1

rput:			.BYTE 1
rget:			.BYTE 1
UPort:			.BYTE 1
RXB:			.BYTE 256


//-------------------------------------

.def rnull = r2 // this will always be 0 - NEVER set to anything else

#define lo8(x) (x & 0xFF)
#define hi8(x) ((x >> 8) & 0xFF)

#define mlo8(x) ((-x) & 0xFF)
#define mhi8(x) (((-x) >> 8) & 0xFF)

//-------------------------------------

#define SELBIT  4
#define SELPORT PORTC
#define SELDDR  DDRC
#define SELPIN	PINC

#define LEDBIT	2
#define LEDPORT PORTC
#define LEDDDR	DDRC

#define RSTPORT PORTB
#define RSTPIN PINB
#define RSTDDR DDRB
#define RSTBIT 0


//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//init

.cseg

	cli
	clr		rnull // NEVER set this to anything other than 0
	
	out		SREG,rnull
	ldi		r16,LOW (RAMEND)	//setup stack
	out		SPL,r16
	ldi		r17,HIGH(RAMEND)
	out		SPH,r17


	ldi		r16,0 // 16/1 == 16Mhz
	rcall	SetPrescaler

//-------------------------------------

	out		RSTDDR,rnull
	out		RSTPORT,rnull

//-------------------------------------
//enumerate

enum:
	rcall	usb_task
	lds		r23,conf_nr
	tst		r23
	breq	enum

	rcall	ForceCAL

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//main loop

Mnext:
	sbis	RSTPIN,RSTBIT
	rcall	dW_RX

	sbic	SELPIN,SELBIT //PINC4
	rjmp	BLEnd

	out		RSTDDR,rnull

	ldi		r24,0xD0 //bootloader
	ldi		ZH,0xCA
	ldi		ZL,0x53
	jmp		THIRDBOOTSTART //jump to bootloader

BLEnd:

//-------------------------------------

	rcall	usb_task

//-------------------------------------
//USB RX

	rcall	ugetc
	push	r16
	rcall	ugetc
	push	r16

//-------------------------------------


	sbis	RSTPIN,RSTBIT
	rcall	dW_RX



	sbis	RSTPIN,RSTBIT
	rcall	dW_RX


	sbis	RSTPIN,RSTBIT
	rcall	dW_RX


	sbis	RSTPIN,RSTBIT
	rcall	dW_RX


//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------


usb_task:
	sbis	RSTPIN,RSTBIT
	rcall	dW_RX

	//usb_task
	sts		UENUM,rnull
	lds		r16,UEINTX
	sbrc	r16,RXSTPI
	rcall	usb_process_request//if this is called dW sync may be lost

	lds		r16,UDINT		//if (Is_usb_reset())
	sbrs	r16,EORSTI
	rjmp	UTend

	sbis	RSTPIN,RSTBIT
	rcall	dW_RX

	rcall	usb_reset
UTend:
	sbis	RSTPIN,RSTBIT
	rcall	dW_RX
	ret

//---------------------------------------------------------

ugetc:
	sbis	RSTPIN,RSTBIT
	rcall	dW_RX

	ldi		r16,RX_EP
	sts		UENUM,r16

	lds		r16,UEINTX
	sbrs	r16,RXOUTI
	rjmp	UGret0

	sbis	RSTPIN,RSTBIT
	rcall	dW_RX

	sbrs	r16,RWAL
	rjmp	UGack
	lds		r16,UEDATX
	rjmp	UGret
UGack:
	lds		r16,UEINTX
	andi	r16,~((1<<RXOUTI)|(1<<FIFOCON))
	sts		UEINTX,r16
UGret0:
	ldi		r16,0
UGret:
	sbis	RSTPIN,RSTBIT
	rcall	dW_RX
	ret

//---------------------------------------------------------

dW_TX:

//----------------------
//output 0x06 -- r20r21 == delay

	ldi		r17,9
	ldi		r18,0x06 //disable dW command
	clc
DdBit:
	movw	r24,r20
	brcs	DdSet
	sbi		RSTDDR,RSTBIT //rst low
	rjmp	DdBDly
DdSet:
	cbi		RSTDDR,RSTBIT //rst pullup
	nop
DdBDly: //8 clks
	sbiw	r24,1
	breq	DdBB  //--> round trip == 16 clks
	nop
	rjmp	PC+1
	rjmp	DdBDly
DdBB:
	nop
	ror		r18
	dec		r17
	brne	DdBit
DdLast:
	cbi		RSTDDR,RSTBIT
	ret

//---------------------------------------------------------

dW_RX: //c r20 r21 r22 r23






	ret

//---------------------------------------------------------
ForceCAL:
	sbi		RSTDDR,RSTBIT
	ldi		r16,2 //2 ms
	rcall	Delay0
	cbi		RSTDDR,RSTBIT
DoCAL:
	ldi		r24,0x00
	ldi		r25,0xA0 //15.36mS -- 125kHz Clock dW = 1kHz
DdWait: //6 cycles
	sbiw	r24,1
	breq	Ddret
	sbic	RSTPIN,RSTBIT
	rjmp	DdWait

//----------------------
//baud detection for --Start0 0x55 Stop1--

DdStart:
	ldi		r19,9
	ldi		r20,0x00
	ldi		r21,0x21

DdNext:
	in		r17,RSTPIN
	ldi		r24,0xFF
	ldi		r25,0x20 //2mS

DdLoop: // 8 clks 500nS
	sbiw	r24,1 //	dec		r16
	breq	DdFail //too slow = 10 bits
	in		r18,RSTPIN
	eor		r18,r17
	sbrs	r18,RSTBIT
	rjmp	DdLoop

	//if(r20 >= r24) r20 = r24; -- r20 = MIN(r20,r24)
	cp		r20,r24
	cpc		r21,r25
	brcs	Dds
	movw	r20,r24
Dds:
	dec		r19
	brne	DdNext

//----------------------

	ldi		r24,0x00
	ldi		r25,0x21
	sub		r24,r20 // shouldn't ever be 0
	sbc		r25,r21 // r24r25*8 == clks
	sbiw	r24,1
	breq	DdFail //too fast
	movw	r20,r24

	ldi		r16,255 //510uS
	tst		r21
	brne	Dddu
	cpi		r20,128
	brcc	Dddu

	ldi		r16,128 //256uS
	cpi		r20,33
	brcc	Dddu

	ldi		r16,64 //128uS
Dddu:
	rcall	DelayU

//	ldi		r16,1 // 500uS
//	rcall	Delay



	ret

//---------------------------------------------------------
// Bootloader functions

SetPrescaler:
	jmp		FLASHEND-9

DelayU:
	jmp		FLASHEND-8

Delay0:
	jmp		FLASHEND-7

usb_peek:
	jmp		FLASHEND-5

usb_getc:
	jmp		FLASHEND-4

usb_putc_ready:
	ldi		r23,TX_EP
	sts		UENUM,r20
usb_in_ready:
	lds		r23,conf_nr
	tst		r23
	breq	upr
	lds		r23,UEINTX
	andi	r23,(1<<RWAL)
upr:
	ret

usb_putc_nf:
	jmp		FLASHEND-3

usb_flush:
	lds		r16,UEINTX
	andi	r16,~((1<<TXINI) | (1<<FIFOCON))
	sts		UEINTX,r16
	ret

usb_process_request:
	jmp		FLASHEND-2
usb_reset:
	jmp		FLASHEND-1

//---------------------------------------------------------
//---------------------------------------------------------





















