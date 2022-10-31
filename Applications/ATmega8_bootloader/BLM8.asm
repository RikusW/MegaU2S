//BLM8.asm
//STK500 type bootloader for ATmega8
//Copyright 2010-2011 Rikus Wessels
//GNU GPLv2
//rikusw --- gmail --- com
//RikusW on #avr on freenode.net

//Use HighFuse=0xDA   LowFuse=0xFF   Lockbits=0xEF   Connect a 7.3728MHz crystal with 22pF caps.
//Use STK500pp for avrdude. Because avrdude use CMD_SPI_MULTI STK500v2 won't work.
//Both ISP and HVPP modes work for AVRStudio4.

//To enter bootload mode:
//1 Press Select while turning on power.
//2 Press Reset, press Select, release Reset.
//  The select button can be used to jump from app to bootloader.
//3 from the app do: clt   rjmp/jmp FLASHEND

#include <m8def.inc>
#include "command.h"

//-------------------------------------

#define C7MHZ //C14MHZ 14Mhz not tested
//#define HAS_SIGRD 
#define SW_MINOR 0x0A

#define jump rjmp //m8
//#define jump jmp  //m16->

#define SELBIT  2
#define SELPORT PORTD // Gnd->resistor->switch->IO (270R)
#define SELDDR  DDRD
#define SELPIN	PIND

#define LEDBIT	4
#define LEDPORT PORTD // Vcc->resistor->led->IO (>=270R)
#define LEDDDR	DDRD

//-------------------------------------

.dseg
PStart: //MUST BE before the other parameters
vtg:		.BYTE 1
vad:		.BYTE 1
pinit:		.BYTE 1
sckdur:		.BYTE 1
oscp:		.BYTE 1
oscc:		.BYTE 1
extrst:		.BYTE 1

address:	.BYTE 4
buffer:		.BYTE 282

//-------------------------------------
/*
r27:r26 X is getc_ptr
r29:r28 Y is putc_ptr
*/

.def rnull = r2 // this will always be 0 - NEVER set to anything else
.def rflag = r3
.def checksum = r4

.equ SPMCSR = SPMCR
.equ EEPE = EEWE
.equ EEMPE = EEMWE

//-------------------------------------

#define lo8(x) (x & 0xFF)
#define hi8(x) ((x >> 8) & 0xFF)

#define mlo8(x) ((-x) & 0xFF)
#define mhi8(x) (((-x) >> 8) & 0xFF)

//-------------------------------------

.cseg
//.org FIRSTBOOTSTART  //m64 --->m128 m256x DO RAMPZ FIRST !!! in ProgramFlash<---
//.org SECONDBOOTSTART //m32
.org THIRDBOOTSTART    //m8 m16
BLStart:
//-------------------------------------

	cli
	set
DoBL:

//-------------------------------------
Ms:
	clr		rnull // NEVER set this to anything other than 0

	ldi		r16,LOW (RAMEND)	//setup stack
	out		SPL,r16
	ldi		r17,HIGH(RAMEND)
	out		SPH,r17
Msel:
	ldi		XL,LOW (SRAM_START) //clear the ram
	ldi		XH,HIGH(SRAM_START)
Mnext:
	cp		XL,r16
	cpc		XH,r17
	st		X+,rnull
	brcs	Mnext

//-------------------------------------
// decide what to execute APP/BL

	cbi		SELDDR,SELBIT  //not needed ?
	sbi		SELPORT,SELBIT //pullup
	sbi		LEDPORT,LEDBIT //led off
	sbi		LEDDDR,LEDBIT  //led

	brtc	BLoad
	sbic	SELPIN,SELBIT  //if(SEL pressed)
	jump	0 //APP
BLoad:

	cbi		LEDPORT,LEDBIT // led on
Mselloop:
	sbis	SELPIN,SELBIT	//while(SEL);
	rjmp	Mselloop
	sbi		LEDPORT,LEDBIT // led off

//-------------------------------------

	ldi		r16,45 //4v5
	sts		vtg,r16
	ldi		r16,1
	sts		sckdur,r16
	sts		extrst,r16

