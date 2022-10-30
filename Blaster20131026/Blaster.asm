//Rikus Wessels (RikusW) --  26 October 2013
//Altera USB Blaster clone
//GPLV2
/*
ixo-jtag.sourceforge.net
http://www.sa89a.net/mp.cgi/ele/ub.htm
http://www.altera.com/literature/ug/ug_usb_blstr.pdf (2x5 pinout)

Thanks to these projects I was able to figure out how to create an USB-Blaster for USB AVR.
In short a FT245BM is connected to an EPM7064 CPLD and level translator.
From the above it became clear the following bitmappings was used from FT245 to EPM7064.

OUT Data bits:
7 - Mode when 0
6 - When 1 read data back when writing
5 - OE LED - C2 on U2S
4 - TDI
3 - nCS
2 - nCE
1 - TMS
0 - TCK

IN Data bits:
1 - ASDO
0 - TDO



OUT Data bits:
7 - Mode when 1
6 - When 1 read data back when writing
5 to 0 byte count to be received
--bytes transmitted serially out of TDI/ASDI and read back from TDO/ASDO--
(TMS will be previously set using a Mode0 command)


Standard JTAG Connector pinout 2x5 header:
13579
02468

(Programmer -> JTAG/PS/AS)

0 -> TCK / DCLK
1 -- GND
2 <- TDO / CONF_DONE
3 <- VTG  ---  for level translators only
4 -> TMS / nCONFIG
5 -> X / X / nCE
6 <- X / nSTATUS / ASDO
7 -> X / X / nCS
8 -> TDI / DATAO / ASDI
9 -- GND
*/

//U2S port bits all on PORTB
#define nCE 0
#define TCK 1
#define TDI 2
#define TDO 3
#define nCS 4 //not fixed yet can be 4 5 6
#define ASDO 6 //not fixed yet can be 4 5 6
#define TMS 7

//=================================================================================================
//=================================================================================================

#define U2USB //--> make it work in ATmega8/16/32U2 and AT90USB82/162  ---else---  work with 16/32U4 and AT90USB64/128

#ifdef U2USB
#include <m32U2def.inc>
#else
#include <m32U4def.inc>
#endif

//Porting notes:
//Check U2USB and proper usb_setup
//Check Interrupt vectors for AT90USB64/128

//Prescaler can be set to /1 instead of /2 for increased performance

//-------------------------------------

#define CONTROL_EP	0x00
#define TX_EP		0x01
#define RX_EP		0x02

//-------------------------------------

.dseg
.org 0x100 //ring buffer must be on 0x100
TXB:		.BYTE 256

conf_nr:	.BYTE 1 //USB configuration number default 0, changes to 1 when enumerated
ft_lat:		.BYTE 1 //FTDI latency, not actually used...

//-------------------------------------

.def rnull = r2 // this will always be 0 - NEVER set to anything else

#define TXtail X
#define TXtailL r26
#define TXtailH r27

#define TXhead Y
#define TXheadL r28
#define TXheadH r29

//=================================================================================================
//=================================================================================================
.cseg //Interrupt vectors

#ifdef U2USB

.org 0x000  jmp Reset   //32U2
.org 0x002  reti //INT0
.org 0x004  reti //INT1
.org 0x006  reti //INT2
.org 0x008  reti //INT3
.org 0x00A  reti //INT4
.org 0x00C  reti //INT5
.org 0x00E  reti //INT6
.org 0x010  reti //INT7
.org 0x012  reti //PCINT0
.org 0x014  reti //PCINT1

.org 0x016  jmp	USB_GEN_vect
.org 0x018  jmp USB_COM_vect
.org 0x01A  reti //jmp WDT_vect
.org 0x01C  reti //TIMER1_CAPT
.org 0x01E  reti //TIMER1_COMPA
.org 0x020  reti //TIMER1_COMPB
.org 0x022  reti //TIMER1_COMPC
.org 0x024  reti //TIMER1_OVF
.org 0x026  reti //TIMER0_COMPA
.org 0x028  reti //TIMER0_COMPB
.org 0x02A  //jmp T0_OVF_vect //TIMER0_OVF
.org 0x02C  reti //SPI, STC
.org 0x02E  reti //USART1, RX
.org 0x030  reti //USART1, UDRE
.org 0x032  reti //USART1, TX
.org 0x034  reti //ANALOG_COMP
.org 0x036  reti //EE_READY
.org 0x038  reti  //SPM_READY


