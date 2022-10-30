//Blisp32U2.asm
//STK500 type bootloader with loadable module support for ATmega16U2 / ATmega32U2
//The ISP/HVPP/HVSP programmer is included as a module in STK500.asm
//Copyright 2010 Rikus Wessels
//This is free for personal or non-profit use, for commercial use contact me.
//rikusw --- gmail --- com

//Compiled using AVRStudio 4.18, 5 or 6 should also work.
//20110912 V3 added mode E for emergency bootloader repair
//20111125 V3 added Select goes from stk500/debug mode to bootloader mode <-- removed
//20120211 V3 removed the above line's functionality due to a HVPP conflict
//20120817 V4 LeavePMSP - set DDRC 56 as inputs, leave power on and reset at 5V
//20120817 V4 Moved DelayU, again.... finally to (THIRDBOOTSTART-15)
//20120818 V4 LeavePMSP - power on/off from bit0 parameter 0x9B

#if 0
#include <m16U2def.inc>
#else
#include <m32U2def.inc>
#endif

//-------------------------------------

#include "usb_commun.h"
#include "usb_commun_cdc.h"
#include "command.h"

#define HAS_SIGRD

// build magic to match bootloader and isp
#define BUILDML 0x5A
#define BUILDMH 0xA5

#define INT_EP		0x01
#define TX_EP		0x03
#define RX_EP		0x04

//-------------------------------------
.eseg
.org EEPROMEND-0xF
eesel:	 .db	0x81 // xx sel (0x80 - bl mode) (0x40 no usb_setup) (0x20 no led flashing) (0x10 no var init)

eeshw:	 .db	0x02 // 00 stk HW version
eesjv:	 .db	0x02 // 01 stk major version
eesmv:	 .db	0x0A // 02 stk minor version
eeadl:   .db	0xB0 // 03 1s Arduino delay -> (256-eeadl) * 12800us <<====
eevtg:   .db	48   // 04 VTG
eevad:   .db	0    // 05 VAD
eeoscp:	 .db	0x00 // 06 clkgen
eeoscc:	 .db	0x00 // 07 clkgen
eesck:	 .db	0x02 // 08 sck duration 1==125kHz
ee232:   .db	0x00 // 09 rs232 mode <<====
ee0A:    .db	0xFF // 0A topcard
ee0B:    .db	0xFF // 0B reserved value <<====
ee0C:    .db	0x00 // 0C ?status?
ee0D:    .db	0xFF // 0D ?data?
eerst:   .db	0x01 // 0E ext rst 1=AVR // fix for avrdude

//-------------------------------------

#define LF_CODING	1
#define LF_STATUS	2
#define LF_BREAK	4

.dseg
conf_nr:		.BYTE 1
line_flags:		.BYTE 1 // 1=coding 2=status 4=break
line_coding:	.BYTE 7
line_status:	.BYTE 2
line_break:		.BYTE 2

//----------------------
EStart:
sel:		.BYTE 1 // xx this MUST be in the same order as the eep values
PStart:
shw:		.BYTE 1 // 00
sjv:		.BYTE 1 // 01
smv:		.BYTE 1 // 02
adl:		.BYTE 1 // 03 <<===
vtg:		.BYTE 1 // 04
vad:		.BYTE 1 // 05
oscp:		.BYTE 1 // 06
oscc:		.BYTE 1 // 07
sckdur:		.BYTE 1 // 08
rs232:		.BYTE 1 // 09 <<===
topcard:	.BYTE 1 // 0A
misc:		.BYTE 1 // 0B <<=== config bits (0-HVSP leave power)
status:		.BYTE 1 // 0C
pdata:		.BYTE 1 // 0D
extrst:		.BYTE 1 // 0E
ee_end:
pinit:		.BYTE 1 // 0F = 0;
//----------------------

blstarta:	.BYTE 2
address:	.BYTE 4  // keep these
spstack:	//same as below
ppstack:	.BYTE 32 // two together
buffer:		.BYTE 282
buf:		.BYTE 1

LatchC:		.BYTE 1 // for HVSP

//-------------------------------------
/*
r27:r26 X is getc_ptr
r29:r28 Y is putc_ptr
*/

.def rnull = r2 // this will always be 0 - NEVER set to anything else
.def rflag = r3
.def checksum = r4
.def flo = r6
.def fhi = r7