//-------------------------------------==============================
//setup usart

#ifdef C7MHZ
	ldi		r16,3 //115k2 7,3728MHz
#else
#ifdef C14MHZ
	ldi		r16,7 //115k2 14,745MHz
#else
	#error No crystal defined
#endif
#endif
	out		UBRRH, rnull
	out		UBRRL, r16
	ldi 	r16, (1<<RXEN)|(1<<TXEN) //Enable RX & TX
	out 	UCSRB,r16
	ldi 	r16, (1<<URSEL)|(1<<UCSZ1)|(1<<UCSZ0) //8N1
	out 	UCSRC,r16
Mcal:

//---------------------- MAIN LOOP -------------------------

Mclr:
	ldi		r24,0 //xx DON'T move these
	ldi		r25,0 //xx
	clr		rflag
	sbi		LEDPORT,LEDBIT //led off
Mput:
	sbis	UCSRA, RXC
	rjmp	Mput
	in		r16,UDR
	rcall	PutByte
	tst		rflag
	breq	Mput //xx
	cbi		LEDPORT,LEDBIT //led on
	rcall	SendMsg
	rjmp	Mclr

//-------------------------------------==============================
/*
DoCal:
	sbis	UCSRA, RXC
	rjmp	DoCal
	in		r17,OSCCAL
	in		r16,UDR

	cpi		r16,'Q'
	breq	DCdone
	dec		r17 //default
DCend:
	out		UDR,r16
	out		OSCCAL,r17
	rjmp	DoCal
DCdone:
	out		UDR,r17
	rcall	SetToBL
	ret
*/
//-------------------------------------==============================

SendMsg:
//	sleep
//	if(rflag) or other flag like ??txie??

	ldi		r26,lo8(buffer) //getc_ptr = &buffer[5];
	ldi		r27,hi8(buffer)
	adiw	r26,5
	movw	r28,r26 //putc_ptr = &buffer[6];

	//if(checksum)
	tst		checksum
	breq	SMchecksumOK
		ldi		r16,0xB0 //ANSWER_CKSUM_ERROR
		st		Y+,r16
		ldi		r16,0xC1 //STATUS_CKSUM_ERROR
		st		Y+,r16
		rjmp	SMgenmsg

SMchecksumOK:
	adiw	r28,1 //go past cmd byte
	rcall	PutMsgBL

SMgenmsg:
//	rcall	GenMsg
//	ret

//END SendMsg

GenMsg:
	ldi		r30,lo8(buffer)
	ldi		r31,hi8(buffer)

	//set tx packet size
	movw	r24,r28
	sub		r24,r30
	sbc		r25,r31
	sbiw	r24,5
	std		Z+2,r25
	std		Z+3,r24

	//checksum
	ldi		r16,0
GMnext:
#ifndef DEBUG
	sbis	UCSRA,UDRE
	rjmp	GMnext
#endif
	ld		r17,Z+
	out		UDR,r17
	eor		r16,r17
	cp		r30,r28
	cpc		r31,r29
	brne	GMnext
GMnext2:
#ifndef DEBUG
	sbis	UCSRA,UDRE
	rjmp	GMnext2
#endif
	out		UDR,r16
	//st		Y+,r16 //debug or irq tx

	//buffer_index = 0;
	ldi		r24,0x00
	ldi		r25,0x00

	ret
}

//END GenMsg
//-------------------------------------

PutByte:
	eor  	checksum,r16

	//buffer[bufferi] = r16
	movw	r30,r24
	subi	r30,mlo8(buffer)
	sbci	r31,mhi8(buffer)
	st		Z,r16
	//bufferi++;
	adiw	r24,1

	//if(buffer_index > 5)
	cpi		r24,0x06
	cpc		r25,rnull
	brcs	PBn1
	//{-----
//		cbi		PORTD,3 //dd

		//if(buffer_index == buffer_index_max)
		cp		r24,r26
		cpc		r25,r27
		brne	PBov
		//{