#else

.org 0x000  jmp Reset   //32U4
.org 0x002  reti //INT0
.org 0x004  reti //INT1
.org 0x006  reti //INT2
.org 0x008  reti //INT3
.org 0x00A  reti //Reserved1
.org 0x00C  reti //Reserved2
.org 0x00E  reti //INT6
.org 0x010  reti //Reserved3
.org 0x012  reti //PCINT0

.org 0x014  jmp	USB_GEN_vect
.org 0x016  jmp USB_COM_vect
.org 0x018  reti //jmp WDT_vect

.org 0x01A  reti //Reserved4
.org 0x01C  reti //Reserved5
.org 0x01E  reti //Reserved6

.org 0x020  reti //TIMER1_CAPT
.org 0x022  reti //TIMER1_COMPA
.org 0x024  reti //TIMER1_COMPB
.org 0x026  reti //TIMER1_COMPC
.org 0x028  reti //TIMER1_OVF
.org 0x02A  reti //TIMER0_COMPA
.org 0x02C  reti //TIMER0_COMPB
.org 0x02E  jmp T0_OVF_vect //TIMER0_OVF
.org 0x030  reti //SPI, STC

.org 0x032  reti //USART1, RX
.org 0x034  reti //USART1, UDRE
.org 0x036  reti //USART1, TX

.org 0x038  reti //ANALOG_COMP
.org 0x03A  reti //ADC
.org 0x03C  reti //EE_READY

.org 0x03E  reti //TIMER3_CAPT
.org 0x040  reti //TIMER3_COMPA
.org 0x042  reti //TIMER3_COMPB
.org 0x044  reti //TIMER3_COMPC
.org 0x046  reti //TIMER3_OVF
.org 0x048  reti //TWI
.org 0x04A  reti //SPM_READY
.org 0x04C  reti //TIMER4_COMPA
.org 0x04E  reti //TIMER4_COMPB
.org 0x050  reti //TIMER4_COMPD
.org 0x052  reti //TIMER4_OVF
.org 0x054  reti //TIMER4_FPF

#endif

//=================================================================================================
//=================================================================================================
//init

Reset:
	cli
	clr		rnull // NEVER set this to anything other than 0
	sts		USBCON,rnull
	out		SREG,rnull
	ldi		r16,LOW (RAMEND)	//setup stack
	ldi		r17,HIGH(RAMEND)
	out		SPL,r16
	out		SPH,r17

	ldi		XL,LOW (SRAM_START) //clear the ram
	ldi		XH,HIGH(SRAM_START)
clrram:
	cp		XL,r16
	cpc		XH,r17
	st		X+,rnull
	brcs	clrram

	ldi		r16,5 //maybe the ram loop is enough delay from USBCON ??
	rcall	Delay

	sts		conf_nr,rnull
	out		GPIOR0,rnull

//-------------------------------------	

	ldi		r16,1 // 16/2 ==  8Mhz
//	ldi		r16,0 // 16/1 == 16Mhz   It does work at 16MHz and 3.3V on ATmega32U2, but its slightly overclocked.
	rcall	SetPrescaler

	//usb init
	rcall	usb_setup
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

	ldi		TXtailL,LOW(TXB)
	ldi		TXtailH,HIGH(TXB)
	ldi		TXheadL,LOW(TXB)
	ldi		TXheadH,HIGH(TXB)

	sei

//=================================================================================================
//=================================================================================================
//Blaster loop

	ldi		r16,(1<<TCK)|(1<<TDI)|(1<<TMS)|(1<<nCE)|(1<<nCS)
	out		DDRB,r16
	ldi		r16,(1<<TDO)|(1<<ASDO) //pullups
	out		PORTB,r16

	sbi		PORTC,2 //LED off
	sbi		DDRC,2

mainloop:
	rcall	usb_getc
	sbrs	r16,7
	rcall	DoBitbang //62 clocks per bitbang loop
	sbrc	r16,7
	rcall	DoSerial
	rjmp 	mainloop

//Blaster loop
//=================================================================================================
//=================================================================================================
//JTAG

