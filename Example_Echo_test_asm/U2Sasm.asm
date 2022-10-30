
//Blisp16U2.asm
//STK500 type bootloader and ISP programmer for ATmega16U2
//Copyright 2010 Rikus Wessels
//rikusw --- gmail --- com

#if 0
#include <m16U2def.inc>
#else
#include <m32U2def.inc>
#endif

//-------------------------------------

#define CONTROL_EP	0x00
#define INT_EP		0x01
#define TX_EP		0x03
#define RX_EP		0x04

#define LF_CODING	1
#define LF_STATUS	2
#define LF_BREAK	4

//-------------------------------------

.dseg
conf_nr:		.BYTE 1
line_flags:		.BYTE 1 // 1=coding 2=status 4=break
line_coding:	.BYTE 7
line_status:	.BYTE 2
line_break:		.BYTE 2
select:			.BYTE 1

//-------------------------------------
/*
r27:r26 X is getc_ptr
r29:r28 Y is putc_ptr
*/

.def rnull = r2 // this will always be 0 - NEVER set to anything else

//-------------------------------------

#define lo8(x) (x & 0xFF)
#define hi8(x) ((x >> 8) & 0xFF)

#define mlo8(x) ((-x) & 0xFF)
#define mhi8(x) (((-x) >> 8) & 0xFF)

#define RSTPORT PORTB
#define RSTBIT  0
#define RSTDDR  DDRB
#define RSTPIN	PINB

#define SPIPIN  PINB
#define SPIPORT PORTB
#define SCKBIT  1
#define MOSIBIT 2
#define MISOBIT 3
#define SPIDDR  DDRB

#define SELBIT  4
#define SELPORT PORTC
#define SELDDR  DDRC
#define SELPIN	PINC

#define LEDBIT	2
#define LEDPORT PORTC
#define LEDDDR	DDRC

//-----------------------------------------------------------------------------

.cseg
.org 0x000 //RESET
	rjmp	Start
.org 0x002 //INT0
.org 0x004 //INT1
.org 0x006 //INT2
.org 0x008 //INT3
.org 0x00A //INT4
.org 0x00C //INT5
.org 0x00E //INT6
.org 0x010 //INT7
.org 0x012 //PCINT0
.org 0x014 //PCINT1
.org 0x016 //USB_GEN
	jmp		USB_GEN_vect
.org 0x018 //USB_COM
	jmp		USB_COM_vect
.org 0x01A //WDT
.org 0x01C //TIMER1_CAPT
.org 0x01E //TIMER1_COMPA
.org 0x020 //TIMER1_COMPB
.org 0x022 //TIMER1_COMPC
.org 0x024 //TIMER1_OVF
.org 0x026 //TIMER0_COMPA
.org 0x028 //TIMER0_COMPB
.org 0x02A //TIMER0_OVF
.org 0x02C //SPI_STC
.org 0x02E //USART1_RX
.org 0x030 //USART1_UDRE
.org 0x032 //USART1_TX
.org 0x034 //ANALOG_COMP
.org 0x036 //EE_READY
.org 0x038 //SPM_READY


.org 0x03A
Start:
	cli
	clr		rnull // NEVER set this to anything other than 0
	
	out		SREG,rnull
	ldi		r16,LOW (RAMEND)	//setup stack
	out		SPL,r16
	ldi		r17,HIGH(RAMEND)
	out		SPH,r17

	ldi		r16,1 // 16/2 == 8Mhz
	rcall	SetPrescaler

//-------------------------------------

	out		DDRD,rnull
	out		DDRB,rnull
	out		PORTD,rnull
	out		PORTB,rnull

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

main:
	andi	r24,0x0F // the select value from the bootloader
	rcall	usb_init

mainloop:
	sbic	PINC,PINC4
	rjmp	mno_sel
	cbi		PORTC,PORTC2 //led on
waitsel:
	sbis	PINC,PINC4 //while(select_pressed());
	rjmp	waitsel
mode81:	
	ldi		r16,0x81
	rcall	select_mode
mno_sel:
	rcall	usb_rxready
	breq	mainloop
	
	rcall	usb_getc
	cpi		r16,'q'
	breq	mode81
	add		r16,r24
	rcall	usb_putc

	rjmp	mainloop

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

Delay0:
	tst		r16
	brne	Delay
	ret
Delay100:
	ldi		r16,100
Delay:	// r16 = delay in ms -- const r16 -- 0 == 256ms
	push	r16
	push	r17
	push	r18
