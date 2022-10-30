//USART.asm
//USB to USART io module
//Copyright 2011 Rikus Wessels
//This is free for personal or non-profit use, for commercial use contact me.
//rikusw --- gmail --- com
/*
UART Pinout:

D0 - I   DCD
D1 - I   RI
D2 - I   RX
D3 - O TX
D4 - O DTR
D5 - I   DSR
D6 - O RTS  Done in hardware on ATmega32U2
D7 - I   CTS  Done in hardware on ATmega32U2
Pullups are on and DTR is high by default. (PORTD = 0xB7  DDRD = 0x58)
*/
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
rsvd1:			.BYTE 4
ubl:			.BYTE 1 // 04 vtg
ubh:			.BYTE 1 // 05 vad
rsvd2:			.BYTE 3
rs232:			.BYTE 1 // 09

line_irq:		.BYTE 1
line_err:		.BYTE 1

rput:			.BYTE 1
rget:			.BYTE 1
UPort:			.BYTE 1
RXB:			.BYTE 256

#define RS232_BAUD_NONSTD   0
#define RS232_BAUD_OVERRIDE 1
#define RS232_HW_FLOW_CTRL  2
#define RS232_SETUP_OVERRIDE 3

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


//---------------------------------------------------------

.cseg

#ifdef MODULE
.org THIRDBOOTSTART - 0xE00
USARTStart:
	rjmp	USARTEnd
USARTEntry:
	ldi		r16,(USARTApp-USARTEntry)
	mov		r5,r16
	ret
USARTApp:
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

//-------------------------------------
//Setup ports

	lds		r16,rs232
	sbrc	r16,RS232_SETUP_OVERRIDE
	rjmp	skip_uart_setup

	out		DDRB,rnull
	out		PORTB,rnull

	ldi		r17,0x58
	out		DDRD,r17
	ldi		r17,0xB7
	out		PORTD,r17


/*	in		r16,PORTC  //from bootloader
	andi	r16,0x0F
	ori		r16,(1<<SELBIT)
	out		PORTC,r16
	in		r16,DDRC
	andi	r16,0x0F
	ori		r16,0x04
	out		PORTC,r16*/


//-------------------------------------
//Setup USART

	sbrc	r16,RS232_HW_FLOW_CTRL
	ldi		r17,(1<<RTSEN)|(1<<CTSEN) //on
	sbrs	r16,RS232_HW_FLOW_CTRL
	ldi		r17,0 //off
	sts		UCSR1D,r17

	sbrc	r16,RS232_BAUD_OVERRIDE
	rjmp	baud_over
	sts		UBRR1H,rnull
	ldi		r17,207   //9600  16MHZ U2X
	sts		UBRR1L,r17
	rjmp	baud_norm
baud_over:
	lds		r16,ubh
	sts		UBRR1H,r16
	lds		r16,ubl
	sts		UBRR1L,r16
baud_norm:

	ldi		r16,(1<<U2X1)
	sts		UCSR1A,r16

	ldi		r16,(1<<UCSZ11)|(1<<UCSZ10) //8N1
	sts		UCSR1C,r16

	rcall	F3go
	ldi		r16,(1<<RXEN1)|(1<<TXEN1)
	sts		UCSR1B,r16

skip_uart_setup:

	//Timer0
	out		TCCR0A,rnull
	out		TCCR0B,rnull
	sts		TIMSK0,rnull
	sbi		TIFR0,TOV0 //clear it

	//RX Ring buffer
	sts		rput,rnull
	sts		rget,rnull
	sts		UPort,rnull

	//default state
	sts		line_err,rnull
	ldi		r16,0xFF //invalid value...
	sts		line_irq,r16

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//Main Loop
Mnext:
//-------------------------------------

	rcall	RS232RX //~40

//-------------------------------------

	//Jump back to bootloader ?
	sbic	SELPIN,SELBIT //PINC4
	rjmp	BLEnd

	out		DDRD,rnull
	out		PORTD,rnull
	sts		UCSR1B,rnull //UART off
	out		TCCR0B,rnull //Timer0 off

	ldi		r24,0xD0 //bootloader - Will get incremented to 0xD1 because of Select switch...
	ldi		ZH,0xCA
	ldi		ZL,0x53
	jmp		THIRDBOOTSTART //jump to bootloader
BLEnd:

//-------------------------------------
//usb_task

	rcall	usb_task //~35

//-------------------------------------

	rcall	RS232RX //~40

//-------------------------------------
//USB OUT to RS232 TX

	rcall	usb_peek //~30
	breq	UsbOutEnd
	lds		r16,UCSR1A
	sbrs	r16,UDRE1
	rjmp	UsbOutEnd
	cbi		LEDPORT,LEDBIT //led on

	rcall	RS232RX //~36

	rcall	usb_getc_np //~22
	sts		UDR1,r16
	sbi		LEDPORT,LEDBIT //led off
UsbOutEnd:

//-------------------------------------

	rcall	RS232RX //~32 / ~25

//-------------------------------------

