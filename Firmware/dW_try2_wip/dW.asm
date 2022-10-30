// vim:ts=4 sts=0 sw=4

//dW.asm
//debugWire module
//Copyright 2011 Rikus Wessels
//rikusw --- gmail --- com

//Attempt to make a working autobaud sw uart... not working yet

#if 0
#include <m16U2def.inc>
#else
#include <m32U2def.inc>
#endif

#define MODULE

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
BitPL:			.BYTE 1
BitPH:			.BYTE 1
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

//-------------------------------------
//Commands

#define C_SYNC 0x00
#define C_BREAK 0x01 //XXX
#define C_PRESCALER 0x02
#define C_SETMODE 0x4D // same as jtag mki

#define C_RESET 0x11
#define C_SETBAUD 0x12
#define C_DWTX 0x13
#define C_SETPERIOD 0x14
#define C_RUN 0x15

#define R_UNKNOWN 0x80

#define R_DOCAL 0x81
#define R_FORCECAL 0x82

#define R_SYNC 0xA5




//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//init

.cseg

#ifdef MODULE
.org THIRDBOOTSTART - 0x1000 //XXX 0xF40 / F80
dWStart:
	rjmp	dWEnd
dWEntry:
	ldi		r16,(dWApp-dWEntry)
	mov		r5,r16
	ret
dWApp:
#else
.org 0
#endif

	cli
	clr		rnull // NEVER set this to anything other than 0
	
	out		SREG,rnull
	ldi		r16,LOW (RAMEND)	//setup stack
	out		SPL,r16
	ldi		r17,HIGH(RAMEND)
	out		SPH,r17


	ldi		r16,0 // 16/1 == 16Mhz
	rcall	SetPrescaler

	sts		TCCR1A,rnull
	ldi		r16,(1<<CS10)
	sts		TCCR1B,r16


//-------------------------------------

	out		RSTDDR,rnull
	out		RSTPORT,rnull // just make sure


	ldi		r16,128 //XXX default bit period init
	mov		r8,r16
	mov		r9,rnull
	ldi		r16,192 //1.5 bitp
	mov		r6,r16
	mov		r7,rnull


	ldi		r16,(1<<PCINT0)
	sts		PCMSK0,r16
	sbi		PCIFR,PCIF0



//-------------------------------------
//enumerate

enum:
	sbis	SELPIN,SELBIT
	rjmp	GotoBL
	rcall	usb_task
	lds		r23,conf_nr
	tst		r23
	breq	enum

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

RunLoop:
	sbis	SELPIN,SELBIT
	rjmp	GotoBL

	//usb_task
	sts		UENUM,rnull
	lds		r16,UEINTX
	sbrc	r16,RXSTPI
	rcall	usb_process_request
	lds		r16,UDINT
	sbrc	r16,EORSTI
	rcall	usb_reset

	//detect break
	sbis	RSTPIN,RSTBIT
	rcall	DoCAL

	//detect pinchange (break missed...)
	sbic	PCIFR,PCIF0
	rcall	ForceCAL
	sbi		PCIFR,PCIF0

	//command handler
	rcall	usb_peek
	breq	RunLoop
	rcall	usb_getc
	rcall	CommonCommands
	rjmp	RunLoop

//---------------------------------------------------------

CommonCommands:
//---------------------------------
//Sync
	cpi		r16,C_SYNC
	brne	C_SYNC_E
	ldi		r16,R_SYNC
	rjmp	usb_putc
C_SYNC_E:

//---------------------------------
//Break
	cpi		r16,C_BREAK
	brne	C_BREAK_E
	rjmp	ForceCAL
C_BREAK_E:

//---------------------------------
//SetPrescaler
	cpi		r16,C_PRESCALER
	brne	C_PRESCALER_E
	rcall	usb_getc
	rjmp	SetPrescaler
C_PRESCALER_E:

//---------------------------------
//SetMode
	cpi		r16,C_SETMODE
	breq	SetMode

//---------------------------------
//Unknown command

	ldi		r16,R_UNKNOWN
	rcall	usb_putc
	ret

//---------------------------------------------------------

GotoBL:
	ldi		r16,0x80 //bootloader
	rjmp	SM

SetMode:
	rcall	usb_getc //back to bootloader/STK500
SM:	mov		r24,r16
	ori		r24,0x50
	ldi		ZH,0xCA
	ldi		ZL,0x53

	sts		TCCR1B,rnull //Turn off used stuff
	sts		PCMSK0,rnull
	out		RSTDDR,rnull
	out		RSTPORT,rnull
	jmp		THIRDBOOTSTART //jump to bootloader

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

ForceCAL:
	ldi		r16,R_FORCECAL
	rcall	usb_putc_nf
	sbi		RSTDDR,RSTBIT
	ldi		r16,8 //4 ms
	rcall	Delay0
	cbi		RSTDDR,RSTBIT
DoCAL:
	//wait high