//-------------------------------------

#define lo8(x) (x & 0xFF)
#define hi8(x) ((x >> 8) & 0xFF)

#define mlo8(x) ((-x) & 0xFF)
#define mhi8(x) (((-x) >> 8) & 0xFF)

#define SELBIT  4
#define SELPORT PORTC
#define SELDDR  DDRC
#define SELPIN	PINC

#define LEDBIT	2
#define LEDPIN	PINC
#define LEDPORT PORTC
#define LEDDDR	DDRC

//=================================================================================================
//=================================================================================================
.cseg
.org THIRDBOOTSTART-0x580
ISPStart:
	rjmp	ISPEnd
ISPEntry:
	rcall	SetupEClk
	ldi		r16,52
	sts		vtg,r16
	ldi		r16,lo8(PutMsgISP-ISPEntry)
	ret

#include "STK500.asm"

//.db 0,0//,0,0,0,0 // padding

.db	BUILDML, BUILDMH, LOW(ISPEnd-ISPEntry), HIGH(ISPEnd-ISPEntry), 0, 2
ISPEnd:
//=================================================================================================
//Debug
DBStart:
	rjmp	BLStart

DBEntry:
	ldi		r16,30
	sts		vtg,r16
	ldi		r16,lo8(PutMsgDB-DBEntry)
	ret

PutMsgDB:
	ld		r16,X+
	cpi		r16,0xFE
	breq	PMDgo
	cpi		r16,0x01
	brne	PMDunk
	rjmp	SendSignOn
PMDunk:
	ldi		r16,STATUS_CMD_UNKNOWN
	st		Y+,r16
	ret
PMDgo:
	ld		r19,X+ //number
	st		Y+,rnull

PMDnext:
	ld		r16,X+
	subi	r19,1
	brcc	PMDs0
	st		Y+,rnull
	ret

PMDs0: //memr
	cpi		r16,0
	brne	PMDs1
	ld		r31,X+
	ld		r30,X+
	ld		r16,Z
	st		Y+,r16
	rjmp	PMDnext
PMDs1: //memw
	cpi		r16,1
	brne	PMDs2
	ld		r31,X+
	ld		r30,X+
	ld		r16,X+
	st		Z,r16
	rjmp	PMDnext
PMDs2: //memwb
	cpi		r16,2
	brne	PMDs3
	ld		r31,X+
	ld		r30,X+
	ld		r16,X+ //and mask
	ld		r17,X+ //or  mask
	ld		r18,Z
	and		r18,r16
	or		r18,r17
	st		Z,r18
	rjmp	PMDnext
PMDs3:
	cpi		r16,3 //Delay ms
	brne	PMDs4
	ld		r16,X+
	rcall	Delay0
	rjmp	PMDnext
PMDs4:
	cpi		r16,4 // Delay 4us
	brne	PMDnext
	ld		r16,X+
	rcall	DelayU
	rjmp	PMDnext

.db	BUILDML, BUILDMH, LOW(DBEnd-DBEntry), HIGH(DBEnd-DBEntry), 0, 0
DBEnd:
//Debug
//=================================================================================================
//Arduino
ArStart:
	rjmp	BLStart

ArEntry:
	ldi		r16,50
	sts		vtg,r16
	ldi		r16,lo8(ArApp-ArEntry)
	mov		r5,r16
	ret

ArApp:
	ldi		r16,lo8(PutMsgBL)
	ldi		r17,hi8(PutMsgBL)
	movw	flo,r16

ArMclr:
	clr		r8
	lds		r9,adl
	ldi		r24,0 //xx DON'T move these
	ldi		r25,0 //xx
	clr		rflag
	sbi		LEDPORT,LEDBIT //led off

ArMput:
//-----------------------------------
	//~1 second timeout at r9=0xB0 and 50us loop
	// ((0x100-r9) * 0x100) * 50us
	inc		r8
	brne	ArLed
	inc		r9
	brne	ArLed
	sbi		LEDPORT,LEDBIT //led off
	ldi		r24,1
	sts		sel,r24
	sts		line_flags,rnull
	jmp		0	 // to APP
ArLed:
	sbi		LEDPORT,LEDBIT //led off