Flags:
	lds		r24,line_flags
	sts		line_flags,rnull
	tst		r24
	breq	Fend

//---------------------------
//F1:
	sbrs	r24,0 //coding
	rjmp	F2

	rcall	SetLineCoding
	rcall	RS232RX

//---------------------------
F2:
	sbrs	r24,1 //status
	rjmp	F3

	lds		r16,line_status
	com		r16
//	ldi		r17,3
//	eor		r16,r17
	in		r17,PORTD
	bst		r16,0
	bld		r17,4
//	bst		r16,1 XXX
//	bld		r17,6 XXX
	out		PORTD,r17

//	D0 DTR
//	D1 RTS

//---------------------------
F3: //	rcall	RS232RX //~21

	sbrs	r24,2 //break
	rjmp	Fend

	lds		r20,line_break
	lds		r21,line_break+1

	cp		r20,rnull //if(break==0)
	cpc		r21,rnull
	brne	F3null
F3go:
	ldi		r16,(1<<RXEN1)|(1<<TXEN1)
	sts		UCSR1B,r16
	rjmp	Fend

F3null:
	ldi		r16,0xFF //if(break==-1)
	cp		r20,r16
	cpc		r21,r16
	brne	F3min
F3break:
	ldi		r16,(1<<RXEN1) //port is set to - low out already
	sts		UCSR1B,r16
	rjmp	Fend
	
F3min:
	cbi		LEDPORT,LEDBIT //led on //XXX debug code
/*	rcall	F3break
	lsl		r20
	rol		r21 // *2 */


	//set timer r2021 = 0.5ms  /8


//line_break:		.BYTE 2

Fend:

	//if timer ovf
	//rcall	F3go
//-------------------------------------

	rcall	RS232RX //~40

//-------------------------------------
//USB interrupt

	lds		r18,line_err
	lds		r17,line_irq //Saved

	//load CD RI DSR ~10
	ldi		r16,0
	sbis	PIND,0 //CD
	ori		r16,1
	sbis	PIND,1 //RI
	ori		r16,0x08
	sbis	PIND,5 //DSR
	ori		r16,2
	andi	r16,0xB
	sts		line_irq,r16

	andi	r18,0x1C //if(line_err || line_irq != Saved)
	brne	UsbInt
	cp		r16,r17
	breq	UsbIntEnd
	sts		line_err,rnull
UsbInt:

	bst		r18,2 //UPE
	bld		r16,5 //PE

	bst		r18,3 //DOR
	bld		r16,6 //OverRun

	bst		r18,4 //FE
	bld		r16,4 //FE
	bld		r16,2 //BREAK ???

	rcall	RS232RX //~27

	ldi		r17,INT_EP //if(Ready to transmit)
	sts		UENUM,r17
	rcall	usb_in_ready //~16
	breq	UsbIntEnd

	ldi		r17,0xA1 //USB_SETUP_GET_CLASS_INTER // bmRequestType
	sts		UEDATX,r17
	ldi		r17,0x20 //SETUP_CDC_BN_SERIAL_STATE // bNotification
	sts		UEDATX,r17

	sts		UEDATX,rnull // wValue (zero)
	sts		UEDATX,rnull

	rcall	RS232RX //~29

	sts		UEDATX,rnull // wIndex (Interface)
	sts		UEDATX,rnull

	ldi		r17,2
	sts		UEDATX,r17   // wLength (data count = 2)
	sts		UEDATX,rnull


	sts		UEDATX,r16   // data 0: LSB first of serial state
	sts		UEDATX,rnull // data 1: MSB follows

	rcall	usb_flush //~14 + 13 -> 27

UsbIntEnd:

//-------------------------------------

	rcall	RS232RX //~20 / ~27

//-------------------------------------

	rcall	UsbIn
	rjmp	Mnext
//}

//Main Loop
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//RS232 RX to USB IN

RS232RX: //~12-0 / 43-1 / 69-2
	lds		r19,UCSR1A //if(UCSR1A & (1<<RXC1))
	sbrs	r19,RXC1
rs232ret:
	ret

	lds		r17,rput
	lds		r20,rget
	dec		r20
	cp		r17,r20
	breq	rs232ret //ringbuffer full...

	cbi		LEDPORT,LEDBIT //led on

	lds		r20,line_err //line_err |= UCSR1A;
	or		r20,r19
	sts		line_err,r20

	lds		r19,UDR1
	ldi		r30,lo8(RXB)
	ldi		r31,hi8(RXB)
	add		r30,r17
	adc		r31,rnull
	st		Z,r19
	inc		r17
	sts		rput,r17

	sbi		LEDPORT,LEDBIT //led off

	rjmp	RS232RX

//---------------------------------------------------------

UsbIn: //IN
	lds		r17,rput
	lds		r18,rget
	cp		r17,r18
	breq	UsbInEnd
	rcall	usb_putc_ready //~19
	brne	UsbFirst

UsbNext:
	lds		r23,UEINTX
	andi	r23,(1<<RWAL)
	brne	UsbRW
	rcall	usb_flush //~14
	rjmp	UsbExit //after 32 bytes - go around main loop once