//			sbi		PORTD,3 //dd
			ldi		r16,1
			mov		rflag,r16
			rjmp	PBrst
		//}
	PBov:
		//if(buffer_index > 281) =281;
		ldi		r16,mlo8(282)
		cp		r24,r16
//		cpi		r24,mlo8(282) ???
		ldi		r16,mhi8(282)
		cpc		r25,r16
		brcs	PBret1;
		//{
			ldi		r24,lo8(281)
			ldi		r25,hi8(281)
	PBret1:
			ret
		//}

	//}
	//}-----

PBn1:
	cpi		r24,0x01
	brne	PBn2
	cpi		r16,0x1B
	brne	PBrst
//	cbi		PORTD,2 //dd
	mov		checksum,r16
	ret
PBn2:
	cpi		r24,0x02
	breq	PBret
PBn3:
	cpi		r24,0x03
	brne	PBn4
	mov		r27,r16
	ret
PBn4:
	cpi		r24,0x04
	brne	PBn5
	mov		r26,r16
	adiw	r26,0x06
	ret
PBn5:
	cpi		r24,0x05
	brne	PBrst
	cpi		r16,0x0E
//	brne	PBrst //dd
//	sbi		PORTD,2 //dd
	breq	PBret
PBrst:
	//buffer_index = 0;
	ldi		r24,0x00
	ldi		r25,0x00
PBret:
	ret

//END PutByte
//-------------------------------------==============================

Delay150:
	ldi		r16,150

Delay:	// r16 = delay in ms -- const r16
	push	r16
	push	r17
	push	r18
D16:
	ldi		r17,38
	D17:
		ldi		r18,48 //==195 clks * 38
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

DoSwitch:
	lpm		r0,Z+
	lpm		r1,Z+
	tst		r1
	breq	DSret
	sub		r16,r0
	brcs	DSret
	cp		r16,r1
	brcs	DSok
	add		r30,r1
	adc		r31,rnull
	rjmp	DoSwitch

DSok:
	add		r30,r16
	adc		r31,rnull
	lpm
	pop		r19
	pop		r18
	add		r18,r0
	adc		r19,rnull
	push	r18
	push	r19
DSret:
	ret

//=================================================================================================
//=================================================================================================
// BL switch

PMBjt:
.db 0x00,0x08
.db PMBs00 - PMBij, PMBs01 - PMBij
.db PMBs02 - PMBij, PMBs03 - PMBij
.db PMBs04 - PMBij, PMBs05 - PMBij
.db PMBs06 - PMBij, PMBs07 - PMBij
.db 0x10,0x1E
.db PMBs10 - PMBij, PMBs11 - PMBij
.db PMBs12 - PMBij, PMBs13 - PMBij
.db PMBs14 - PMBij, PMBs15 - PMBij
.db PMBs16 - PMBij, PMBs17 - PMBij
.db PMBs18 - PMBij, PMBs19 - PMBij
.db PMBs1A - PMBij, PMBs1B - PMBij
.db PMBs1C - PMBij, PMBs1D - PMBij

.db PMBs1E - PMBij, PMBs1F - PMBij

.db PMBs20 - PMBij, PMBs21 - PMBij
.db PMBs22 - PMBij, PMBs23 - PMBij
.db PMBs24 - PMBij, PMBs25 - PMBij
.db PMBs26 - PMBij, PMBs27 - PMBij
.db PMBs28 - PMBij, PMBs29 - PMBij
.db PMBs2A - PMBij, PMBs2B - PMBij
.db PMBs2C - PMBij, PMBs2D - PMBij
.db 0,0

PutMsgBL:
	clt //HVPP default
	ld		r16,X+
	ldi		r30,lo8(PMBjt*2)
	ldi		r31,hi8(PMBjt*2)
	rcall	DoSwitch

PMBij:
PMBs00:
PMBs1E:
	ldi		r16,STATUS_CMD_UNKNOWN
	rjmp	PMBretr16