DoBitbang: //p r16 => 6 - Read  5-0 - bits
	in		r17,PORTB //not PINB
	in		r18,PINB

	bst		r16,0 //TCK
	bld		r17,TCK

	bst		r16,1 //TMS
	bld		r17,TMS

	bst		r16,2 //nCE
	bld		r17,nCE //Reset pin on U2S

	bst		r16,3 //nCS
	bld		r17,nCS

	bst		r16,4 //TDI
	bld		r17,TDI

	out		PORTB,r17

	sbrs	r16,5 //U2S LED on C2
	cbi		PORTC,2
	sbrc	r16,5
	sbi		PORTC,2

	sbrs	r16,6
	ret //23 clocks

	ldi		r16,0
	
	bst		r18,TDO
	bld		r16,0

	bst		r18,ASDO
	bld		r16,1

	st		TXhead,r16 //rcall usb_putc
	inc		TXheadL //TXheadH should NOT change
	ret //32 clocks

//-----------------------------------------------------------------------------

DoSerial: //p r16 => 6 - Read  5-0 - count	
	mov		r23,r16
	andi	r23,0x3F
	sbrc	r16,6
	rjmp	DS_RW

//---------------------------

DS_W: //JTAG/AS write only -- it is possible to use SPI here instead
	rcall	usb_getc
	ldi		r22,8
	in		r20,PORTB
	bst		r16,0
	bld		r20,TDI
DS_WL: //this loop was optimized a bit
		out		PORTB,r20
		lsr		r16
		bst		r16,0
		sbi		PORTB,TCK
		bld		r20,TDI
		dec		r22
		nop // could possibly be taken out
		cbi		PORTB,TCK
		brne	DS_WL
	dec		r23
	brne	DS_W //28 + count * 12 clocks
	ret

//-----------------------------------------------

DS_RW: //Read Write
	sbis	PORTB,nCS //Use PORTB _NOT_ PINB
	rjmp	DS_AS

//---------------------------

DS_JT: //JTAG Read Write -- it is possible to use SPI here instead
	rcall	usb_getc //22 clocks
	ldi		r22,8
	ldi		r21,1 //bitmask
	in		r20,PORTB
	clr		r15 //return value
JRWL: //14 clocks
		bst		r16,0
		bld		r20,TDI
		out		PORTB,r20
		sbic	PINB,TDO
		or		r15,r21
		sbi		PORTB,TCK
		lsl		r21
		lsr		r16
		dec		r22
		cbi		PORTB,TCK
		brne	JRWL
	st		TXhead,r15 //rcall usb_putc
	inc		TXheadL //TXheadH should NOT change
	dec		r23
	brne	DS_JT //32 + count * 14 clocks
	ret

//---------------------------

DS_AS: //AS Read Write -- it is __NOT__ possible to use SPI here
	rcall	usb_getc
	ldi		r22,8
	ldi		r21,1 //bitmask
	in		r20,PORTB
	clr		r15 //return value
ARWL:
		bst		r16,0
		bld		r20,TDI
		out		PORTB,r20
		sbic	PINB,ASDO //sole difference from JTAG_RW
		or		r15,r21
		sbi		PORTB,TCK
		lsl		r21
		lsr		r16
		dec		r22
		cbi		PORTB,TCK
		brne	ARWL
	st		TXhead,r15 //rcall usb_putc
	inc		TXheadL //TXheadH should NOT change
	dec		r23
	brne	DS_AS
	ret

//JTAG
//=================================================================================================
//=================================================================================================
//RX - receive from PC, USB OUT

usb_getc:
	lds		r16,conf_nr	//Is_device_enumerated()
	tst		r16
	breq	usb_getc

	ldi		r16,RX_EP
	sts		UENUM,r16

	//data available on endpoint ?
	lds		r16,UEINTX
	sbrs	r16,RXOUTI
	rjmp	usb_tx
	sbrs	r16,RWAL
	rjmp	UGack

	lds		r16,UEDATX
	ret
UGack:
	rcall	usb_ack_receive_out

//-------------------------------------
//TX - transmit to PC, USB IN

usb_tx: //buffer to USB
	ldi		r16,TX_EP
	sts		UENUM,r16

	//endpoint bank free ?
	lds		r16,UEINTX
	sbrs	r16,TXINI
	rjmp	UTret
	sbrs	r16,RWAL
	rjmp	UTack //XXX2410 UTret -- unlikely to be taken

	//FT245BM kludge.... put 0x31 0x60 at the beginning of every packet
	ldi		r16,0x31
	sts		UEDATX,r16
	ldi		r16,0x60
	sts		UEDATX,r16

UTL:
	cp		TXtailL,TXheadL
	breq	UTack //ring buffer empty
	ld		r16,TXtail
	inc		TXtailL //TXtailH should NOT change
	sts		UEDATX,r16
	lds		r16,UEINTX
	sbrc	r16,RWAL
	rjmp	UTL