UsbRW:
	cp		r17,r18
	breq	UsbExit //ringbuffer empty
UsbFirst:
	ldi		r30,lo8(RXB)
	ldi		r31,hi8(RXB)
	add		r30,r18
	adc		r31,rnull
	ld		r16,Z
	inc		r18
	sts		rget,r18

	sts		UEDATX,r16 //usb_putc_nf_fast
	rcall	RS232RX //~40
	rjmp	UsbNext

UsbExit: //setup timer to flush after 2ms idle time
	ldi		r16,0x70
	out		TCNT0,r16
	ldi		r16,(1<<CS02) // /256 /256 --> 2ms ovf
	out		TCCR0B,r16

UsbInEnd:
	//flush after 2ms timeout
	sbis	TIFR0,TOV0
	rjmp	UsbNoFlush
	out		TCCR0B,rnull
	sbi		TIFR0,TOV0 //clear it

	ldi		r23,TX_EP
	sts		UENUM,r23
	rcall	usb_flush //~14
UsbNoFlush:
	ret

//---------------------------------------------------------

SetLineCoding:
	ldi		r30,lo8(line_coding)
	ldi		r31,hi8(line_coding)
	ld		r16,Z+ //dwDTERate 
	ld		r17,Z+
	ld		r18,Z+
	ld		r19,Z+ //discard the msb

	lds		r20,rs232
	sbrc	r20,RS232_SETUP_OVERRIDE
	ret

	sbrc	r20,RS232_BAUD_OVERRIDE
	rjmp	slc_baud_over

	sbrc	r20,RS232_BAUD_NONSTD
	rjmp	slc_baud_nonstd

	ldi		r19,0x80
	ldi		r20,0x84
	ldi		r21,0x1E //2,000,000 = 0x1E8480
	rjmp	slc_baud_std
slc_baud_nonstd:
	ldi		r19,0x00 //convert 115200 -> 125000 (baud*1.08507)
	ldi		r20,0x20
	ldi		r21,0x1C //1,843,200 = 0x1C2000
slc_baud_std:


	ldi		r22,0
	ldi		r23,0
F1div: //r22r23 = r19r20r21 / r16r17r18;
	cp		r19,r16
	cpc		r20,r17
	cpc		r21,r18
	brcs	F1done
	sub		r19,r16
	sbc		r20,r17
	sbc		r21,r18
	inc		r22
	brne	F1div
	inc		r23
	rjmp	F1div
F1done:
	subi	r22,1
	sbci	r23,0
	sts		UBRR1H,r23
	sts		UBRR1L,r22

slc_baud_over:

//baud
//-------------------------------------
//bits

//Setup UCSR1C
	ldi		r20,0
	ld		r16,Z+ //bCharFormat = Stopbits
	tst		r16 //0=1 1=1.5 2=2
	breq	F1p //0=1 1=2   1=2 -- 1.5 set as 2
	ori		r20,(1<<USBS1)

F1p:
	ld		r16,Z+ //bParityType 0=none 1odd 2even XXX3mark 4spaceXXX
	tst		r16   //0 1 2 3 4
	breq	F1b
	andi	r16,1 //x 1 0 ? ?
	swap	r16
	ori		r16,(1<<UPM11)
	or		r20,r16 //3 2 3 2

F1b://bDataBits
	ld		r16,Z+ //5 6 7 8 XX16->8XX
	subi	r16,5  //0 1 2 3   1011
	lsl		r16    //0 2 4 6  10110
	andi	r16,0x06 //UCSZ101  110 = 6
	or		r20,r16

	sts		UCSR1C,r20
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

//usb_getc:
//	jmp		FLASHEND-4

usb_putc_ready:
	ldi		r23,TX_EP
	sts		UENUM,r23
usb_in_ready:
	lds		r23,conf_nr
	tst		r23
	breq	upr
	lds		r23,UEINTX
	andi	r23,(1<<RWAL)
upr:
	ret

//usb_putc_nf:
//	jmp		FLASHEND-3

usb_flush:
	lds		r16,UEINTX
	andi	r16,~((1<<TXINI) | (1<<FIFOCON))
	sts		UEINTX,r16
	ret

usb_task:
	jmp		FLASHEND-0

//-------------------------------------

usb_getc_np:
	lds		r16,UEDATX
	//usb_ack_out:
	lds		r17,UEINTX
	sbrs	r17,RXOUTI
	ret
	sbrc	r17,RWAL
	ret
	//usb_ack_receive_out:
	lds		r17,UEINTX
	andi	r17,~((1<<RXOUTI)|(1<<FIFOCON))
	sts		UEINTX,r17
	ret


//---------------------------------------------------------

#ifdef MODULE

// build magic to match U2S bootloader and modules
#define BUILDML 0x5A
#define BUILDMH 0xA5

.org THIRDBOOTSTART-0xC83
.db	BUILDML, BUILDMH, LOW(USARTEnd-USARTEntry), HIGH(USARTEnd-USARTEntry), 0, 0x4

USARTEnd:

#endif

