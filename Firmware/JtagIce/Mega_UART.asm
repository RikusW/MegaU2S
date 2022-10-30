// vim:ts=4 sts=0 sw=4
// JtagIce wrapper for the ATmega8 including UART fw
// Copyright 2010 2011 Rikus Wessels
// Version 20110421

//This firmware is for a 7.3728MHz crystal
#define USE_CLKPR
#define _7MHZ // 7.3728/1 else 14.7456/2

//select the uart you want to use
#define PORT 0 //9 0 1 2 3


//#include <m8def.inc>    //PORT 9
//#include <m162def.inc>  //PORT 0 1
//#include <m168pdef.inc> //PORT 0
#include <m328pdef.inc> //PORT 0
//#include <m128def.inc>  //PORT 0 1

//-------------------------------------------------------------------
//User adjustable JTAG pinout

#if 1

#define JPIN PINC
#define JDDR DDRC
#define JPORT PORTC
#define JRST 0
#define JTCK 1
#define	JTDI 2
#define JTDO 3
#define JTMS 4

#else

//m8 SPI pinout
#define JPIN PINB
#define JDDR DDRB
#define JPORT PORTB
#define JRST 2
#define JTCK 5
#define JTDO 4
#define	JTDI 3
#define JTMS 1

#endif

//-------------------------------------------------------------------
//some #defines to sort out the UDR UDR0 UDR1 mess....

#if PORT == 0
.ifndef RXC0
.error "#define PORT 0 invalid"
.exit
.endif
#define UDR   UDR0
#define RXC   RXC0
#define RXEN  RXEN0
#define TXEN  TXEN0
#define UDRE  UDRE0
#define UBRRL UBRR0L
#define UBRRH UBRR0H
#define UCSZ0 UCSZ00
#define UCSZ1 UCSZ01
#define UCSRA UCSR0A
#define UCSRB UCSR0B
#define UCSRC UCSR0C
#define RXCIE RXCIE0
.ifdef URSEL0
.equ URSELbm = (1<<URSEL0)
.else
.equ URSELbm = 0
.endif

.ifdef URXC0addr // fix for mxx8
.equ URXCaddr = URXC0addr
.endif

#elif PORT == 1
.ifndef RXC1
.error "#define PORT 1 invalid"
.exit
.endif
#define UDR   UDR1
#define RXC   RXC1
#define RXEN  RXEN1
#define TXEN  TXEN1
#define UDRE  UDRE1
#define UBRRL UBRR1L
#define UBRRH UBRR1H
#define UCSZ0 UCSZ10
#define UCSZ1 UCSZ11
#define UCSRA UCSR1A
#define UCSRB UCSR1B
#define UCSRC UCSR1C
#define RXCIE RXCIE1
#define URXCaddr URXC1addr
.ifdef URSEL1
.equ URSELbm = (1<<URSEL1)
.else
.equ URSELbm = 0
.endif

#elif PORT == 2
.ifndef RXC2
.error "#define PORT 2 invalid"
.exit
.endif
#define UDR   UDR2
#define RXC   RXC2
#define RXEN  RXEN2
#define TXEN  TXEN2
#define UDRE  UDRE2
#define UBRRL UBRR2L
#define UBRRH UBRR2H
#define UCSZ0 UCSZ20
#define UCSZ1 UCSZ21
#define UCSRA UCSR2A
#define UCSRB UCSR2B
#define UCSRC UCSR2C
#define RXCIE RXCIE2
#define URXCaddr URXC2addr
.ifdef URSEL2
.equ URSELbm = (1<<URSEL2)
.else
.equ URSELbm = 0
.endif

#elif PORT == 3
.ifndef RXC3
.error "#define PORT 3 invalid"
.exit
.endif
#define UDR   UDR3
#define RXC   RXC3
#define RXEN  RXEN3
#define TXEN  TXEN3
#define UDRE  UDRE3
#define URSEL URSEL3
#define UBRRL UBRR3L
#define UBRRH UBRR3H
#define UCSZ0 UCSZ30
#define UCSZ1 UCSZ31
#define UCSRA UCSR3A
#define UCSRB UCSR3B
#define UCSRC UCSR3C
#define RXCIE RXCIE3
#define URXCaddr URXC3addr
.ifdef URSEL3
.equ URSELbm = (1<<URSEL3)
.else
.equ URSELbm = 0
.endif

#elif PORT == 9
.ifndef UDR
.error "#define PORT 9 invalid"
.exit
.endif
.ifdef URSEL
.equ URSELbm = (1<<URSEL)
.else
.equ URSELbm = 0
.endif
#else
.error "#define PORT 9 0 1 2 3"
.exit
#endif


/*
//AVR Studio 4.18.700
//BUG!!! outputs both errors
.equ YESYES = 0
#define OHYES YESYES
.ifndef OHYES
.error "OH NO"
.else
.error "OH YES"
.exit
.endif
*/