PMBs04: //CMD_SET_DEVICE_PARAMETERS
PMBs05: //CMD_OSCCAL
PMBs07: //CMD_FIRMWARE_UPGRADE
PMBfail:
	ldi		r16,STATUS_CMD_FAILED
PMBretr16:
	st		Y+,r16
	ret

//------------------------------
PMBs01: //CMD_SIGN_ON
	rjmp	SendSignOn
PMBs02: //CMD_SET_PARAMETER
	rjmp	SetParameter
PMBs03: //CMD_GET_PARAMETER
	rjmp	GetParameter
PMBs06: //CMD_LOAD_ADDRESS
	rcall	SetAddress
	rjmp	PMBok
//------------------------------

PMBs17: //CMD_PROGRAM_FUSE_ISP -- can't be implemented
PMBs19: //CMD_PROGRAM_LOCK_ISP -- rather don't implement this...
	st		Y+,rnull //STATUS_CMD_OK
PMBs10: //CMD_ENTER_PROGMODE_ISP
PMBs11: //CMD_LEAVE_PROGMODE_ISP
PMBs12: //CMD_CHIP_ERASE_ISP

PMBs20: //CMD_ENTER_PROGMODE_PP
PMBs21: //CMD_LEAVE_PROGMODE_PP
PMBs22: //CMD_CHIP_ERASE_PP
PMBs27: //CMD_PROGRAM_FUSE_PP
PMBs29: //CMD_PROGRAM_LOCK_PP
PMBs2D: //CMD_SET_CONTROL_STACK
	rjmp	PMBok
//------------------------------


PMBs23: //CMD_PROGRAM_FLASH_PP //XXX
	ld		r23,X+
	ld		r22,X+
	adiw	XH:XL,2
	rjmp	ProgramFlash
PMBs13: //CMD_PROGRAM_FLASH_ISP
	ld		r23,X+
	ld		r22,X+
	adiw	XH:XL,7
	rjmp	ProgramFlash
PMBs14: //CMD_READ_FLASH_ISP
PMBs24: //CMD_READ_FLASH_PP
	rcall	SetupRWFlEep
	st		Y+,rnull //STATUS_CMD_OK
	lsl		r30
	rol		r31
PMBrfl:
	lpm		r16,Z+
PMBrfl0:
	st		Y+,r16
	sbiw	r24,1 // MUST be even
	brne	PMBrfl
	lsr		r31
	ror		r30
	rjmp	PMBsta

PMBs25: //CMD_PROGRAM_EEPROM_PP //XXX
	rcall	SetupRWFlEep
	adiw	XH:XL,2
	rjmp	PMBwee
PMBs15: //CMD_PROGRAM_EEPROM_ISP
	rcall	SetupRWFlEep
	adiw	XH:XL,7
PMBwee:
	ld		r17,X+
	rcall	WriteEEP
	adiw	r30,1
	sbiw	r24,1
	brne	PMBwee
	rjmp	PMBsta

PMBs16: //CMD_READ_EEPROM_ISP
PMBs26: //CMD_READ_EEPROM_PP
	rcall	SetupRWFlEep
	st		Y+,rnull //STATUS_CMD_OK
PMBree:
	rcall	ReadEEP
	st		Y+,r16
	adiw	r30,1
	sbiw	r24,1
	brne	PMBree
	rjmp	PMBsta


PMBs18: //CMD_READ_FUSE_ISP
PMBs1A: //CMD_READ_LOCK_ISP
	set
	ldi		r30,0x00
	adiw	XH:XL,1 //pollIndex
	ld		r16,X+
	sbrc	r16,3 //58 == 1/3 == b0
	ori		r30,1
	ld		r16,X+
	sbrc	r16,3 //08 == 2/3 == b1
	ori		r30,2
	rjmp	PMBrfo

PMBs2A: //CMD_READ_LOCK_PP
	ldi		r31,3
	rjmp	PMBs28a
PMBs28: //CMD_READ_FUSE_PP
	ld		r31,X+ //0,1,2
PMBs28a:
	ldi		r30,4   // Convert
	sub		r30,r31 // 0 1 2 3
	andi	r30,3   // 0 3 2 1