UTack:
	rcall	usb_ack_in_ready //flush when ep buffer is ful
UTret:
	rjmp	usb_getc

//=================================================================================================
//=================================================================================================
// USB driver
// Rikus Wessels 2011 - modified for FT245BM 10/2013

#include "usb_commun.h"
#include "usb_commun_cdc.h"

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
#ifdef U2USB

	sts		REGCR,rnull		//Usb_enable_regulator(); //REGCR &= ~(1<<REGDIS);

	ldi		r16,(1<<FRZCLK)	//Usb_freeze_clock();//USBCON &= ~(1<<USBE);
	sts		USBCON,r16 //Usb_disable();

	ldi		r16,(1<<USBE)//Usb_enable();//USBCON |= (1<<USBE);
	sts		USBCON,r16
	sts		USBCON,r16

	ldi		r16,(1<<PLLE)|(1<<PLLP0) // (16MHz = 1) (8MHz = 0)
	out		PLLCSR,r16		//Start_pll(1<<PLLP0);

#else

	ldi		r16,(1<<UVREGE)		//Usb_enable_regulator();
	sts		UHWCON,r16

	ldi		r16,(1<<FRZCLK)	//Usb_freeze_clock();//USBCON &= ~(1<<USBE);
	sts		USBCON,r16 //Usb_disable();

	ldi		r16,(1<<USBE)|(1<<OTGPADE)//Usb_enable();
	sts		USBCON,r16
	sts		USBCON,r16

	ldi		r16,(1<<PLLE)|(1<<PINDIV) // (16MHz = 1) (8MHz = 0)
	out		PLLCSR,r16		//Start_pll(1<<PLLP0);

#endif


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
	ldi		r17,SIZE_8 | ONE_BANK
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
/*
is_usb_read_enabled:
is_usb_write_enabled:
	lds		r16,UEINTX
	andi	r16,(1<<RWAL)
	ret*/

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
usb_reset_v:
	ldi		r16,~(1<<EORSTI)
	sts		UDINT,r16		// Usb_ack_reset();
	rcall	usb_init_device	
	ldi		r16,1			//UERST=1<<(U8)ep, UERST=0
	sts		UERST,r16		//Usb_reset_endpoint(0);
	sts		UERST,rnull
	sts		conf_nr,rnull
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

//-----------------------------------------------------------------------------

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
	sbrc	r16,RXSTPI
	call	usb_process_request
//---------------------------
	pop		r16
	sts		UENUM,r16
	pop		r16
	out		SREG,r16
	pop		r16
	reti

//-----------------------------------------------------------------------------

usb_process_request:
	push	r17
	push	r18
	push	r19
	push	r30
	push	r31

	rcall	usb_ack_control_out

	lds		r17,UEDATX // bmRequestType = Usb_read_byte();
	lds		r16,UEDATX // bmRequest     = Usb_read_byte();

//-------------------------------------

	//switch(r16)
	cpi		r17,USB_SETUP_GET_STAND_DEVICE
	brne	UPRssd

	cpi		r16,SETUP_GET_DESCRIPTOR
	brne	UPRsgs
	rcall	usb_get_descriptor
	rjmp	UPRret

UPRsgs:
	cpi		r16,SETUP_GET_STATUS
	brne	UPRsgc
	rcall	usb_ack_receive_setup
	sts		UEDATX,rnull
	sts		UEDATX,rnull
	rjmp	UPRsgg

UPRsgc:
	cpi		r16,SETUP_GET_CONFIGURATION
	brne	UPRssd
	rcall	usb_ack_receive_setup
	lds		r16,conf_nr
	sts		UEDATX,r16
UPRsgg:
	rcall	usb_send_control_in           // send a ZLP for STATUS phase
	rcall	wait_receive_out             // waits for status phase done
	rcall	usb_ack_receive_out
	rjmp	UPRret

//-------------------------------------

UPRssd:
	cpi		r17,USB_SETUP_SET_STAND_DEVICE
	brne	UPRven

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
	brne	UPRven
//usb_set_configuration:
	lds		r16,UEDATX
	sts		conf_nr,r16
	rcall	usb_ack_receive_setup
	rcall	usb_send_control_in              // send a ZLP for STATUS phase
	rcall	wait_read_control             // waits for status phase done
	rcall	usb_user_endpoint_init			 // endpoint configuration
	rjmp	UPRret