D16:
	ldi		r17,40
	D17:
		ldi		r18,49 //==199 clks * 40   (38&48 for 7.3728)
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


//---------------------------------------------------------

select_mode:
	mov		r24,r16
	ori		r24,0x50 // Prevent USB reinit
	ldi		r30,0x53
	ldi		r31,0xCA

	ldi		r16,CONTROL_EP
	sts		UENUM,r16
	sts		UDIEN,rnull
	sts		UEIENX,rnull
	jmp		THIRDBOOTSTART //FLASHEND-0x3FF

//---------------------------------------------------------

usb_init:
	ldi		r16,CONTROL_EP
	sts		UENUM,r16
	ldi		r16,(1<<EORSTE)
	sts		UDIEN,r16
UIrs:
	ldi		r16,(1<<RXSTPE)
	sts		UEIENX,r16
	lds		r16,UEIENX
	andi	r16,(1<<RXSTPE)
	breq	UIrs //???
	sei
	ret

//---------------------------------------------------------

SetPrescaler:
	ldi		r17,(1<<CLKPCE)
	sts		CLKPR,r17
	sts		CLKPR,r16
	ret

//=======================================================================================
//=======================================================================================
//=======================================================================================
//Z flag = 1 when ready

usb_rxready:
	lds		r16,conf_nr	//Is_device_enumerated()
	tst		r16
	breq	rxret
	ldi		r16,RX_EP
	sts		UENUM,r16

	lds		r16,UEINTX //if(Is_usb_receive_out())
	andi	r16,(1<<RXOUTI)
	breq	rxret
flush_out:
	lds		r16,UEINTX //if(!Is_usb_read_enabled())
	andi	r16,(1<<RWAL)
	brne	rxret

	lds		r16,UEINTX //Usb_ack_receive_out()
	andi	r16,~((1<<RXOUTI) | (1<<FIFOCON))
	sts		UEINTX,r16
	clz
rxret:
	ret

//---------------------------------------------------------

usb_getc:
	rcall	usb_rxready
	breq	usb_getc
	lds		r17,UEDATX
	rcall	flush_out
	mov		r16,r17
	ret

//---------------------------------------------------------
//Z flag = 1 when ready

usb_txready:
	lds		r16,conf_nr	//Is_device_enumerated()
	tst		r16
	breq	txret
	ldi		r16,TX_EP
	sts		UENUM,r16
flush_in:
	lds		r16,UEINTX //return Is_usb_write_enabled())
	andi	r16,(1<<RWAL)
	brne	txret
	rcall	usb_flush
	clz
txret:
	ret

//---------------------------------------------------------

usb_putc:
	rcall	usb_putc_nf
usb_flush:
	lds		r16,UEINTX
	andi	r16,~((1<<TXINI) | (1<<FIFOCON))
	sts		UEINTX,r16
	ret

//---------------------------------------------------------

usb_putc_nf:
	mov		r17,r16
UPNw:
	rcall	usb_txready
	breq	UPNw
	sts		UEDATX,r17
	rjmp	flush_in

//-----------------------------------------------------------------------------

USB_GEN_vect:
	push	r16
	in		r16,SREG
	push	r16
	lds		r16,UENUM
	push	r16
//---------------------------
	lds		r16,UDINT //Is_usb_reset()
	andi	r16,(1<<EORSTI)
	breq	UGVnr
	call	FLASHEND-1 //usb_reset 0x3FFE for 32U2
UGVnr:
	ldi		r16,CONTROL_EP
	sts		UENUM,r16
UGVrs:
	ldi		r16,(1<<RXSTPE)
	sts		UEIENX,r16
	lds		r16,UEIENX
	andi	r16,(1<<RXSTPE)
	breq	UGVrs //???
//---------------------------
	pop		r16
	sts		UENUM,r16
	pop		r16
	out		SREG,r16
	pop		r16
	reti

//---------------------------------------------------------

USB_COM_vect:
	push	r16
	in		r16,SREG
	push	r16
	lds		r16,UENUM
	push	r16
//---------------------------
	ldi		r16,CONTROL_EP
	sts		UENUM,r16
	lds		r16,UEINTX //Is_usb_receive_setup()
	andi	r16,(1<<RXSTPI)
	breq	UCVr
	call	FLASHEND-2 //usb_process_request 0x3FFD for 32U2
UCVr:
//---------------------------
	pop		r16
	sts		UENUM,r16
	pop		r16
	out		SREG,r16
	pop		r16
	reti

//-----------------------------------------------------------------------------
