// JtagIce wrapper for the ATmega__U2 including CDC
// Copyright 2010 2011 Rikus Wessels
// Version 20110421
// Version 20121223 - moved #include to fix jump out of range

#if 1
#include <m16U2def.inc>
#else
#include <m32U2def.inc>
#endif

//#include <usb162def.inc>

//#define _8MHZ //If you have a 8MHz crystal connected else 16MHz
//!!!!------16MHz crystal default------!!!!

//-------------------------------------------------------------------
//User adjustable JTAG pinout

#define JPIN PINB
#define JDDR DDRB
#define JPORT PORTB
#define JRST 0
#define JTCK 1
#define JTDI 2
#define JTDO 3
#define JTMS 7

//-------------------------------------------------------------------
// variables for CDC

.dseg
conf_nr:		.BYTE 1
line_flags:		.BYTE 1 // 1=coding 2=status 4=break
line_coding:	.BYTE 7
line_status:	.BYTE 2
line_break:		.BYTE 2

//-------------------------------------------------------------------

.cseg
.org 0

#undef U2S
#define SETUPBAUD() /##/ignored
#define SETUPSERIAL() rcall SetupCDC

#define getc    usb_getc
#define putc    usb_putc
#define putc_nf usb_putc_nf
#define flush   usb_flush
#define peek    usb_peek

	rjmp	jtmki //jump to the include

//-------------------------------------

SetupCDC:
#ifdef _8MHZ
	ldi		r16,0 // 8MHz/1
#else
	ldi		r16,1 //16MHz/2
#endif
	ldi		r17,(1<<CLKPCE)
	sts		CLKPR,r17
	sts		CLKPR,r16 //SetPrescaler

	ldi		r16,0
	sts		conf_nr,r16
	rcall	usb_setup
	ret

//=================================================================================================
//=================================================================================================
// USB CDC 800 bytes  ---  for standalone jtag


#include "usb_commun.h"
#include "usb_commun_cdc.h"


#define INT_EP		0x01
#define TX_EP		0x03
#define RX_EP		0x04

#define LF_CODING	1
#define LF_STATUS	2
#define LF_BREAK	4


//UECFG0X
#define TYPE_CONTROL             0x00
#define TYPE_ISOCHRONOUS         0x40
#define TYPE_BULK                0x80
#define TYPE_INTERRUPT           0xC0

#define DIRECTION_OUT            0x00
#define DIRECTION_IN             0x01

//UECFG1X
#define SIZE_8                   0x00
#define SIZE_16                  0x10
#define SIZE_32                  0x20
#define SIZE_64                  0x30


#define ONE_BANK                 0x00
#define TWO_BANKS                0x04

//-------------------------------------


usb_setup:
	sts		REGCR,rnull		//Usb_enable_regulator(); //REGCR &= ~(1<<REGDIS);

	ldi		r16,(1<<FRZCLK)	//Usb_freeze_clock();//USBCON &= ~(1<<USBE);
	sts		USBCON,r16 //Usb_disable();

	ldi		r16,(1<<USBE)//Usb_enable();//USBCON |= (1<<USBE);
	sts		USBCON,r16
	sts		USBCON,r16

#ifdef _8MHZ
	ldi		r16,(1<<PLLE)            // (8MHz = 0)
#else
	ldi		r16,(1<<PLLE)|(1<<PLLP0) // (16MHz = 1)
#endif
	out		PLLCSR,r16		//Start_pll(1<<PLLP0);

USwpll:
	in		r16,PLLCSR		//Wait_pll_ready();
	sbrs	r16,PLOCK		//while (!(PLLCSR & (1<<PLOCK)));
	rjmp	USwpll

	//Usb_attach();//UDCON &= ~(1<<DETACH);//Usb_reset_macro_only();//(UDCON &= ~(1<<RSTCPU));
   	sts		UDCON,rnull

usb_init_device:
	push	r17
	sts		UENUM,rnull		//UENUM = EP_CONTROL;
	ldi		r16,TYPE_CONTROL | DIRECTION_OUT
	ldi		r17,SIZE_32 | ONE_BANK
	rcall	usb_config_ep
	pop		r17
	ret

usb_config_ep:
	push	r18
	ldi		r18,(1<<EPEN) 	//Usb_enable_endpoint();
	sts		UECONX,r18		//UECONX  |=  (1<<EPEN);
	sts		UECFG0X,r16		//UECFG0X = config0;
	ori		r17,(1<<ALLOC)	//Usb_allocate_memory();//UECFG1X |=  (1<<ALLOC);
	sts		UECFG1X,r17		//UECFG1X = (UECFG1X & (1<<ALLOC)) | config1;
	pop		r18
	ret
//  return (Is_endpoint_configured()); //UESTA0X &  (1<<CFGOK)
}