PMBrfo:
	ldi		r31,0
	ldi		r16,(1<<BLBSET)|(1<<SPMEN)
	out		SPMCSR,r16
	lpm
PMBroc:
	st		Y+,rnull //STATUS_CMD_OK
	st		Y+,r0
	brts	PMBok //no trailing 0 for HVPP
	ret

#ifdef HAS_SIGRD
PMBs1B: //CMD_READ_SIGNATURE_ISP
	ldi		r17,0
	rjmp	PMBs1Cx
PMBs1C: //CMD_READ_OSCCAL_ISP //sigrd
	ldi		r17,1
PMBs1Cx:
	movw	r30,r26
	ldd		r16,Z+3
	set
	rjmp	PMBs1Cz

PMBs2B: //CMD_READ_SIGNATURE_PP
	ldi		r17,0
	rjmp	PMBs2Cx
PMBs2C: //CMD_READ_OSCCAL_PP
	ldi		r17,1
PMBs2Cx:
	ld		r16,X+
PMBs1Cz:
	lsl		r16
	add		r16,r17
	mov		r30,r16
	ldi		r31,0
	ldi		r16,(1<<SIGRD)|(1<<SPMEN)
	out		SPMCSR,r16
	lpm
	rjmp	PMBroc
#else
PMBs1C: //CMD_READ_OSCCAL_ISP
	set
PMBs2C: //CMD_READ_OSCCAL_PP
	lds		r0,OSCCAL
	rjmp	PMBroc

PMBs1B: //CMD_READ_SIGNATURE_ISP
	set
	movw	r30,r26
	ldd		r16,Z+3
	rjmp	PMBs1Bx
PMBs2B: //CMD_READ_SIGNATURE_PP
	ld		r16,X
PMBs1Bx:
	andi	r16,3
	ldi		r30,lo8(PMBs1Bsig*2)
	ldi		r31,hi8(PMBs1Bsig*2)
	add		r30,r16
	adc		r31,rnull //check alignment of data!!! if commented
	lpm
	rjmp	PMBroc
PMBs1Bsig:
	.db SIGNATURE_000, SIGNATURE_001, SIGNATURE_002, 0x00
#endif

PMBs1D: //CMD_SPI_MULTI -- seems not to be used ???
	rjmp	PMBfail

//----------
PMBs1F: //page erase extension <-- EXTENSION
	rcall	SetupRWFlEep
	cpi		r25,0xA3 //check byte after command
	brne	PMBs1D //fail
	mov		r16,r24
	andi	r16,((PAGESIZE*2)+1)
	brne	PMBs1D //alignment incorrect
//----------
PMBs1Fnext:
	rcall	SpmWait
	ldi		r16,(1<<SPMEN)|(1<<PGERS)
	out		SPMCSR,r16
	spm

	subi	r30,mlo8(PAGESIZE*2)
	sbci	r31,mhi8(PAGESIZE*2)
	dec		r24
	brne	PMBs1Fnext
//----------
PMBs1Fe:
	rcall	SpmWait
	ldi		r16,(1<<RWWSRE)|(1<<SPMEN)
	out		SPMCSR,r16
	spm
//----------

PMBsta:// PMIsta:
	sts		address  ,r30
	sts		address+1,r31
PMBok:// PMIok:
	st		Y+,rnull //STATUS_CMD_OK
	ret

SetupRWFlEep:
	ld		r25,X+
	ld		r24,X+
	lds		r30,address
	lds		r31,address+1
	ret

//END PutMsgBL
//-------------------------------------==============================

GPjt:
.db 0x80,0x02 //0x80
.db GPs80 - GPij, GPs81 - GPij
.db 0x10,0x10 //0x90
.db GPs90 - GPij, GPs91 - GPij
.db GPs92 - GPij, GPs93 - GPij
.db GPs94 - GPij, GPs95 - GPij
.db GPs96 - GPij, GPs97 - GPij
.db GPs98 - GPij, GPs99 - GPij
.db GPs9A - GPij, GPs9B - GPij
.db GPs9C - GPij, GPs9D - GPij
.db GPs9E - GPij, GPs9F - GPij
.db 0,0