//	ldi		r16,5 //20us
	ldi		r16,10 //40us
	rcall	DelayU
	cbi		LEDPORT,LEDBIT //led on
//-----------------------------------
	rcall	usb_task
	rcall	usb_peek
	breq	ArMput
	rcall	usb_getc
	rcall	PutByte
	tst		rflag
	breq	ArMput //xx
	cbi		LEDPORT,LEDBIT //led on
	rcall	SendMsg
	rjmp	ArMclr

.db	BUILDML, BUILDMH, LOW(ArEnd-ArEntry), HIGH(ArEnd-ArEntry), 0, 0xF
ArEnd:
//Arduino
//=================================================================================================
SMEntry: //SetToMod:
	clr		r5
	lds		r25,sel
	andi	r24,0x0F

//	rcall	usb_getc //XXX
//	rjmp	SMEntry  //XXX test mode E 20110912

//	ldi		r16,48
//	sts		vtg,r16
//	ldi		r16,lo8(PutMsgBL)
//	ldi		r17,hi8(PutMsgBL)
//	movw	flo,r16

	ldi		r23,0
	ldi		r30,lo8(SMEntry+1)
	ldi		r31,hi8(SMEntry+1)
STMnext:
	lsl		r30 // word to lpm ptr -- 64k limit
	rol		r31
	sbiw	r30,8 // to previous module
	lpm		r17,Z+
	lpm		r18,Z+
	cpi		r17,BUILDML
	brne	STMend1
	cpi		r18,BUILDMH
	brne	STMend1
	lpm		r18,Z+ //szl
	lpm		r19,Z+ //szh
	lpm		r17,Z+ //?sze?
	lpm		r17,Z+ //sel
	lsr		r31 //lpm to word ptr
	ror		r30
	sub		r30,r18
	sbc		r31,r19

	cpi		r24,1   //if another module is nr 1
	breq	STMnext //then it will cause a bl lockout...
	cp		r24,r17
	brne	STMnext

	icall //returned r16 == offset from Z to PutMsgX
	mov		flo,r16
	clr		fhi
	add		flo,r30
	adc		fhi,r31

	inc		r23
	rjmp	STMnext

STMend1:
	adiw	r30,4
	sts		blstarta  ,r30
	sts		blstarta+1,r31
	tst		r23
	brne	STMret
	ldi		r25,0x81 // no matching mod found, set to bl
	sts		sel,r25  // save selection 20110912
	ret

STMret:
	sts		sel,r25  // save selection

	tst		r5 //not putmsg but app ?
	breq	STMr
	movw	r30,flo
	ijmp
STMr:
	ret

.org THIRDBOOTSTART-15
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
	ret

//.org THIRDBOOTSTART-6   20120817
//.db 0,0,0,0,0,0
//.org THIRDBOOTSTART-3
//	rjmp	DelayU

.db	BUILDML, BUILDMH
	rjmp	SMEntry
SMEnd:

//=================================================================================================
//=================================================================================================
//=================================================================================================
//Bootloader

.org THIRDBOOTSTART //0x1C00 16U2 -- 0x3C00 32U2 -- 4KB
BSStart:
BLStart:
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

	//if(signature not valid)
	cpi		ZL,0x53
	brne	Mss
	cpi		ZH,0xCA
	breq	Msel
	Mss://set signature
		ldi		r24,0 //sel
		ldi		ZL,0x53
		ldi		ZH,0xCA

//-------------------------------------

Msel:
	ldi		r16,LOW (RAMEND)
	ldi		r17,HIGH(RAMEND)
	ldi		XL,LOW (SRAM_START) //clear the ram
	sbrc	r24,4 //0x10 no line vars init
	ldi		XL,LOW (SRAM_START+13) //clear the ram
	ldi		XH,HIGH(SRAM_START)
Mnext:
	cp		XL,r16
	cpc		XH,r17
	st		X+,rnull
	brcs	Mnext

//-------------------------------------
// decide what to execute APP/BL/ISP
//#ifndef INJECT
	sbi		LEDPORT,LEDBIT // led off
	sbi		LEDDDR,LEDBIT //led
	sbi		SELPORT,SELBIT //pullup
	cbi		SELDDR,SELBIT // not needed ?
	sbic	SELPIN,SELBIT  //if(SEL pressed)
	rjmp	MSELoff
		inc		r24
		cbi		LEDPORT,LEDBIT // led on
	Mselloop:
		sbis	SELPIN,SELBIT	//while(SEL);
		rjmp	Mselloop
		sbi		LEDPORT,LEDBIT // led off
		ori		r24,0x80