//-------------------------------------

usb_ack_receive_setup: //UEINTX &= ~(1<<RXSTPI)
	lds		r16,UEINTX
	andi	r16,~(1<<RXSTPI)
	sts		UEINTX,r16
	ret
/*
usb_ack_nak_out:
	lds		r16,UEINTX
	andi	r16,~(1<<NAKOUTI)
	sts		UEINTX,r16
	ret*/

usb_send_control_in: //UEINTX &= ~(1<<TXINI)
	lds		r16,UEINTX
	andi	r16,~(1<<TXINI)
	sts		UEINTX,r16
	ret

usb_flush:
usb_ack_in_ready:
	lds		r16,UEINTX
	andi	r16,~((1<<TXINI) | (1<<FIFOCON))
	sts		UEINTX,r16
	ret

usb_ack_receive_out:
	lds		r16,UEINTX
	andi	r16,~((1<<RXOUTI)|(1<<FIFOCON))
	sts		UEINTX,r16
	ret

usb_ack_control_out:
	lds		r16,UEINTX
	andi	r16,~(1<<RXOUTI)
	sts		UEINTX,r16
	ret

wait_read_control:
	lds		r16,UEINTX
	sbrs	r16,TXINI
	rjmp	wait_read_control
	ret

wait_receive_out:
	lds		r16,UEINTX //while (!(Is_usb_receive_out())); UEINTX&(1<<RXOUTI)
	sbrs	r16,RXOUTI
	rjmp	wait_receive_out
	ret

is_usb_read_enabled:
is_usb_write_enabled:
	lds		r16,UEINTX
	andi	r16,(1<<RWAL)
	ret

//-------------------------------------

usb_task:
	clr		rnull			//just make sure, this is called from the app as well
	sts		UENUM,rnull		//UENUM = EP_CONTROL;
	lds		r16,UEINTX		//if(Is_usb_receive_setup()  UEINTX&(1<<RXSTPI))
	sbrc	r16,RXSTPI
	rcall	usb_process_request

	lds		r16,UDINT		//if (Is_usb_reset())
	sbrs	r16,EORSTI
	ret
usb_reset:
	ldi		r16,~(1<<EORSTI)
	sts		UDINT,r16		// Usb_ack_reset();
	rcall	usb_init_device	
	ldi		r16,1			//UERST=1<<(U8)ep, UERST=0
	sts		UERST,r16		//Usb_reset_endpoint(0);
	sts		UERST,rnull
	sts		conf_nr,rnull
	ret

//-------------------------------------

usb_process_request:
	push	r17
	push	r18
	push	r19
	push	r30
	push	r31

	rcall	usb_ack_control_out

	lds		r17,UEDATX // bmRequestType = Usb_read_byte();
	lds		r16,UEDATX // bmRequest     = Usb_read_byte();

	//switch(r16)
	cpi		r17,USB_SETUP_GET_STAND_DEVICE
	brne	UPRssd
	cpi		r16,SETUP_GET_DESCRIPTOR
	brne	UPRssd
	rcall	usb_get_descriptor
	rjmp	UPRret

UPRssd:
	cpi		r17,USB_SETUP_SET_STAND_DEVICE
	brne	UPRsci
	cpi		r16,SETUP_SET_ADDRESS
	brne	UPRscf
//usb_set_address:
	lds		r17,UEDATX
	rcall	usb_ack_receive_setup
	rcall	usb_send_control_in           // send a ZLP for STATUS phase
	rcall	wait_read_control             // waits for status phase done
	ori		r17,(1<<ADDEN)                // before using the new address
	sts		UDADDR,r17
	rjmp	UPRret
//usb_set_address:

UPRscf:
	cpi		r16,SETUP_SET_CONFIGURATION
	brne	UPRsci
//usb_set_configuration:
	lds		r16,UEDATX
	sts		conf_nr,r16
	rcall	usb_ack_receive_setup
	rcall	usb_send_control_in              // send a ZLP for STATUS phase
	rcall	usb_user_endpoint_init			 // endpoint configuration
	rjmp	UPRret
//usb_set_configuration:

UPRsci:
	lds		r18,UEDATX //wValue
	lds		r19,UEDATX

	cpi		r17,USB_SETUP_SET_CLASS_INTER
	brne	UPRgci
	cpi		r16,SETUP_CDC_SET_LINE_CODING
	brne	UPRscls
//cdc_set_line_coding:
	ldi		ZL,LOW (line_coding)
	ldi		ZH,HIGH(line_coding)
	rcall	usb_ack_receive_setup
	rcall	wait_receive_out

	ldi		r16,7