//usb_set_configuration:

//-------------------------------------

UPRven:
	cpi		r17,USB_SETUP_GET_VENDOR_DEVICE
	brne	UPRvs

	cpi		r16,0x0A //get latency
	brne	UPRv90
	rcall	usb_ack_receive_setup
	lds		r16,ft_lat
	sts		UEDATX,r16
//	sts		UEDATX,rnull
	rjmp	UPRvenDone

UPRv90:
	cpi		r16,0x90 //read eeprom
	brne	UPRvenxx
	ldi		r30,LOW (FT245rom*2)
	ldi		r31,HIGH(FT245rom*2)

	lds		r16,UEDATX //wValue
	lds		r17,UEDATX
	lds		r16,UEDATX //wIndex
	lsl		r16
	andi	r16,0x7E
	add		r30,r16
	adc		r31,rnull

	rcall	usb_ack_receive_setup
	lpm		r16,Z+
	sts		UEDATX,r16
	lpm		r16,Z+
	sts		UEDATX,r16
	rjmp	UPRvenDone

UPRvenxx: //???
	rcall	usb_ack_receive_setup
	ldi		r16,0x36
	sts		UEDATX,r16
	ldi		r16,0x83
	sts		UEDATX,r16 

UPRvenDone:
	rcall	usb_send_control_in              // send a ZLP for STATUS phase
	rcall	wait_read_control
	rcall	usb_ack_receive_out
	rjmp	UPRret

//-------------------------------------

UPRvs:
	cpi		r17,USB_SETUP_SET_VENDOR_DEVICE
	brne	UPRdef

	cpi		r16,0 //?opening
	brne	UPRvs3
	rjmp	UPRvend

UPRvs3:
	cpi		r16,3 //?opening
	brne	UPRvs9
	rjmp	UPRvend

UPRvs9:
	cpi		r16,9 //set latency
	brne	UPRvsB
	lds		r16,UEDATX
	sts		ft_lat,r16
	rjmp	UPRvend

UPRvsB:
	cpi		r16,0x0B //disable bitbang here ???
	brne	UPRvend
	

UPRvend:
	rcall	usb_ack_receive_setup
	rcall	usb_send_control_in              // send a ZLP for STATUS phase
	rcall	wait_read_control
	rjmp	UPRret


//-------------------------------------

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

//-------------------------------------

//seems not to be actually used ?
//maybe only when first connecting...
#define FT245romd \
0x00, 0x00, 0xFB, 0x09, 0x01, 0x60, 0x00, 0x04, \
0x80, 0x28, 0x1C, 0x00, 0x10, 0x01, 0x94, 0x0E, \
0xA2, 0x18, 0xBA, 0x12, 0x0E, 0x03, 0x41, 0x00, \
0x6C, 0x00, 0x74, 0x00, 0x65, 0x00, 0x72, 0x00, \
0x61, 0x00, 0x18, 0x03, 0x55, 0x00, 0x53, 0x00, \
0x42, 0x00, 0x2D, 0x00, 0x42, 0x00, 0x6C, 0x00, \
0x61, 0x00, 0x73, 0x00, 0x74, 0x00, 0x65, 0x00, \
0x72, 0x00, 0x12, 0x03, 0x30, 0x00, 0x30, 0x00, \
0x30, 0x00, 0x30, 0x00, 0x30, 0x00, 0x30, 0x00, \
0x30, 0x00, 0x30, 0x00, 0x01, 0x02, 0x03, 0x01, \
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x85, 0xD0

FT245rom:
.db FT245romd

#define udd \
0x12, 0x01, 0x10, 0x01, 0x00, 0x00, 0x00, 0x08, 0xFB, \
0x09, 0x01, 0x60, 0x00, 0x04, 0x01, 0x02, 0x03, 0x01

#define usbddsz 0x12
usbdd:
.db udd

#define ucd \
0x09, 0x02, 0x20, 0x00, 0x01, 0x01, 0x00, 0x80, 0x28, \
0x09, 0x04, 0x00, 0x00, 0x02, 0xFF, 0xFF, 0xFF, 0x00, \
0x07, 0x05, 0x81, 0x02, 0x40, 0x00, 0x01, \
0x07, 0x05, 0x02, 0x02, 0x40, 0x00, 0x01

#define usbcdsz 0x20
usbcd:
.db ucd

#define usbsd0sz 0x04 //0x904
usbsd0:
.db 0x04, 0x03, 0x09, 0x04