GetParameter:
	ld		r16,X+
	ldi		r30,lo8(GPjt*2)
	ldi		r31,hi8(GPjt*2)
	rcall 	DoSwitch
GPij:

GPs93: GPs99: GPs9B: GPs9E: //PARAM_RESET_POLARITY
GPfail:
	ldi		r17,STATUS_CMD_FAILED
	rjmp	GPret

GPs90: //PARAM_HW_VER
GPs91: //PARAM_SW_MAJOR
	ldi		r17,0x02
	rjmp	GPok
GPs92: //PARAM_SW_MINOR
	ldi		r17,SW_MINOR
	rjmp	GPok

//-----
GPs94: //PARAM_VTARGET
	ldi 	r30,vtg-Pstart
	rjmp 	GPld
GPs95: //PARAM_VADJUST
	ldi 	r30,vad-Pstart
	rjmp 	GPld
GPs96: //PARAM_OSC_PSCALE
	ldi 	r30,oscp-Pstart
	rjmp 	GPld
GPs97: //PARAM_OSC_CMATCH
	ldi 	r30,oscc-Pstart
	rjmp 	GPld
GPs98: //PARAM_SCK_DURATION
	ldi 	r30,sckdur-Pstart
	rjmp 	GPld
GPs9F: //PARAM_CONTROLLER_INIT
	ldi 	r30,pinit-Pstart
GPld:
	ldi		r31,0
	subi	r30,mlo8(Pstart)
	sbci	r31,mhi8(Pstart)
	ld		r17,Z
	rjmp	GPok
//-----


GPs9A: //PARAM_TOPCARD_DETECT
GPs9D: //PARAM_DATA
	ldi		r17,0xFF
	rjmp	GPok
GPs9C: //PARAM_STATUS
GPr0:
GPs80:
GPs81:
	ldi		r17,0x00
//	rjmp	GPok

GPok:
//	ldi		r16,STATUS_CMD_OK
	st		Y+,rnull
GPret:
	st		Y+,r17
	ret

//END GetParameter:
//-------------------------------------

SPjt:
.db 0x94,0x06
.db SPs94 - SPij, SPs95 - SPij
.db SPs96 - SPij, SPs97 - SPij
.db SPs98 - SPij, 0
.db 0x0A,0x02
.db SPs9E - SPij, SPs9F - SPij
.db 0,0

SetParameter:
	ld		r16,X+
	ldi		r30,lo8(SPjt*2)
	ldi		r31,hi8(SPjt*2)
	rcall	DoSwitch
SPij:
	ldi		r16,STATUS_CMD_FAILED
	st		Y+,r16
	ret

SPs94: //PARAM_VTARGET
	ldi 	r30,vtg-Pstart
	rjmp 	SPok
SPs95: //PARAM_VADJUST
	ldi 	r30,vad-Pstart
	rjmp 	SPok

SPs96: //PARAM_OSC_PSCALE
	ldi 	r30,oscp-Pstart
	rjmp	SPs97x
SPs97: //PARAM_OSC_CMATCH
	ldi 	r30,oscc-Pstart
SPs97x:
	rjmp 	SPok

SPs98: //PARAM_SCK_DURATION
	ldi 	r30,sckdur-Pstart
	rjmp 	SPok
SPs9E: //PARAM_RESET_POLARITY
	ldi 	r30,extrst-Pstart
	rjmp 	SPok
SPs9F: //PARAM_CONTROLLER_INIT
	ldi 	r30,pinit-Pstart

SPok:
	ldi		r31,0
	subi	r30,mlo8(Pstart)
	sbci	r31,mhi8(Pstart)
	ld		r16,X+
	st		Z,r16
	st		Y+,rnull //STATUS_CMD_OK
	ret


//END SetParameter:
//-------------------------------------

Sign:
.db 0,8,'S','T','K','5','0','0','_','2'