cslcn:
	lds		r17,UEDATX
	st		Z+,r17
	dec		r16
	brne	cslcn

	rcall	usb_ack_receive_out
	rcall	usb_send_control_in              // send a ZLP for STATUS phase
	rcall	wait_read_control
	ldi		r16,LF_CODING
	rcall	set_lf
	rjmp	UPRret
//cdc_set_line_coding:

UPRscls:
	cpi		r16,SETUP_CDC_SET_CONTROL_LINE_STATE
	brne	UPRsbr
//cdc_set_control_line_state:
	rcall	usb_ack_receive_setup
	rcall	usb_send_control_in              // send a ZLP for STATUS phase
	ldi		r30,LOW (line_status)
	ldi		r31,HIGH(line_status)
	st		Z+,r18
	st		Z+,r19
	rcall	wait_read_control
	ldi		r16,LF_STATUS
	rcall	set_lf
	rjmp	UPRret
//cdc_set_control_line_state:

UPRsbr:
	cpi		r16,SETUP_CDC_SEND_BREAK
	brne	UPRgci
//cdc_send_break:
	rcall	usb_ack_receive_setup
	rcall	usb_send_control_in              // send a ZLP for STATUS phase
	ldi		r30,LOW (line_break)
	ldi		r31,HIGH(line_break)
	st		Z+,r18
	st		Z+,r19
	rcall	wait_read_control
	ldi		r16,LF_BREAK
	rcall	set_lf
	rjmp	UPRret
//cdc_send_break:

UPRgci:
	cpi		r17,USB_SETUP_GET_CLASS_INTER
	brne	UPRdef
	cpi		r16,SETUP_CDC_GET_LINE_CODING
	brne	UPRdef
//cdc_get_line_coding:
	ldi		ZL,LOW (line_coding)
	ldi		ZH,HIGH(line_coding)
	rcall	usb_ack_receive_setup

	ldi		r16,7
cglcn:
	ld		r17,Z+
	sts		UEDATX,r17
	dec		r16
	brne	cglcn

	rcall	usb_send_control_in              // send a ZLP for STATUS phase
	rcall	wait_read_control
//11	rcall	wait_receive_out
	rcall	usb_ack_receive_out
	rjmp	UPRret
//cdc_get_line_coding:

UPRdef:
	// Request unknow in the specific request list from interface
	// keep that order (set StallRq/clear RxSetup) or a
	// OUT request following the SETUP may be acknowledged
	lds		r16,UECONX		//UECONX  |=  (1<<STALLRQ)//Usb_enable_stall_handshake();
	ori		r16,(1<<STALLRQ)
	sts		UECONX,r16

	rcall	usb_ack_receive_setup

UPRret:
	pop		r31
	pop		r30
	pop		r19
	pop		r18
	pop		r17
	ret

set_lf:
	lds		r17,line_flags
	or		r17,r16
	sts		line_flags,r17
	ret

//-------------------------------------

#define udd \
0x12, 0x01, 0x00, 0x02, 0x02, 0x00, 0x00, 0x20, 0xEB, \
0x03, 0x18, 0x20, 0x00, 0x10, 0x01, 0x01, 0x01, 0x01

#define ucd \
0x09, 0x02, 0x43, 0x00, 0x02, 0x01, 0x00, 0x80, 0xA0, \
0x09, 0x04, 0x00, 0x00, 0x01, 0x02, 0x02, 0x01, 0x00, \
0x05, 0x24, 0x00, 0x10, 0x01, \
0x05, 0x24, 0x01, 0x03, 0x01, \
0x04, 0x24, 0x02, 0x06, \
0x05, 0x24, 0x06, 0x00, 0x01, \
0x07, 0x05, 0x81, 0x03, 0x10, 0x00, 0xFF, \
0x09, 0x04, 0x01, 0x00, 0x02, 0x0A, 0x00, 0x00, 0x00, \
0x07, 0x05, 0x83, 0x02, 0x20, 0x00, 0x00, \
0x07, 0x05, 0x04, 0x02, 0x20, 0x00, 0x00, 0

#define usbddsz 0x12
usbdd:
.db udd

#define usbcdsz 0x43
usbcd:
.db ucd

#define usblisz 4
usbli:
.db 0x04, 0x03, 0x09, 0x04

#define usbu2ssz 8
usbu2s:
.db 0x08, 0x03, 0x55, 0x00, 0x32, 0x00, 0x53, 0x00

//-------------------------------------


usb_get_descriptor:

	lds		r17,UEDATX
	lds		r16,UEDATX

	cpi		r16,DESCRIPTOR_DEVICE
	brne	ugdd
	ldi		r16,usbddsz
	ldi		r30,LOW (usbdd*2)
	ldi		r31,HIGH(usbdd*2)
	rjmp	ugok
ugdd:
	cpi		r16,DESCRIPTOR_CONFIGURATION
	brne	ugdc
	ldi		r16,usbcdsz
	ldi		r30,LOW (usbcd*2)
	ldi		r31,HIGH(usbcd*2)
	rjmp	ugok