//-------------------------------------------------------------------
// some more magic...


.macro oute //IO,Rr
.if @0 >= 0x40
  .if @0 >= 0x60
    sts @0,@1
  .else
    .error "INVALID ADRESS"
  .endif
.else
  out @0,@1
.endif
.endmacro


.macro ine //Rd,IO
.if @1 >= 0x40
  .if @1 >= 0x60
    lds @0,@1
  .else
    .error "INVALID ADRESS"
  .endif
.else
  in @0,@1
.endif
.endmacro


.macro sbise //IO,bit
.if @0 >= 0x40
  .if @0 >= 0x60
    lds r0,@0
    sbrs r0,@1
  .else
    .error "INVALID ADRESS"
  .endif
.else
  .if @0 >= 0x20
    in r0,@1
    sbrs r0,@1
  .else
    sbis @0,@1
  .endif
.endif
.endmacro


.macro sbice //IO,bit
.if @0 >= 0x40
  .if @0 >= 0x60
    lds r0,@0
    sbrc r0,@1
  .else
    .error "INVALID ADRESS"
  .endif
.else
  .if @0 >= 0x20
    in r0,@1
    sbrc r0,@1
  .else
    sbic @0,@1
  .endif
.endif
.endmacro


//-------------------------------------------------------------------

.cseg
.org 0
	rjmp	START

.org URXCaddr
	rjmp	ISRgetc

START:
	sei

#define SETUPBAUD() rcall SetupBaud //p r18
#define SETUPSERIAL() rcall SetupUART

#include "JtagIce.asm"

//-------------------------------------------------------------------

.dseg
ring: .byte 0x100
rget: .byte 1
rput: .byte 1
.cseg

SetupBaud: //p r18 c r16
	lds		r16,Pbaud
	neg		r16
	lsl		r16
	lsl		r16
	dec		r16
	oute	UBRRH, rnull
	oute	UBRRL, r16
	ret

//-------------------------------------

SetupUART:
	sts		rget,rnull
	sts		rput,rnull

#ifdef USE_CLKPR
#ifdef _7MHZ
	ldi		r16,0 // 7.3728MHz/1
#else
	ldi		r16,1 //14.7456MHz/2
#endif
	ldi		r17,(1<<CLKPCE)
	sts		CLKPR,r17
	sts		CLKPR,r16 //SetPrescaler
#endif

	lds		r18,Pbaud
	rcall	SetupBaud

	ldi 	r16, (1<<RXCIE)|(1<<RXEN)|(1<<TXEN) //Enable RX & TX
	oute	UCSRB,r16
	ldi 	r16, URSELbm|(1<<UCSZ1)|(1<<UCSZ0) //8N1
	oute	UCSRC,r16

	sei

	ret

//-------------------------------------------------------------------
//UART

peek:
	push	r17
	lds		r16,rget
	lds		r17,rput
	cp		r16,r17
	pop		r17
	ret

//-------------------------------------

getc:
	rcall	peek
	breq	getc
	push	r31
	push	r30

	ldi		r30,lo8(ring)
	ldi		r31,hi8(ring)
	add		r30,r16
	adc		r31,rnull
	inc		r16
	sts		rget,r16
	ld		r16,Z

	pop		r30
	pop		r31
	ret

//-------------------------------------

ISRgetc:
	push	r0
	push	r16
	in		r16,SREG
	push	r16
	push	r17
	push	r31
	push	r30
	lds		r17,rput

IGnext:
	ldi		r30,lo8(ring)
	ldi		r31,hi8(ring)
	add		r30,r17
	adc		r31,rnull
	inc		r17
	ine		r16,UDR
	st		Z,r16
	sbice	UCSRA,RXC
	rjmp	IGnext

	sts		rput,r17
	pop		r30
	pop		r31
	pop		r17
	pop		r16
	out		SREG,r16
	pop		r16
	pop		r0
	reti

//-------------------------------------

putc:
putc_nf:
	push	r0
putc0:
	sbise	UCSRA,UDRE
	rjmp	putc0
	oute	UDR,r16
	pop		r0

flush: //stub, unused for UART
	ret

//UART
//-------------------------------------------------------------------

Delay:	// r16 = delay in ms
	push	r16 //0=256ms
	push	r17
	push	r18
D16:
	ldi		r17,38
	D17:
		ldi		r18,48 //==199 clks * 40   (38&48 for 7.3728) (40&49 for 8MHz)
		D18:
		nop
		dec		r18
		brne	D18
	dec		r17
	brne	D17

	dec		r16
	brne	D16

	pop		r18
	pop		r17
	pop		r16
	ret

//-------------------------------------

DelayU: //p r16 (4us at 7.372MHz)
	push	r17
DUloop:
	dec		r16
	breq	DUret
	ldi		r17,8
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

//-------------------------------------------------------------------