DoCALH:
	//wait low -- (11 bits)

	//wait change x 9

	//calculate bit period

	//wait for stop bit

//-------------------------------------

	//set Z here !!
	ldi		r30,lo8(RXB)
	ldi		r31,hi8(RXB) //XXX temp!!!

	lds		r18,TCNT1L
	st		Z+,r18
	lds		r18,TCNT1H
	st		Z+,r18


	ldi		r19,5

//-------------------------------------

dcNextBit:

	ldi		r24,0
	ldi		r25,0xFF
waitlo:
	sbiw	r24,1
	breq	loto //dcTimeOut
	sbic	RSTPIN,RSTBIT
	rjmp	waitlo
loto:
	lds		r18,TCNT1L
	st		Z+,r18
	lds		r18,TCNT1H
	st		Z+,r18

//----------------------

	ldi		r24,0
	ldi		r25,0xFF
waithi:
	sbiw	r24,1
	breq	hito //dcTimeOut
	sbis	RSTPIN,RSTBIT
	rjmp	waithi
hito:
	lds		r18,TCNT1L
	st		Z+,r18
	lds		r18,TCNT1H
	st		Z+,r18


	dec		r19
	brne	dcNextBit


	// send via USB here
	ldi		r16,R_DOCAL
	rcall	usb_putc_nf

	ldi		r30,lo8(RXB)
	ldi		r31,hi8(RXB) //XXX temp!!!

	ldi		r17,22

nextb:
	ld		r16,Z+
	rcall	usb_putc_nf
	dec		r17
	brne	nextb
	rcall	usb_flush

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

StopLoop:
Mnext:
	sbis	SELPIN,SELBIT
	rjmp	GotoBL
	rcall	usb_getc

//---------------------------------
//Reset dW
	cpi		r16,C_RESET
	brne	C_RESET_E
	ldi		r16,0x07 //dW reset
	rcall	dW_TX
	ret //let the RunLoop catch the break
C_RESET_E:

//---------------------------------
//Set dW baud
	cpi		r16,C_SETBAUD
	brne	C_SETBAUD_E
	rcall	usb_getc
	rcall	dW_TX
	rcall	DoCAL
	rjmp	Mnext
C_SETBAUD_E:

//---------------------------------
//Set bit period
	cpi		r16,C_SETPERIOD
	brne	C_SETPERIOD_E
	rcall	usb_getc
	mov		r8,r16
	rcall	usb_getc
	mov		r9,r16

	//1.5 bit period
	mov		r6,r8
	mov		r7,r9
	lsr		r7
	ror		r6
	add		r6,r8
	adc		r7,r9

	rjmp	Mnext
C_SETPERIOD_E:

//---------------------------------
//dW TX
	cpi		r16,C_DWTX
	brne	C_DWTX_E
	mov		r20,r16 //tx counter
	rcall	usb_getc
	mov		r21,r16 //rx counter
C4na:
	rcall	usb_getc
	rcall	dW_TX
	ldi		r16,0x55
	brtc	C4xa
	ldi		r16,0x77
C4xa:	
	rcall	usb_putc_nf //debug
	dec		r20
	brne	C4na
C4nb:
	rcall	dW_RX
	rcall	usb_putc_nf
	ldi		r16,0xAA
	brtc	C4xb
	ldi		r16,0xEE
C4xb:	
	rcall	usb_putc_nf //debug
	dec		r20
	brne	C4nb
	rcall	usb_flush
	rjmp	Mnext
C_DWTX_E:

//---------------------------------
//Goto RunLoop
	cpi		r16,C_RUN
	brne	C_RUN_E
	ret
C_RUN_E:

//---------------------------------------------------------


Cend:

	rcall	CommonCommands
	rjmp	Mnext

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------


//r8+r9 == bit delay time
/*
	ldi		r16,20
	mov		r8,r16
	eor		r9,r9*/


dW_TX:  //p r8 r9 r16  c r10 r11 r19
	ldi		r19,10
	lds		r10,TCNT1L
	lds		r11,TCNT1H
	sbi		RSTDDR,RSTBIT //start bit
	add		r10,r8
	adc		r11,r9
	sec		//stop bit
	rjmp	dtx_first
dtx_next:
	add		r10,r8
	adc		r11,r9
dtx_first:
	sts		OCR1AH,r11
	sts		OCR1AL,r10
	sbi		TIFR1,OCF1A //clear the flag
	dec		r19
	breq	dtx_stop
	ror		r16
	brcc	dtx_lo
	nop
dtx_hi:
	sbis	TIFR1,OCF1A
	rjmp	dtx_hi
	cbi		RSTDDR,RSTBIT //rst high
	rjmp	dtx_next
dtx_lo:
	sbis	TIFR1,OCF1A
	rjmp	dtx_lo
	sbi		RSTDDR,RSTBIT //rst low
	rjmp	dtx_next