ugdc:
	cpi		r16,DESCRIPTOR_STRING
	brne	ugds
	cpi		r17,0 //LANG_ID
	brne	ugli
	ldi		r16,usblisz
	ldi		r30,LOW (usbli*2)
	ldi		r31,HIGH(usbli*2)
	rjmp	ugok
ugli:
	cpi		r17,1 //U2S_ID
	brne	ugds
	ldi		r16,usbu2ssz
	ldi		r30,LOW (usbu2s*2)
	ldi		r31,HIGH(usbu2s*2)
	rjmp	ugok

ugds: //failed
	ldi		r16,0
	ret

ugok:
	lds		r18,UEDATX
	lds		r19,UEDATX
	lds		r18,UEDATX //wlen
	lds		r19,UEDATX

	mov		r17,r16
	rcall	usb_ack_receive_setup
	mov		r16,r17

	cp		r16,r18
	cpc		rnull,r19
	brcs	ugmax
	mov		r16,r18
ugmax:
	mov		r18,r16

uglp1:   	
	tst		r18 //while(data_to_transfer != 0)
	breq	ugzlp
		rcall	wait_read_control
		ldi		r19,0 //nb_byte=0;
uglp2:
		tst		r18 //while(data_to_transfer != 0)
		breq	ugci

			cpi		r19,0x20 //if(nb_byte++==EP_CONTROL_LENGTH)
			breq	ugci
			inc		r19

			lpm		r16,Z+
			sts		UEDATX,r16 //Usb_write_PGM_byte(pbuffer++);

			dec		r18 //data_to_transfer --;  //decrements the number of bytes to transmit.
			rjmp	uglp2
ugci:
		rcall	usb_send_control_in
		rjmp	uglp1

ugzlp:   
   andi		r17,0x1F  //if((zlp == TRUE)) {
   brne		ugret
		rcall	wait_read_control
		rcall	usb_send_control_in
ugret:
	rcall	usb_ack_control_out
	ldi		r16,1
	ret

usb_user_endpoint_init:
	ldi		r31,0
	ldi		r30,UENUM

	ldi		r16,INT_EP
	st		Z,r16
	ldi		r16,TYPE_INTERRUPT | DIRECTION_IN
	ldi		r17,SIZE_16 | ONE_BANK
	rcall	usb_config_ep

	ldi		r16,TX_EP
	st		Z,r16
	ldi		r16,TYPE_BULK | DIRECTION_IN
	ldi		r17,SIZE_32 | TWO_BANKS
	rcall	usb_config_ep

	ldi		r16,RX_EP
	st		Z,r16
	ldi		r16,TYPE_BULK | DIRECTION_OUT
	ldi		r17,SIZE_32 | TWO_BANKS
	rcall	usb_config_ep

	// reset ep
	ldi		r30,UERST
	ldi		r16,(1<<RX_EP)|(1<<TX_EP)|(1<<INT_EP)
	st		Z,r16
	st		Z,rnull
	ret

//-------------------------------------

usb_getc:
	rcall	usb_peek
	breq	usb_getc
	lds		r16,UEDATX
	ret

usb_peek:
	rcall	usb_task
	lds		r16,conf_nr	//Is_device_enumerated()
	tst		r16
	breq	UPret

	ldi		r16,RX_EP
	sts		UENUM,r16
	lds		r16,UEINTX
	sbrs	r16,RXOUTI
	rjmp	UPret

	sbrs	r16,RWAL
	rjmp	UPack
	clz //data available
	ret
UPack:
	rcall	usb_ack_receive_out
UPret:
	sez //no data available
	ret

usb_putc:
	rcall	usb_putc_nf
	rjmp	usb_flush

usb_putc_nf:
	push	r17
	mov		r17,r16
UPNn:
	lds		r16,conf_nr	//Is_device_enumerated()
	tst		r16
	breq	UPNret

	ldi		r16,TX_EP
	sts		UENUM,r16
UPNw:
	rcall	is_usb_write_enabled
	breq	UPNw
	sts		UEDATX,r17

	rcall	is_usb_write_enabled
	brne	UPNret
	rcall	usb_ack_in_ready
UPNret:
	pop		r17
	ret


// ADDED for jtag mki

//END USB
//=================================================================================================
//=================================================================================================

jtmki:
#include "JtagIce.asm"

Delay:	// r16 = delay in ms
	push	r16 //0=256ms
	push	r17
	push	r18
D16:
	ldi		r17,40
	D17:
		ldi		r18,49 //==199 clks * 40   (38&48 for 7.3728) (40&49 for 8MHz)
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

DelayU: //4us at 8MHz
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

//-------------------------------------------------------------------