#define usbsd1sz 0x0E //Altera
usbsd1:
.db 0x0E, 0x03, 0x41, 0x00, 0x6C, 0x00, 0x74, 0x00, 0x65, 0x00, 0x72, 0x00, 0x61, 0x00

#define usbsd2sz 0x18 //USB-Blaster
usbsd2:
.db 0x18, 0x03, 0x55, 0x00, 0x53, 0x00, 0x42, 0x00, 0x2D, 0x00, 0x42, 0x00, 0x6C, 0x00, 0x61, 0x00, 0x73, 0x00, 0x74, 0x00, 0x65, 0x00, 0x72, 0x00

#define usbsd3sz 0x12 //00000000
usbsd3:
.db 0x12, 0x03, 0x30, 0x00, 0x30, 0x00, 0x30, 0x00, 0x30, 0x00, 0x30, 0x00, 0x30, 0x00, 0x30, 0x00, 0x30, 0x00

usbD:
.db 0x00, 0x00

//-------------------------------------


usb_get_descriptor:

	lds		r17,UEDATX //index
	lds		r16,UEDATX //type

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
	brne	ugddd

	cpi		r17,0 //LANG_ID 0x409
	brne	ugdsd1
	ldi		r16,usbsd0sz
	ldi		r30,LOW (usbsd0*2)
	ldi		r31,HIGH(usbsd0*2)
	rjmp	ugok
ugdsd1:
	cpi		r17,1 //Altera
	brne	ugdsd2
	ldi		r16,usbsd1sz
	ldi		r30,LOW (usbsd1*2)
	ldi		r31,HIGH(usbsd1*2)
	rjmp	ugok
ugdsd2:
	cpi		r17,2 //USB-Blaster
	brne	ugdsd3
	ldi		r16,usbsd2sz
	ldi		r30,LOW (usbsd2*2)
	ldi		r31,HIGH(usbsd2*2)
	rjmp	ugok
ugdsd3:
	cpi		r17,3 //00000000 - Serial
	brne	ugdf
	ldi		r16,usbsd3sz
	ldi		r30,LOW (usbsd3*2)
	ldi		r31,HIGH(usbsd3*2)
	rjmp	ugok

ugddd:
	cpi		r16,0x0A //DEBUG -- XXX new in Blaster code
	brne	ugdf
	ldi		r16,2
	ldi		r30,LOW (usbD*2)
	ldi		r31,HIGH(usbD*2)
	rjmp	ugok

ugdf: //failed
	ldi		r16,0
	ret

ugok:
	lds		r18,UEDATX //LangID
	lds		r19,UEDATX
	lds		r18,UEDATX //wLength
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

			cpi		r19,8//0x20 32 byte //if(nb_byte++==EP_CONTROL_LENGTH)
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
	andi	r17,7  //0x1F 32 byte//if((zlp == TRUE)) {
	brne	ugret
	rcall	wait_read_control
	rcall	usb_send_control_in
ugret:
	rcall	usb_ack_control_out
	ldi		r16,1
	ret

usb_user_endpoint_init:
	ldi		r31,0
	ldi		r30,UENUM

	ldi		r16,TX_EP
	st		Z,r16
	ldi		r16,TYPE_BULK | DIRECTION_IN
	ldi		r17,SIZE_64 | ONE_BANK
	rcall	usb_config_ep

	ldi		r16,RX_EP
	st		Z,r16
	ldi		r16,TYPE_BULK | DIRECTION_OUT
	ldi		r17,SIZE_64 | ONE_BANK
	rcall	usb_config_ep

	// reset ep
	ldi		r30,UERST
	ldi		r16,(1<<RX_EP)|(1<<TX_EP)
	st		Z,r16
	st		Z,rnull
	ret

//END USB
//=================================================================================================
//=================================================================================================
//Helper functions

SetPrescaler:
	ldi		r17,(1<<CLKPCE)
	sts		CLKPR,r17
	sts		CLKPR,r16
	ret

//-------------------------------------
/*
DelayU: //4us at 8MHz
	push	r17
DUloop:
	dec		r16
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
	ret*/

//-------------------------------------
/*
Delay0:
	tst		r16
	brne	Delay
	ret
Delay150:
	ldi		r16,150*/
Delay:	// r16 = delay in ms -- const r16 -- 0 == 256ms -- for 8MHz
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

//Helper functions
//=================================================================================================
//=================================================================================================