SendSignOn:
	ldi		r16,10
	ldi		r30,lo8(Sign*2)
	ldi		r31,hi8(Sign*2)
SSnext:
	lpm		r17,Z+
	st		Y+,r17
	dec		r16
	brne	SSnext
	ret

//END SendSignOn
//-------------------------------------

SetAddress:
	ldi		r30,lo8(address)
	ldi		r31,hi8(address)

	ld		r16,X+
	ori		r16,0x40 //enable LoadEA
	std		Z+3,r16
	ld		r16,X+
	std		Z+2,r16
	ld		r16,X+
	std		Z+1,r16
	ld		r16,X+
	std		Z+0,r16
	ret

//END SetAddress
//-------------------------------------==============================
// BL extra code

SpmWait:
	in		r16,SPMCSR
	sbrc	r16,SPMEN
	rjmp	SpmWait
SW2:
	sbic	EECR,EEPE
	rjmp	SW2
	ret

//ReadEEPL:
//	ldi		r31,0
ReadEEP:
	rcall	SpmWait

	out		EEARH,r31
	out		EEARL,r30
	sbi		EECR,EERE
	in		r16,EEDR
	ret

WriteEEP: //r17=data
	rcall	ReadEEP
	cp		r16,r17
	breq	WRret
	out		EEDR,r17
//	cli
	sbi		EECR,EEMPE
	sbi		EECR,EEPE
//	out		EEARH,rnull
//	out		EEARH,rnull
//	sei
WRret:
	sbic	EECR,EEPE
	rjmp	WRret
	ret

//END RWeadEEP
//-------------------------------------
// 64k limit

ProgramFlash: //r22r23 == size
	set
PFnext:
	lds		r30,address
	lds		r31,address+1 //word address
	//lds	rxx,address+2

	//protect the bootloader, bootsection SPM lockbit should be set as well
	cpi		r30,lo8(BLStart)
	ldi		r16,hi8(BLStart)
	cpc		r31,r16
	brcc	PFfail //BL cannot overwrite BL

	mov		r16,r30
	andi	r16,(PAGESIZE-1) //eg 0x3F
	breq	PFgo //aligned write
PFfail:
	ldi		r16,STATUS_CMD_FAILED
	st		Y+,r16
	ret

PFgo:
	lsl		r30 // 64k limit //byte address
	rol		r31 // 64k limit
//	rol		rxx // no limit

	ldi		r24,lo8(PAGESIZE*2)
	ldi		r25,hi8(PAGESIZE*2)
	sub		r22,r24
	sbc		r23,r25
	brcs	PFfail //data length is not a multiple of PAGESIZE
	brne	PFset
	clt
PFset:

	push	r30
	push	r31 //push rxx  mov rampz,rxx
//========
PMwfl:
	ld		r0,X+
	ld		r1,X+
//----------
	rcall	SpmWait
	ldi		r16,(1<<SPMEN)
	out		SPMCSR,r16
	spm
//----------
	adiw	ZH:ZL,2 // adc rxx,rnull
	sbiw	r24,2
	brne	PMwfl
//========

	//save address
//	lsr		rxx   ror r31
	lsr		r31
	ror		r30
	sts		address  ,r30
	sts		address+1,r31

	pop		r31
	pop		r30
//----------
	rcall	SpmWait
	ldi		r16,(1<<SPMEN)|(1<<PGERS)
	out		SPMCSR,r16
	spm
//----------
	rcall	SpmWait
	ldi		r16,(1<<SPMEN)|(1<<PGWRT)
	out		SPMCSR,r16
	spm
//----------
	rcall	SpmWait
	ldi		r16,(1<<RWWSRE)|(1<<SPMEN)
	out		SPMCSR,r16
	spm
//----------
	brts	PFnext
	st		Y+,rnull //STATUS_CMD_OK
	ret


//END ProgramFlash
//=================================================================================================
//=================================================================================================

.org FLASHEND
	rjmp	DoBL