dtx_stop:
	clt
	ldi		r19,5
dtx_sw:
	dec		r19
	brne	dtx_sw //delay by 12+14=26 clocks before collision checking
dtx_sb:
	sbis	RSTPIN,RSTBIT
	set		// collision detected
	sbis	TIFR1,OCF1A
	rjmp	dtx_sb

	ldi		r19,10
dtx_d:
	dec		r19
	brne	dtx_d //delay by 30 clocks before returning
	ret

//-----------------------------------------------------------------------------


dW_RX:
	ldi		r16,0
	clt
	sbic	RSTDDR,RSTBIT
	rjmp	drx_ws
	set
	ldi		r16,0xAA //already 0 on entry
	ret


drx_ws: //wait for start bit (25 bytes timeout)
	ldi		r19,250
	lds		r10,TCNT1L
	lds		r11,TCNT1H
drx_wsn:
	add		r10,r8
	adc		r11,r9
	sts		OCR1AH,r11
	sts		OCR1AL,r10
	sbi		TIFR1,OCF1A //clear the flag
drx_wsw:
	sbis	RSTDDR,RSTBIT
	rjmp	drx_start
	sbis	TIFR1,OCF1A
	rjmp	drx_wsw
	dec		r19
	brne	drx_wsn
	set
	ldi		r16,0xA5 //timeout
	ret


drx_start:
	lds		r10,TCNT1L
	lds		r11,TCNT1H
	ldi		r19,9
	add		r10,r6
	adc		r11,r7 //wait 1.5
drx_next:
	sts		OCR1AH,r11
	sts		OCR1AL,r10
	sbi		TIFR1,OCF1A //clear the flag
	dec		r19
	breq	drx_stop
//get bit
	clc
drx_wait:
	sbis	TIFR1,OCF1A
	rjmp	drx_wait
	sbic	RSTDDR,RSTBIT
	sec
	ror		r16

	//wait 1
	add		r10,r8
	adc		r11,r9
	rjmp	drx_next


drx_stop:
	sbis	TIFR1,OCF1A
	rjmp	drx_stop
	sbis	RSTDDR,RSTBIT
	set
	ret

//leaving in the center of the stopbit
//wait at least 1 period before tx...

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
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

usb_putc:
	call	FLASHEND-3
usb_flush:
	ldi		r23,TX_EP
	sts		UENUM,r20
	lds		r16,UEINTX
	andi	r16,~((1<<TXINI) | (1<<FIFOCON))
	sts		UEINTX,r16
	ret

usb_process_request:
	jmp		FLASHEND-2
usb_reset:
	jmp		FLASHEND-1
usb_task:
	jmp		FLASHEND

//---------------------------------------------------------

#ifdef MODULE

// build magic to match U2S bootloader and modules
#define BUILDML 0x5A
#define BUILDMH 0xA5

.org THIRDBOOTSTART-0xE03
.db	BUILDML, BUILDMH, LOW(dWEnd-dWEntry), HIGH(dWEnd-dWEntry), 0, 0x4

dWEnd:

#endif

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------





//dcTimeOut:

//-------------------------------------

/*

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

Ddret: //XXX
DdFail: //XXX !!!!
	ret
*/


//----------------------
//output 0x06 -- r20r21 == delay
/*
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
*/





//---------------------------------
/*

C4: //Flush USB TX
	cpi		r16,4
	brne	C5
//	sbis	RSTPIN,RSTBIT
//	rcall	DoCAL

	ldi		r23,TX_EP	//rcall	usb_flush
	sts		UENUM,r20
	lds		r16,UEINTX
	andi	r16,~((1<<TXINI) | (1<<FIFOCON))
	sts		UEINTX,r16
	rjmp	Mnext
*/



/*usb_task:
	sbis	RSTPIN,RSTBIT
	rcall	DoCAL

	//usb_task
	sts		UENUM,rnull
	lds		r16,UEINTX
	sbrc	r16,RXSTPI
	rcall	usb_process_request//if this is called dW sync may be lost

	sbis	RSTPIN,RSTBIT
	rcall	DoCAL

	lds		r16,UDINT		//if (Is_usb_reset())
	sbrs	r16,EORSTI
	rjmp	UTend

	sbis	RSTPIN,RSTBIT
	rcall	DoCAL

	rcall	usb_reset
UTend:
	sbis	RSTPIN,RSTBIT
	rcall	DoCAL
	ret*/

//---------------------------------------------------------
/*
usb_getc:
//	sbis	RSTPIN,RSTBIT
//	rcall	DoCAL

	ldi		r16,RX_EP
	sts		UENUM,r16

	lds		r16,UEINTX
	sbrs	r16,RXOUTI
	rjmp	UGret0

//	sbis	RSTPIN,RSTBIT
//	rcall	DoCAL

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
//	sbis	RSTPIN,RSTBIT
//	rcall	DoCAL
	ret
*/
//---------------------------------------------------------


