//		ldi		r16,150
//		rcall	Delay
MSELoff:
//#endif
//-------------------------------------
//variable init

	ldi		ZL,lo8(EEPROMEND-0xF) //reset signature cleared here
	ldi		ZH,hi8(EEPROMEND-0xF)
	ldi		YL,lo8(EStart)
	ldi		YH,hi8(EStart)
Mvnext:
	rcall	ReadEEP
	adiw	ZL,1
	st		Y+,r16
	cpi		YL,lo8(ee_end) //XXXX
	brcs	Mvnext

//-------------------------------------

	tst		r24 //if(!r24)
	brne	Msetup
	lds		r24,sel
Msetup:
	sts		sel,r24 // save selection

//-------------------------------------
 //flash led for each reset

	mov 	r30,r24
	andi	r30,0x0F

	sbrc	r24,5 // 0x20 no flashing
	rjmp	Sr
Sl:
	sbi		LEDPORT,LEDBIT // led off
	tst		r30
	breq	Sr
	dec		r30

	rcall	Delay150
	sbi		LEDDDR,LEDBIT //led
	cbi		LEDPORT,LEDBIT // led on
	rcall	Delay150

	rjmp	Sl
Sr:
//-------------------------------------

	sbrs	r24,6 // 0x40
	rcall	usb_setup

	sbrs	r24,7 // 0x80
Sjmp0:
	jmp		0	 // to APP

	rcall	SetToMod // Module loading

//=============================================================================
//STK500 framing

Mclr:
	ldi		r24,0 //xx DON'T move these
	ldi		r25,0 //xx
	clr		rflag
	sbi		LEDPORT,LEDBIT //led off
Mput:
	rcall	usb_getc
	rcall	PutByte
	tst		rflag
	breq	Mput //xx
	cbi		LEDPORT,LEDBIT //led on
	rcall	SendMsg
	rjmp	Mclr

//-----------------------------------------------

SendMsg:
//	sleep
//	if(rflag) or other flag like ??txie??

	ldi		r26,lo8(buffer) //getc_ptr = &buffer[5];
	ldi		r27,hi8(buffer)
	adiw	r26,5
	movw	r28,r26 //putc_ptr = &buffer[6];
//#ifndef INJECT
	//if(checksum)
	tst		checksum
	breq	SMchecksumOK
		ldi		r16,0xB0 //ANSWER_CKSUM_ERROR
		st		Y+,r16
		ldi		r16,0xC1 //STATUS_CKSUM_ERROR
		st		Y+,r16
		rjmp	SMgenmsg
SMchecksumOK:
//#endif
	adiw	r28,1 //go past cmd byte

/*	ld		r16,X
	cpi		r16,0x10
	brcc	SMpc
	rcall	PutMsgBL
	rjmp	SMgenmsg*/

SMpc:
	ld		r16,X
	cpi		r16,0xFF
	brne	SMnormal
	adiw	r26,1 //X+
	rcall	PutCustom
	rjmp	SMgenmsg

SMnormal:
	movw	r30,flo
	//ww mov		r31,fhi
	icall   //rcall PutMsg

SMgenmsg:
//	rcall	GenMsg
//	ret

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
	ld		r17,Z+
	eor		r16,r17
	cp		r30,r28
	cpc		r31,r29
	brne	GMnext

	st		Z,r16 //checksum
	adiw	r24,6
	ldi		r30,lo8(buffer)
	ldi		r31,hi8(buffer)
//	rcall	usb_putbuf
GMnb:
	ld		r16,Z+
	rcall	usb_putc_nf
	sbiw	r24,1
	brne	GMnb
	rcall	usb_flush

	//buffer_index = 0;
	ldi		r24,0x00
	ldi		r25,0x00

	ret
}

//END GenMsg
//-----------------------------------------------

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

//END STK500 framing
//=============================================================================

SetToMod:
	rcall	StoreBsstart
	sbiw	r30,4

	ldi		r16,lo8(PutMsgBL)
	ldi		r17,hi8(PutMsgBL)
	movw	flo,r16