/* From the XML Partdescription files
    <STK500_2>
      <IspEnterProgMode>
        <timeout>200</timeout>
        <stabDelay>100</stabDelay>
        <cmdexeDelay>25</cmdexeDelay>
        <synchLoops>32</synchLoops>
        <byteDelay>0</byteDelay>
        <pollIndex>3</pollIndex>
        <pollValue>0x53</pollValue>
      </IspEnterProgMode>

      <IspLeaveProgMode>
        <preDelay>1</preDelay>
        <postDelay>1</postDelay>
      </IspLeaveProgMode>

      <IspChipErase>
        <eraseDelay>20</eraseDelay>
        <pollMethod>0</pollMethod>
      </IspChipErase>

      <IspProgramFlash>
        <mode>0x21</mode>
        <blockSize>64</blockSize>
        <delay>10</delay>
        <cmd1>0x40</cmd1>
        <cmd2>0x4C</cmd2>
        <cmd3>0x20</cmd3>
        <pollVal1>0xFF</pollVal1>
        <pollVal2>0x00</pollVal2>
      </IspProgramFlash>

      <IspProgramEeprom>
        <mode>0x04</mode>
        <blockSize>128</blockSize>
        <delay>20</delay>
        <cmd1>0xC0</cmd1>
        <cmd2>0x00</cmd2>
        <cmd3>0xA0</cmd3>
        <pollVal1>0xFF</pollVal1>
        <pollVal2>0xFF</pollVal2>
      </IspProgramEeprom>

      <IspReadFlash>
        <blockSize>256</blockSize>
      </IspReadFlash>

      <IspReadEeprom>
        <blockSize>256</blockSize>
      </IspReadEeprom>

      <IspReadFuse>
        <pollIndex>4</pollIndex>
      </IspReadFuse>

      <IspReadLock>
        <pollIndex>4</pollIndex>
      </IspReadLock>

      <IspReadSign>
        <pollIndex>4</pollIndex>
      </IspReadSign>

      <IspReadOsccal>
        <pollIndex>4</pollIndex>
      </IspReadOsccal>

      <PPControlStack>0x0E 0x1E 0x0F 0x1F 0x2E 0x3E 0x2F 0x3F 0x4E 0x5E 0x4F 0x5F 0x6E 0x7E 0x6F 0x7F 0x66 0x76 0x67 0x77 0x6A 0x7A 0x6B 0x7B 0xBE 0xFD 0x00 0x01 0x00 0x00 0x00 0x00</PPControlStack>

      <PpEnterProgMode>
        <stabDelay>100</stabDelay>
        <progModeDelay>0</progModeDelay>
        <latchCycles>5</latchCycles>
        <toggleVtg>1</toggleVtg>
        <powerOffDelay>15</powerOffDelay>
        <resetDelayMs>2</resetDelayMs>
        <resetDelayUs>0</resetDelayUs>
      </PpEnterProgMode>

      <PpLeaveProgMode>
        <stabDelay>15</stabDelay>
        <resetDelay>15</resetDelay>
      </PpLeaveProgMode>

      <PpChipErase>
        <pulseWidth>0</pulseWidth>
        <pollTimeout>20</pollTimeout>
      </PpChipErase>

      <PpProgramFlash>
        <pollTimeout>10</pollTimeout>
        <mode>0x0D</mode>
        <blockSize>256</blockSize>
      </PpProgramFlash>

      <PpReadFlash>
        <blockSize>256</blockSize>
      </PpReadFlash>

      <PpProgramEeprom>
        <pollTimeout>10</pollTimeout>
        <mode>0x05</mode>
        <blockSize>256</blockSize>
      </PpProgramEeprom>

      <PpReadEeprom>
        <blockSize>256</blockSize>
      </PpReadEeprom>

      <PpProgramFuse>
        <pulseWidth>0</pulseWidth>
        <pollTimeout>10</pollTimeout>
      </PpProgramFuse>

      <PpProgramLock>
        <pulseWidth>0</pulseWidth>
        <pollTimeout>10</pollTimeout>
      </PpProgramLock>
    </STK500_2>
*/