//---20110912
//	ldi		r16,0x81
//	sts		sel,r16
	andi	r24,0x0F
	cpi		r24,0x0E //mode E for emergency repair
	breq	STMend
//---

	lpm		r16,Z+
	lpm		r17,Z+
	cpi		r16,BUILDML
	brne	STMend
	cpi		r17,BUILDMH
	brne	STMend
	lsr		r31
	ror		r30
	icall
STMend:
	ret

//-------------------------------------

Load_blstarta:
	lds		r16,blstarta // if(addr >= blstarta) fail
	lds		r17,blstarta+1
	ret

StoreBsstart:
	ldi		r30,lo8(BSStart*2)
	ldi		r31,hi8(BSStart*2)
Store_blstarta:
	sts		blstarta  ,r30
	sts		blstarta+1,r31
	ret

//-------------------------------------

PutCustom:
	ld		r16,X+
PCs00: // SelectMode
	cpi		r16,0
	brne	PCs01
	st		Y+,rnull
	ld		r24,X+
	ori		r24,0x50
	push	r24
	rcall	GenMsg // return STATUS_CMD_OK
	pop		r24
PCmagic:
	ldi		ZH,0xCA
	ldi		ZL,0x53
	rjmp	BLStart
PCs01: // GetMode
	cpi		r16,1
	brne	PCs02
	st		Y+,rnull
	lds		r16,sel
	st		Y+,r16
	ret
PCs02: // Get Blisp version
	cpi		r16,2
	brne	PCs03
	st		Y+,rnull
	ldi		r16,4 //version number 3
	st		Y+,r16
	ret
PCs03: // Get address of first module / size of app section
	cpi		r16,3
	brne	PCs04
	rcall	Load_blstarta
	st		Y+,r16
	st		Y+,r17
	ret
PCs04: //disable module protection
	cpi		r16,4
	brne	PCfail
	rcall	StoreBsstart
	st		Y+,rnull
	ret

PCfail:
	ldi		r16,STATUS_CMD_UNKNOWN
	st		Y+,r16
	ret

//-------------------------------------

SetPrescaler:
	ldi		r17,(1<<CLKPCE)
	sts		CLKPR,r17
	sts		CLKPR,r16
	ret

//-------------------------------------

Delay0:
	tst		r16
	brne	Delay
	ret
Delay150:
	ldi		r16,150
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

//-------------------------------------

DoSwitch:
	pop		r25
	pop		r24
	movw	r30,r24
	sub		r30,r17
	sbc		r31,rnull
	lsl		r30
	rol		r31
DSnext:
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
	rjmp	DSnext

DSok:
	add		r30,r16
	adc		r31,rnull
	lpm
	add		r24,r0
	adc		r25,rnull
DSret:
	push	r24
	push	r25
	ret

//=============================================================================
//=============================================================================
//STK500 Bootloader

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

//-------------------------------------

PSetZ:
	st		Y+,rnull //STATUS_CMD_OK
	ldi		r30,lo8(PStart)
	ldi		r31,hi8(PStart)
	andi	r16,0x0F
	add		r30,r16
//	adc		r31,rnull //XXX
	ret

//-------------------------------------

GetParameter:
	ld		r16,X+
	mov		r17,r16
	andi	r17,0xF0
	cpi		r17,0x90
	breq	GPok

	andi	r16,0xFE
	cpi		r16,0x80
	brne	PMBfail //---->
	ldi		r16,0x9C //0x80 0x81 0x9C return 0x00
GPok:
	rcall	PSetZ
	ld		r16,Z
	st		Y+,r16
	ret

//-------------------------------------

SetParameter:
	ld		r16,X+
	mov		r17,r16
	andi	r17,0xF0
	cpi		r17,0x90
	brne	PMBfail //---->
	rcall	PSetZ
	ld		r16,X+
	st		Z,r16
	ret

//=============================================================================
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
	ldi		r17,PMBij-PMBjt
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
//	ret
PMBs02: //CMD_SET_PARAMETER
	rjmp	SetParameter
//	ret
PMBs03: //CMD_GET_PARAMETER
	rjmp	GetParameter
//	ret
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
	rcall	CheckBls //p
	ldi		r16,0    //p
	brcc	PMBrfl0  //p
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
PMBs1F: //page erase extension
	rcall	SetupRWFlEep
	cpi		r25,0xA3 //check byte after command
	brne	PMBs1D //fail
	mov		r16,r24
	andi	r16,((PAGESIZE*2)+1)
	brne	PMBs1D //alignment incorrect
//----------
PMBs1Fnext:
	rcall	CheckBls
	brcc	PMBs1Fe //cannot overwrite BL or modules

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
	rcall	StoreZA
PMBok:// PMIok:
	st		Y+,rnull //STATUS_CMD_OK
	ret

SetupRWFlEep:
	ld		r25,X+
	ld		r24,X+
LoadZA:
	lds		r30,address
	lds		r31,address+1
	ret

StoreZA:
	sts		address  ,r30
	sts		address+1,r31
	ret

//END PutMsgBL
//=============================================================================
// BL Programming code

SpmWait:
	in		r16,SPMCSR
	sbrc	r16,SPMEN
	rjmp	SpmWait
SW2:
	sbic	EECR,EEPE
	rjmp	SW2
	ret

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
	sbi		EECR,EEMPE
	sbi		EECR,EEPE
WRret:
	sbic	EECR,EEPE
	rjmp	WRret
	ret

//END RWeadEEP
//-------------------------------------
// 64k limit

CheckBls:
	//protect the bootloader / isp programmer
	rcall	Load_blstarta
	cp		r30,r16
	cpc		r31,r17
	ret

ProgramFlash: // Z == address  r245 == size
	set
PFnext:
	rcall	LoadZA
	//ld	rxx,??

	mov		r16,r30
	andi	r16,(PAGESIZE-1) //eg 0x3F
	breq	PFgo //misaligned write
PFfail:
	ldi		r16,STATUS_CMD_FAILED
	st		Y+,r16
	ret

PFgo:
	lsl		r30 // 64k limit
	rol		r31 // 64k limit
//	rol		rxx // no limit
	rcall	CheckBls
	brcc	PFfail //cannot overwrite BL or modules

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
	rcall	StoreZA

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

//Bootloader
//=================================================================================================
//=================================================================================================
// USB - 850 bytes
#if 1

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

	ldi		r16,(1<<PLLE)|(1<<PLLP0) // (16MHz = 1) (8MHz = 0)
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

GotoApp:
	lds		r16,sel
	cpi		r16,0x81
	brne	GAret
GAn://10Hz led flashing
	sbi		PINC,2 //led toggle
	ldi		r16,25
	rcall	Delay
	sbis	PINC,4
	rjmp	GAn
	sbi		PORTC,2 //led off
	clr		r24
	rjmp	Sjmp0 //jmp 0 old code 20111125
GAret:
//	ldi		r24,0xD0 -- 20120211 REMOVED again - breaks HVPP in stk500 mode :( :(
//	rjmp	PCmagic //Make Select go back to bootloader from stk500 mode
	ret//	---> old code 20111125
	nop

usb_getc:
	rcall	usb_task
	sbis	PINC,4
	rcall	GotoApp
	rcall	usb_peek
	breq	usb_getc
	lds		r16,UEDATX
	push	r16
	rcall	usb_ack_out
	pop		r16
	ret

usb_peek:
	lds		r16,conf_nr	//Is_device_enumerated()
	tst		r16
	breq	UPret

	ldi		r16,RX_EP
	sts		UENUM,r16

usb_ack_out:
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

#else
usb_setup:
usb_getc:
usb_putc_nf:
usb_flush:
usb_peek:
usb_reset:
usb_task:
usb_process_request:
#endif
//-------------------------------------

	
.org FLASHEND-12
	out 	SPMCSR,r24
	spm
	ret
.org FLASHEND-9
	rjmp	SetPrescaler //-9
	rjmp	DelayU     //-8 (somewhat deprecated.... rather use THIRDBOOTSTART-15)
	rjmp	Delay0     //-7
	rjmp	DoSwitch   //-6
	rjmp	usb_peek   //-5
	rjmp	usb_getc   //-4
	rjmp	usb_putc_nf//-3
	rjmp	usb_process_request // r2=0 r16
	rjmp	usb_reset  //-1 r2=0 r16
	rjmp	usb_task   //-0 see above

//END USB
//=================================================================================================
//=================================================================================================




