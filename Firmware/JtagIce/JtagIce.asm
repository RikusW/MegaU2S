/* vim:ts=4 sts=0 sw=4
//Copyright 2010-2013 Rikus Wessels
//This is free for personal or non-profit use, for commercial use contact me.
//rikusw - gmail - com

//20110621 previous stable version
//20111126 added support for new avr's scanchain 6/7 programming + fixed CE polling
//20130924 Edited SaveContext, moving SREG to after register saving, to prevent its corruption...

//=============================================================================
This is a JTAGICE mki clone and supports only the following on AVRStudio 4.18
ATmega16(L),ATmega162(L),ATmega169(L or V),ATmega32(L),ATmega323(L),ATmega64(L),ATmega128(L)
Should support newer avr's too since 20111126
2014 - AS4 can be hacked to allow newer AVRs, the signature and ucRead/Write masks needs to be updated in the DLL.


TODO

--Target detection-- see CSR 7 - implement R_POWER
===>>Connect the target BEFORE connecting USB/power<<===

Required for sw breakpoints, not supported by AVRStudio 4.18 for the mki
----------
DoSPM --- not sure if this will work

CsA1: // Erase Page spm  --- untested, may or may not work

WMsA0: // Write Page spm --- untested, may or may not work

Ireg - PirL PirH PirF --- mki implementation seems buggy and unused...
----------

SPsB6 SPsB7 SPsB8 are these ever used ? (reset bp?) thats what B4 and B5 is for ?

Read/Write memory 0x30/Shadow, this is used for URSEL registers in old AVR's.

CLsC2: //? Osccal --untested--


OCD registers, bits with unknown or unclear function.

BCR 14 - BCR_PC24 - seems to give 2 clocks for 1 test/idle clock, increments PC by 4.
BCR 2 - RW - unknown function
BCR 1 - RO - unknown function
BCR 0 - RO - unknown function

BSR 8 to 15 - unknown function

CSR 14 - RW - CSR_SHADOW set to 1 while reading/writing memory type 0x30 (URSEL ??)
CSR 7 - unknown function - CSR_POWER virtual bit, set by the mki when jtag pin ?2/10? is grounded
        R_POWER - should have been R_CONNECTED
CSR 5 to 13 - RO - unknown function
CSR 3 - RO - Sometimes 1 after a break
CSR 1 - RO - unknown function (break ?)

----------------------------------------------------

fix R_INFO, R_SLEEP and R_BREAK....   ?done?

CLs78: reset is buggy ? (address 0 == -1)
		must singlestep twice to get going...
		---fixed with a 20ms delay---

//=============================================================================

//#define M256 ATmega256x support --incomplete--

//--The 5 switches--
//CommandLoop
//SetParameter
//GetParameter
//ReadMem
//WriteMem

//SaveContext
//RestoreContext

//=============================================================================*/

//There is two hooks for serial interfacing
//SETUPSERIAL(); SETUPBAUD();

//used for debugging to prevent AVRStudio disabling OCDEN
#define ENABLE_WMsB2 //write fuses

//=============================================================================

//A note about register usage by functions:
//Valid combinations: p pr pc r c
//p Parameter
//r Return value
//c Changed by function
//eg:
//pr r16 pc r17 r18 p r19 c r10 r11
//Parameters: r16 r17 r18 r19
//Return values: r16
//Changed: r17 r18 r10 r11

.def rnull = r2 // THIS MUST ALWAYS BE 0

#define lo8(x) (x & 0xFF)
#define hi8(x) ((x >> 8) & 0xFF)

#define mlo8(x) ((-x) & 0xFF)
#define mhi8(x) (((-x) >> 8) & 0xFF)


//=============================================================================
//BCR 8

#define BCR_RUNTIMER	7 //bit 15
#define BCR_PC24		6 //??
#define BCR_EN_STEP		5
#define BCR_EN_FLOW		4
#define BCR_EN_PSB0		3
#define BCR_EN_PSB1		2
#define BCR_EN_BMASK	1
#define BCR_EN_PDMSB	0 //bit 8

#define BCR_EN_PDSB		7
#define BCR_PDMSB1		6
#define BCR_PDMSB0		5
#define BCR_PDSB1		4
#define BCR_PDSB0		3
#define BCR_xxx2		2 //?? RW
#define BCR_xxx1		1 //?? =0
#define BCR_xxx0		0 //?? =0

//-------------------------------------
//BSR 9

#define BSR_STEP	7
#define BSR_FLOW	6 //jmp call ret brxx
#define BSR_PSB0	5
#define BSR_PSB1	4
#define BSR_PDSB	3
#define BSR_PDMSB	2
#define BSR_FORCE	1 //IR=8
#define BSR_SOFT	0

//-------------------------------------
//CSR D

//RW
#define CSR_EN_OCDR 7 //bit 15
#define CSR_SHADOW  6 //bit 14

//RO
//#define CSR_POWER 7 --- high when pind3 is pulled low, connected to jtag pin 2 or 10 
#define CSR_OCDR  4 //OCDR dirty
#define CSR_SLEEP 0

//bits 1&2
#define CSR_BMASK 0x06 //3
#define CSR_Bxxx3 0x06 //3 ??
#define CSR_BREAK 0x04 //2 break
#define CSR_Bxxx1 0x02 //1 ??
#define CSR_BRUN  0x00 //0 running

//=4 on break
//=C sometimes seen on soft break

//=============================================================================
//JTAG Programming
//Commands

#define JTPC_CE  0x80 //Chip Erase

#define JTPC_WFB 0x40 //Write Fuse
#define JTPC_WLB 0x20 //Write Lock
#define JTPC_WF  0x10 //Write Flash
#define JTPC_WE  0x11 //Write EEPROM

#define JTPC_RSC 0x08 //Read Sig&Cal
#define JTPC_RFL 0x04 //Read Fuse&Lock
#define JTPC_RF  0x02 //Read Flash
#define JTPC_RE  0x03 //Read EEPROM

//-------------------
//Instructions - same as HVPP

#define JTPI_LLB 0x13 //Load Low Byte
#define JTPI_LHB 0x17 //Load High Byte
#define JTPI_LLA 0x03 //Load Low  Address
#define JTPI_LHA 0x07 //Load High Address
#define JTPI_LEA 0x0B //Load Extended Address

#define JTPI_CMD 0x23 //Load Command see JTPC_xxx
#define JTPI_NOP 0x33 //Load NOP

#define JTPI_RLB 0x32 //Read Low Byte
#define JTPI_RHB 0x36 //Read High Byte
#define JTPI_WLB 0x31 //Write Low Byte
#define JTPI_WHB 0x35 //Write High Byte

//JTAG Programming
//=============================================================================
//RAM

.dseg
Pstart: //see InitDT
Pbaud:	.byte 1 //RW
Pjclk:	.byte 1 //RW jtag clk (F3: 50kHz, FA: 100kHz, FD: 200kHz)
JTclk:	.byte 1 //used by JTPulseTCK
PmcuM:	.byte 1 //R  mcu mode 0=stopped  1=running  2=programming
Ppml:	.byte 2 //PML function address
ucEECR:	.byte 1

//CCount:	.byte 1

PirF:	.byte 1 //Ireg changed flag
PirL:	.byte 1 //RW instruction register
PirH:	.byte 1 //RW
Pjid0:	.byte 1 //R  jtag id
Pjid1:	.byte 1 //R
Pjid2:	.byte 1 //R
Pjid3:	.byte 1 //R

PflpL:	.byte 1 //flash page size Low
PflpH:	.byte 1 //flash page size High
Peepp:	.byte 1 //eeprom page size

Psb0L:	.byte 1
Psb0H:	.byte 1
Psb1L:	.byte 1
Psb1H:	.byte 1

Pbr1L:	.byte 1
Pbr1H:	.byte 1
Pbr2L:	.byte 1
Pbr2H:	.byte 1

#ifdef DAISY
Pub:	.byte 1
Pua:	.byte 1
Pbb:	.byte 1
Pba:	.byte 1
#endif

//DO NOT change the order
SPRstBrk:
SPb5:	.byte 1
SPb4:	.byte 1
SPb8:	.byte 1
SPb7:	.byte 1
SPb6:	.byte 1
//DO NOT change the order

//----------------------------------------
JTDesc: //JTAG Device Descriptor 123 bytes
ucRead:				.byte 8
ucReadShadow:		.byte 8
ucWrite:			.byte 8
ucWriteShadow:		.byte 8  //32
ucExtRead:			.byte 20
ucExtReadShadow:	.byte 20
ucExtWrite:			.byte 20
ucExtWriteShadow:	.byte 20 //160

ucOCDRaddress:		.byte 1 //IO
ucSPMCAddress:		.byte 1 //MMap
ucRAMPZAddress:		.byte 1 //IO
uwFlashPageSize:	.byte 2
ucEepromPageSize:	.byte 1
ulBootAddress:		.byte 4
ucUpperExtIOLoc:	.byte 1 //11
//----------------------------------------

//Context

//CSR:		.byte 1
CSR_OLD:	.byte 1

//Context
JTCstate:	.byte 1 // 0x01=PC 0x03=PC+Prog
JTPC:		.byte 3 //little endian
JT_YZ:		.byte 7
JT_SREG:	.byte 1
JTSPMC:		.byte 1 //Prog
JTEEDR:		.byte 1
JTEEAL:		.byte 1
JTEEAH:		.byte 1

JTbuf:		.byte 10

JTIR:		.byte 1 //DEBUG

/* Don't do a full context save, at least not now.
bRegisters:	.byte 0x20
bRead:		.byte 0x40
bExtRead:	.byte 0x40
bWrite:		.byte 0x40
bExtWrite:	.byte 0x40*/


//RAM
//=============================================================================
//init

.cseg
JTApp:
	clr		rnull
	out		SREG,rnull
	ldi		r16,LOW (RAMEND) //stack setup
	out		SPL,r16
	ldi		r17,HIGH(RAMEND)
	out		SPH,r17

	ldi		r28,lo8(Pstart)
	ldi		r29,hi8(Pstart)
	ldi		r30,lo8(InitDT*2)
	ldi		r31,hi8(InitDT*2)
	ldi		r18,7
InitNext:
	lpm		r19,Z+
	st		Y+,r19
	dec		r18
	brne	InitNext
Mnext:
	cp		r28,r16 //passed from stack setup
	cpc		r29,r17
	st		Y+,rnull //clear the ram
	brcs	Mnext

/*	ldi		r16,0xFA //19200bps
	sts		Pbaud,r16
	ldi		r16,0xFE //500kHz
	sts		Pjclk,r16
	ldi		r16,1    //500kHz
	sts		JTclk,r16
	ldi		r16,1    //running
	sts		PmcuM,r16
	ldi		r16,lo8(RMpml1)
	sts		Ppml+0,r16
	ldi		r16,hi8(RMpml1)
	sts		Ppml+1,r16
	ldi		r16,0x1C //IO --0x1F for m169 and can128
	sts		ucEECR,r16*/

	SETUPSERIAL();
								
	ldi		r16,(1<<JTDI)|(1<<JTMS)|(1<<JTCK)|(1<<JRST)
	out		JDDR,r16
	ldi		r16,(1<<JTDO)|(1<<JRST) //tdo pullup, reset off by default
	out		JPORT,r16

	rcall	JTDoReset //reset the TAP
//	rcall	StoreCSRLow //r r16 r17 c r18 r19 r20 r21 r22 c r10 r12 r13 r14 r15
	rjmp	CommandLoop

InitDT:
.db	0xFA, 0xFE, 1, 1, lo8(RMpml1), hi8(RMpml1), 0x1C, 0

//init
//=============================================================================
//OCD polling

#define R_OK	0x41 //A
#define R_BREAK 0x42 //B [Resp_Break] [break status register H] [break status register L]
#define R_SE	0x45 //E Sync Error getchar() != Sync_EOP
#define R_FAIL	0x46 //F
#define R_INFO	0x47 //G [Resp_INFO] [OCDR] [Resp_OK]
#define R_SLEEP 0x48 //H
#define R_POWER 0x49 //I

OCDPoll:
#ifdef U2S
	sbic	PINC,4 //select pressed ?
	rjmp	OPp
OPbl: // go to mode 0x80
	out		JDDR,rnull
	out		JPORT,rnull

	ldi		r24,0x80 //bootloader - sel will cause an inc so 0x81...
	ori		r24,0x50
	ldi		ZH,0xCA
	ldi		ZL,0x53
	jmp		THIRDBOOTSTART //jump to bootloader
#endif

//---------------------------

OPp:
	rcall	IfMcuRunning
	breq	OPcont
	ret
OPcont:
//	rcall	StoreCSRLow //r r16 r17 c r18 r19 r20 r21 r22 c r10 r12 r13 r14 r15
	rcall	JTReadCSR
	mov		r24,r16
	andi	r24,0x7F
	lds		r25,CSR_OLD
	eor		r25,r24
	sts		CSR_OLD,r24

//---------------------------
P_INFO: // OCDR dirty

	sbrs	r25,CSR_OCDR
	rjmp	P_SLEEP
	andi	r16,~(1<<CSR_OCDR)
	rcall	JTWriteCSR

	ldi		r16,R_INFO
	rcall	putc_nf
	rcall	JTReadOCDR //r r16 c r17 r18 r19 r20 r21 r22 c r10 r12 r13 r14 r15
	rcall	putc_nf
	rcall	putcR_OK

//---------------------------
P_SLEEP:

	sbrs	r25,CSR_SLEEP
	rjmp	P_BREAK

	ldi		r16,R_SLEEP
	rcall	putc_nf
	ldi		r16,0
	sbrs	r24,CSR_SLEEP
	ldi		r16,1
	rcall	putc_nf
	rcall	putcR_OK

//---------------------------
P_BREAK:

	andi	r24,CSR_BMASK
	cpi		r24,CSR_BREAK
	brne	OPret
	rcall	StopMcu
	ldi		r16,R_BREAK
	rcall	putc_nf
	rcall	JTReadBSR //r r16 r17 c r18 r19 r20 r21 r22 c r10 r12 r13 r14 r15
	rcall	RMputword
	rcall	flush

//---------------------------

OPret:
	ret

//---------------------------
/*
	//code to reset the TAP with the SELECT button
	sbic	PINC,4 //select pressed ?
	ret

	cbi		PORTC,2 // led on
	ldi		r16,150 //ms
	rcall	Delay

	rcall	JTDoReset //goto SelectDR
	rcall	CheckAtmelID
	breq	OPwait
	
	sbi		PORTC,2 //led off
OPwait:
	sbis	PINC,4
	rjmp	OPwait
	sbi		PORTC,2 //led off
*/

//---------------------------
/*//P_POWER: //Connected

//	sbrs	r25,CSR_POWER
//	rjmp	P_SLEEP

	lds		r16,CCount
	inc		r16
	sts		CCount,r16
	brne	OPs

	rcall	CheckAtmelID

	ldi		r16,R_POWER
	rcall	putc_nf
	clr		r16
	sbrs	r24,CSR_POWER
	ldi		r16,1
	rcall	putc_nf
	rcall	putcR_OK
OPs:*/
//---------------------------
/*P_POWER:

	sbrs	r25,CSR_POWER
	rjmp	P_INFO

	ldi		r16,R_POWER
	rcall	putc_nf
	clr		r16
	sbrs	r24,CSR_POWER
	ldi		r16,1
	rcall	putc_nf
	rcall	putcR_OK*/
//---------------------------


//OCD polling
//=============================================================================
//Command Switch

Cjt:
.db CLs20-Cij , 0x20
.db CLs31-CLs20, 0x31
.db CLs32-CLs31, 0x32
.db CLs33-CLs32, 0x33
.db CLs42-CLs33, 0x42
.db CLs46-CLs42, 0x46
.db CLs47-CLs46, 0x47
.db CLs4D-CLs47, 0x4D
.db CLs52-CLs4D, 0x52
.db CLs53-CLs52, 0x53
.db CLs57-CLs53, 0x57
.db CLs62-CLs57, 0x62
.db CLs63-CLs62, 0x63
.db CLs64-CLs63, 0x64
.db CLs71-CLs64, 0x71
.db CLs78-CLs71, 0x78
.db CLsA0-CLs78, 0xA0
.db CLsA1-CLsA0, 0xA1
.db CLsA2-CLsA1, 0xA2
.db CLsA3-CLsA2, 0xA3
.db CLsA4-CLsA3, 0xA4
.db CLsA5-CLsA4, 0xA5
.db CLsC0-CLsA5, 0xC0
.db CLsC1-CLsC0, 0xC1
.db CLsC2-CLsC1, 0xC2
.db CLsD0-CLsC2, 0xD0
.db CLsD1-CLsD0, 0xD1
.db 0,0

//-------------------------------------

CommandLoop:
Cnext:
	rcall	OCDPoll
	rcall	peek
	breq	Cnext
	rcall	getc
	ldi		r17,Cij-Cjt
	rcall	DoSwitch //p r16 c 17 22 23 24 25 30 31
Cij:
CLse:
	ldi		r16,R_SE
	rjmp	CputcN

//-------------------------------------

CokN:
CLs20: // Get Synch             [Resp_OK]
	ldi		r16,R_OK
CputcN:
	rcall	putc
	rjmp	Cnext

//-------------------------------------

CLs31: // Single Step           [Sync_CRC/EOP] [Resp_OK]
	rcall	GetEOP
	rcall	JTReadCSR //r r16 r17 c r18 r19 r20 r21 r22 c r10 r12 r13 r14 r15
	//sbrs	r16,CSR_POWER
	//rjmp	CokN
	andi	r16,CSR_BMASK
	cpi		r16,CSR_BREAK
	breq	CLs31fb
	rcall	StopMcu
	rjmp	CokN
CLs31fb:

	//-----------------------
	rcall	JTSetBCR_24 // just make sure...
	rcall	RestoreContext
	rcall	JTSetBCR_SS
	rcall	DoSSWait
	rcall	JTSetBCR_24
	//rcall	JTGetPC
	rcall	SaveContext
	//-----------------------
	rjmp	CokN

//-------------------------------------

CLs32: // Read PC               [Sync_CRC/EOP] [Resp_OK] [program counter] [Resp_OK]
	rcall	GetEOP
	rcall	IfMcuRunning
	brne	CLs32putPC
	ldi		r16,PDPC-PDLZ
	ldi		r17,4
	rcall	putdata
	rjmp	Cnext
CLs32putPC:
	ldi		r30,lo8(JTPC+3)
	ldi		r31,hi8(JTPC+3)
	rcall	putcZm //MSB
	rcall	putcZm
	rcall	putcZm //LSB
	rjmp	CokN

//-------------------------------------	

CLs33: // Write PC              [program counter] [Sync_CRC/EOP] [Resp_OK] [Resp_OK]
	rcall	getcPUSH3 //msb r5 r6 r7 lsb
	rcall	GetEOP
	sts		JTPC+2,r5 //MSB
	sts		JTPC+1,r6
	sts		JTPC+0,r7 //LSB
	rjmp	CokN

//-------------------------------------

CLs42: // Set Parameter         [parameter] [setting] [Sync_CRC/EOP] [Resp_OK] [Resp_OK]
	rcall	getc
	mov		r17,r16
	rcall	getc
	mov		r18,r16
	rcall	GetEOP
	rcall	SetParameter
	rjmp	Cnext

//-------------------------------------

CLs46: // Forced Stop           [Sync_CRC/EOP] [Resp_OK] [checksum][program counter] [Resp_OK]
	rcall	GetEOP
	//rcall	StoreCSRLow
	//sbrc	r16,CSR_POWER
	rcall	StopMcu
	rjmp	CLs32putPC

//-------------------------------------

CLs47: // Go                    [Sync_CRC/EOP] [Resp_OK]
	rcall	GetEOP
	rcall	SetMcuRunning

	/*rcall	StoreCSRLow
	sbrs	r16,CSR_POWER
	rjmp	Cnext*/
	rcall	JTReadCSR //r r16 r17 c r18 r19 r20 r21 r22 c r10 r12 r13 r14 r15
	andi	r16,CSR_BMASK
	cpi		r16,CSR_BREAK
	brne	CLs47r
	rcall	JTSetBCR_24 // just make sure...
	rcall	RestoreContext
	ldi		r21,9 //GO
	rcall	JTShiftIR //pc r21 c r10 r12 r13 r14 r15 r20 r22
CLs47r:	
	rjmp	Cnext

//-------------------------------------

CLs4D: // Setmode -- --U2S custom command--
#ifdef U2S
	rjmp	OPbl
#else
	rjmp	Cnext //ignore this
#endif

//-------------------------------------

CLs52: // Read Memory           [memory type] [word count] [start address] [Sync_CRC/EOP]
                            // [Resp_OK] [word 0] ... [word n] [checksum] [Resp_OK]
	rcall	getcPUSH5 //type r5 -- count r6 -- msb r7 r8 r9 lsb --
	inc		r6
	rcall	GetEOP
	rcall	ReadMem
	rjmp	Cnext

//-------------------------------------

CLs53: // Get Sign On           [Sync_CRC/EOP] [Resp_OK] [AVRNOCD] [Resp_OK]
	rcall	GetEOP
	ldi		r17,8
	ldi		r16,PDSO-PDLZ
	rcall	putdata
	rjmp	Cnext

//-------------------------------------

CLs57: // Write Memory          [memory type] [word count] [start address] [Sync_CRC/EOP]
                            // [Resp_OK] [Cmd_DATA] [word 0] ... [word n]
	rcall	getcPUSH5 //type r5 -- count r6 -- msb r7 r8 r9 lsb --
	inc		r6
	rcall	GetEOP
	rcall	WriteMem

CLs62: //? Ignored
CLs63: //? Ignored
	rjmp	Cnext

//-------------------------------------

CLs64: // Get Debug Info        [Sync_CRC/EOP] [Resp_OK] [0x00] [Resp_OK]
	rcall	GetEOP
	ldi		r16,0
	rcall	putc_nf
	rjmp	CokN

//-------------------------------------

CLs71: // Get Parameter         [parameter] [Sync_CRC/EOP] [Resp_OK] [setting] [Resp_OK]
	rcall	getc
	mov		r17,r16
	rcall	GetEOP
	rcall	GetParameter
	rjmp	Cnext

//-------------------------------------

CLs78: // Reset		   [Sync_CRC/EOP] [Resp_OK] [Resp_OK]
	rcall	GetEOP
	rcall	SetMcuRunning
	rcall	JTDoReset //goto SelectDR

	ldi		r21,8 //force break
	rcall	JTShiftIR //pc r21 c r10 r12 r13 r14 r15 r20 r22

	//PSB0 on
	ldi		r30,lo8(SPRstBrk)
	ldi		r31,hi8(SPRstBrk)
	ldi		r18,0
	rcall	JTWritePSBsp
	//ldi		r18,1 //??
	//rcall	JTWritePSBsp //??

	rcall	JTResetOn
	ldi		r16,1
	rcall	Delay
	rcall	JTResetOff

	rcall	WaitForBreak //XXX This doesn't seem to work on its own...
	ldi		r16,20 //ms -- Patched with this delay...
	rcall	Delay

	ldi		r16,0
	sts		JTCstate,rnull
	rcall	StopMcu
	//rcall	StoreCSRLow //r r16 r17 c r18 r19 r20 r21 r22 c r10 r12 r13 r14 r15
	rjmp	CokN

//-------------------------------------

CLsA0: // Set Device Descriptor [device info] [Sync_CRC/EOP] [Resp_OK] [Resp_OK]
	ldi		r30,lo8(JTDesc)
	ldi		r31,hi8(JTDesc)
	ldi		r17,123
CLsA0n:
	rcall	getc
	st		Z+,r16
	dec		r17
	brne	CLsA0n
	rcall	GetEOP
	rjmp	CokN

//-------------------------------------

CLsA1: // Erase Page spm        [address] [Sync_CRC/EOP] [Resp_OK] [Resp_OK]
	rcall	getc
	ldi		r26,0 //mov r26,r16 for mega256x ?
	rcall	getc
	mov		r25,r16
	rcall	getc
	mov		r24,r16
	rcall	GetEOP

	ldi		r16,R_FAIL //unsupported
	rjmp	CputcN

	/*	rcall	JTShiftIR_A //xx
	lsl		r24 //convert word to byte address
	rol		r25
	rol		r26
	mov		r16,r26
	rcall	DoST_RAMPZ //mega128

	rcall	DoIJMPtoBoot //to enable spm
	rcall	DoLDI_Z //r24r25
	ldi		r16,(1<<PGERS)|(1<<SPMEN)
	rcall	DoSPM
	ldi		r16,(1<<RWWSRE)|(1<<SPMEN)
	rcall	DoSPM
	rjmp	CokN*/

//-------------------------------------

CLsA2: // Firmware Upgrade      [upgrade string] [Sync_CRC/EOP] [Resp_OK] [Resp_OK]
#if 1

	ldi		r24,8
CLsA2n:
	rcall	getc
	dec		r24
	brne	CLsA2n
	rcall	GetEOP
	rcall	putcR_FAIL
	rjmp	Cnext

#else // necessary for JtagICE mkI

	clt
	ldi		r17,8
	ldi		r16,CLsA2s-CLsA2n
	rcall	LoadZR
//{
CLsA2n:
	rcall	getc
	lpm		r18,Z+

	cp		r16,r18
	breq	CLsA2eq
	rcall	putcR_FAIL
	set
CLsA2eq:	

	dec		r17
	brne	CLsA2n
//}	
	rcall	GetEOP
	brts	CLsA3n ???
	rcall	putcR_OK
	;Delay 6ms   ??for tx completion??
	cli
	jmp		0x3C00 //2kb bootloader on ATmega16
CLsA2s:
	.db	'J','T','A','G','u','p','g','r'

#endif

//-------------------------------------

CLsA3: // Enter Progmode        [Sync_CRC/EOP] [Resp_OK] [Resp_OK]
	rcall	GetEOP
	rcall	CheckAtmelID
	breq	JEok
	rcall	putcR_FAIL
	rjmp	JEfailed
JEok:
	rcall	putcR_OK
JEfailed:
	rcall	JTResetOn
	ldi		r16,6
	rcall	Delay
	rcall	JTProgEnable
	rcall	JTShiftIR_5 //c r10 r12 r13 r14 r15 r20 r21 r22
	rcall	SetMcuProgramming
	rjmp	Cnext

CheckAtmelID:
	rcall	JTGetID
	sbiw	r30,4  //xx
	ld		r16,Z+ //xx
	ld		r17,Z+ //xx
	andi	r16,0xFE
	andi	r17,0x0F
	subi	r16,0x3E // check for atmel id
	sbci	r17,0
	ret

//-------------------------------------

CLsA4: // Leave Progmode        [Sync_CRC/EOP] [Resp_OK] [Resp_OK]
	rcall	GetEOP
	ldi		r17,JTPI_CMD
	rcall	JTProgInst
	ldi		r17,JTPI_NOP
	rcall	JTProgInst
	rcall	JTProgDisable
	rcall	JTResetOff
	rcall	StopMcu
//	rcall	StoreCSRLow //r r16 r17 c r18 r19 r20 r21 r22 c r10 r12 r13 r14 r15
//	rcall	SetMcuRunning    //rcall	SetMcuStopped //??
	rjmp	CokN

//-------------------------------------

CLsA5: // Chip Erase            [Sync_CRC/EOP] [Resp_OK] [Resp_OK]
	rcall	GetEOP
	rcall	JTShiftIR_5 //c r10 r12 r13 r14 r15 r20 r21 r22
	ldi		r16,JTPC_CE
	rcall	JTProgCommand
	ldi		r17,JTPI_WLB
	ldi		r16,JTPC_CE
	rcall	JTProgIR5
	ldi		r17,JTPI_NOP
	ldi		r16,JTPC_CE
	rcall	JTProgIR5
CLsA5n:
	ldi		r17,JTPI_NOP
	ldi		r16,JTPC_CE
	rcall	JTProgIR5
	andi	r17,2
	breq	CLsA5n
	rjmp	CokN

//-------------------------------------

//[IR] [Idle] [Sync_CRC/EOP] [Resp_OK] [Resp_OK]
CLsC0: //? ShiftIR
	rcall	getc
	mov		r11,r16
	rcall	getc
	mov		r22,r16
	rcall	GetEOP
	mov		r21,r11
	rcall	JTShiftIR //pc r21 c r10 r12 r13 r14 r15 r20 r22
	rjmp	CokN

//-------------------------------------

//[RW] [Bits] [RW] [Idle] [W-Data] [Sync_CRC/EOP] [Resp_OK] [R-Data] [Resp_OK]
//---[RW] 0=W 1=R   [Data] msb to lsb ?aligned on lsbit?---
//giving [RW] twice is somewhat braindead.... it MUST be the same, so why twice ???
CLsC1: //? ShiftDR
	rcall	getc //R=1 W=0
	mov		r11,r16

	rcall	getc //bits
	mov		r20,r16

	ldi		r21,0 //R
	rcall	getc //R=1 W=0
	tst		r16
	brne	CLsC1rd
	ldi		r21,1 //W
CLsC1rd:

	rcall	getc //idle
	mov		r22,r16

	cpi		r20,49 //6*8
	brcs	ccok
	rjmp	CLse //ERROR
ccok:
	ldi		r30,lo8(JTbuf)
	ldi		r31,hi8(JTbuf)

	rcall	JTGotoShiftDR //c r10
//if(Write)
	tst		r11
	brne	CLsC1read
//{
	push		r20
CLsC1ng:
	rcall	getc
	st		Z+,r16
	subi	r20,8
	brcs	CLsC1www
	brne	CLsC1ng
	rcall	getc //stupid mki bug...
CLsC1www:
	pop		r20
	rcall	GetEOP
CLsC1wn:
	ld		r15,-Z
	rcall	JTDoShift
	tst		r20
	brne	CLsC1wn
	rjmp	CLsC1r
//}else{ //Read

CLsC1read:
	rcall	GetEOP
	push	r20
CLsC1rn:
	rcall	JTDoShift
	st		Z+,r14
	tst		r20
	brne	CLsC1rn

	pop		r20 //stupid byte reversal required by the protocol :(
CLsC1np:
	ld		r16,-Z
	rcall	putc_nf
	subi	r20,8
	brcs	CLsC1r
	brne	CLsC1np
	ldi		r16,0xAA //stupid mki bug...
	rcall	putc_nf
//}
CLsC1r:
	rcall	JTGotoSelectDR //pc r22 c r10
	rjmp	CokN

//-------------------------------------

CLsC2: //? Osccal --untested--
	rcall	GetEOP
	//cli
	ldi		r24,0xFF
	ldi		r25,0xFF
	in		r18,JPORT
	andi	r18,(1<<JTDO)
	ldi		r20,8
//====TIMING CRITICAL LOOP===	
CLsC2n:
	sbi		JPIN,JTDI //toggle TDI
	in		r19,JPORT
	andi	r19,(1<<JTDO)
	cp		r18,r19
	breq	CLsC2s2
	dec		r20
	brne	CLsC2s
	//sei
	rjmp	CokN //TDO toggled 8 times
CLsC2s2:
	rjmp	PC+1
CLsC2s:
	ldi		r16,36 //delay  36*3=108 +14=122 @ 8MHz = 32.786kHz
CLsC2nn:
	dec		r16
	brne	CLsC2nn

	mov		r18,r19
	sbiw	r24,1
	brne	CLsC2n
//====TIMING CRITICAL LOOP===	
	//sei
	rcall	putcR_FAIL //TDO didn't toggle even after 0xFFFF iterations...
	rjmp	Cnext

//-------------------------------------

//extended instruction used in the U2S mki clone
CLsD0: //TMS operation
//[Bits] [Sync_CRC/EOP] [Resp_OK] --> [W-Data] [Resp_OK]
	rcall	getc
	mov		r20,r16
	rcall	GetEOP
CLsD0n:
	rcall	getc
	ldi		r17,0xFF
CLsD0nb:
	sbrs	r16,0
	cbi		JPORT,JTMS
	sbrc	r16,0
	sbi		JPORT,JTMS
	rcall	JTPulseTCK //c r10
	dec		r20
	breq	CLsD0r
	lsr		r16
	lsr		r17
	brne	CLsD0nb
	rjmp	CLsD0n
CLsD0r:
	rjmp	CokN

//-------------------------------------
//Compared to C1's 65 lines these 30 lines show just how much
//the right protocol design can decrease firmware code size and complexity

//extended instruction used in the U2S mki clone
//[Bits] [RW] [Idle] [Sync_CRC/EOP] [Resp_OK] --> [W-Data] -- [R-Data] [Resp_OK]
//Send [W-Data] only when writing
//When writing data the [R-Data] is sent back as well.
//[Bits] 0=256 bits
//[RW] 1=R/W  2=DR/IR  (0/1)  2=Don't Enter Shift  3=Don't Exit Shift  4=Don't GotoSelectDR
//[RW] can be used with 2+3+4 to shift more than 256 bits. When using 3 always set 4.   
//[Idle] the number of cycles inside Test/Idle, including the entry cycle
//[Idle] an enter and immediate exit generates 1 avr clock

CLsD1: //Shift-R
	rcall	getc //bits
	mov		r20,r16
	rcall	getc //[RW]
	mov		r21,r16
	rcall	getc //idle
	mov		r22,r16
	rcall	GetEOP

	sbrc	r21,2
	rjmp	CLsD1n

	sbrs	r21,1
	rcall	JTGotoShiftDR //c r10
	sbrc	r21,1	
	rcall	JTGotoShiftIR //c r10
	andi	r21,1

CLsD1n:
	sbrc	r21,0
	rcall	getc
	mov		r15,r16
	rcall	JTDoShift
	mov		r16,r14
	rcall	putc_nf
	tst		r20
	brne	CLsD1n

	sbrs	r21,4
	rcall	JTGotoSelectDR //pc r22 c r10
	rjmp	CokN

//-------------------------------------
//-------------------------------------

//--WARNING--
//This may ONLY be called from this switch and NOT any function called from it.
//It pops the return address and jumps directly to CLse on failure.
GetEOP:
	rcall	getc
	rcall	getc
	cpi		r16,0x20
	breq	GEr
	pop		r16 //pop the return address
	pop		r16
	rjmp	CLse //this is sort of like throwing an exception
GEr:
	rjmp	putcR_OK

//Command Switch
//=============================================================================

DoSwitch: //p r16 c 17 22 23 24 25 30 31
	pop		r25
	pop		r24
	mov		r22,r24
	mov		r23,r25
	movw	r30,r24
	sub		r30,r17
	sbc		r31,rnull
	lsl		r30
	rol		r31
DSnext:
	lpm		r17,Z+ //accumulating code offset
	add		r22,r17
	adc		r23,rnull
	lpm		r17,Z+ //value
	tst		r17
	breq	DSret
	cp		r16,r17
	brcs	DSret
	brne	DSnext
	//found
	push	r22
	push	r23
	ret
DSret:
	push	r24
	push	r25	
	ret


LoadZR:
	pop		r31
	pop		r30
	push	r30
	push	r31
	add		r30,r16
	adc		r31,rnull
	lsl		r30
	rol		r31
	ret


getcPUSH3:
	ldi		r17,3
	rjmp	gP5
getcPUSH5:
	ldi		r17,5
gP5:
	ldi		r28,5 //r5
	ldi		r29,0
getcPn:
	rcall	getc
	st		Y+,r16
	dec		r17
	brne	getcPn
	ret


putcR_OK:
	ldi		r16,R_OK
	rjmp	putc

putcR_FAIL:
	ldi		r16,R_FAIL
	rjmp	putc


putcZm:
	ld		r16,-Z
	rjmp	putc_nf


putdata: //r16=offset r17=count
	rcall	LoadZR
PDLZ:
	lpm		r16,Z+
	rcall	putc_nf
	dec		r17
	brne	PDLZ
	rcall	flush
	ret
PDPC:
	.db 0xAA,0x55,0xAA,R_FAIL
PDSO:
	.db	'A','V','R','N','O','C','D',R_OK


//-------------------------------------


IfMcuStopped:
	ldi		r17,0
	rjmp	IMPr
IfMcuRunning:
	ldi		r17,1
	rjmp	IMPr
IfMcuProgramming:
	ldi		r17,2
IMPr:
	lds		r18,PmcuM
	cp		r18,r17
	ret

SetMcuStopped:
	ldi		r16,0
	rjmp	SMPr
SetMcuRunning:
	ldi		r16,1
	rjmp	SMPr
SetMcuProgramming:
	ldi		r16,2
SMPr:
	sts		PmcuM,r16
	ret

//=============================================================================
//=============================================================================
//GetParameter switch

GPjt:
.db GPs62-GPij , 0x62
.db	GPs70-GPs62, 0x70
.db	GPs7A-GPs70, 0x7A
.db	GPs7B-GPs7A, 0x7B
.db	GPs81-GPs7B, 0x81
.db GPs82-GPs81, 0x82
.db GPs84-GPs82, 0x84
.db GPs86-GPs84, 0x86
.db GPs87-GPs86, 0x87
.db GPsA7-GPs87, 0xA7
.db GPsA8-GPsA7, 0xA8
.db GPsA9-GPsA8, 0xA9
.db GPsAA-GPsA9, 0xAA
.db GPsB3-GPsAA, 0xB3
.db 0,0

GetParameter: //p r17
	mov		r16,r17
	ldi		r17,GPij-GPjt
	rcall	DoSwitch //p r16 c 17 22 23 24 25 30 31
GPij:
	rcall	putcR_FAIL
	rjmp	putcR_FAIL

GPs62: // RW Baudrate  UBRR == -BR * 4 - 1
	ldi		r16,Pbaud-Pstart
	rjmp	GPget

GPs70: //CRW EECR
	ldi		r16,ucEECR-Pstart
	rjmp	GPget

GPs7A: // R  Hardware Version	0xC0
	ldi		r16,0xC0
	rjmp	GPput
GPs7B: // R  SwVersion			0x80
	ldi		r16,0x80
	rjmp	GPput

GPs81: // RW Ireg High
	ldi		r16,PirH-Pstart
	rjmp	GPget
GPs82: // RW Ireg Low
	ldi		r16,PirL-Pstart
	rjmp	GPget

GPs84: // R  OCD Vtarget //50=1.2V
	ldi		r16,200 //4.9V  1=24.5mV
	rjmp	GPput
//	ldi		r16,Pvtg-Pstart
//	rjmp	GPget

GPs86: // RW OCD JTAG Clock		1/4 of part frequency
	ldi		r16,Pjclk-Pstart
	rjmp	GPget

GPs87: // R  OCD Break cause
	rcall	JTReadBSR //r r16 r17 c r18 r19 r20 r21 r22 c r10 r12 r13 r14 r15
	rjmp	GPput //BSR low

GPsA7: // R  JTAGIDByte0		Device specific  Get this one FIRST
	rcall	JTGetID
	ldi		r16,Pjid0-Pstart
	rjmp	GPget
GPsA8: // R  JTAGIDByte1		Device specific
	ldi		r16,Pjid1-Pstart
	rjmp	GPget
GPsA9: // R  JTAGIDByte2		Device specific
	ldi		r16,Pjid2-Pstart
	rjmp	GPget
GPsAA: // R  JTAGIDByte3		Device specific
	ldi		r16,Pjid3-Pstart
	rjmp	GPget

GPsB3: // R  MCU_mode
	ldi		r16,PmcuM-Pstart

//--------------------------

GPget:
	ldi		r30,lo8(Pstart)
	ldi		r31,hi8(Pstart)
	add		r30,r16
	adc		r31,rnull
	ld		r16,Z
GPput:
	rcall	putc_nf
	rjmp	putcR_OK

//GetParameter switch
//=============================================================================
//SetParameter switch

SPjt:
.db SPs62-SPij , 0x62
.db SPs70-SPs62, 0x70
.db	SPs81-SPs70, 0x81
.db SPs82-SPs81, 0x82
.db SPs86-SPs82, 0x86
.db SPs88-SPs86, 0x88
.db SPs89-SPs88, 0x89
.db SPs8A-SPs89, 0x8A
.db SPs8B-SPs8A, 0x8B
.db SPsA0-SPs8B, 0xA0
.db SPsA1-SPsA0, 0xA1
.db SPsA2-SPsA1, 0xA2
.db SPsA3-SPsA2, 0xA3
.db SPsA4-SPsA3, 0xA4
.db SPsA5-SPsA4, 0xA5
.db SPsA6-SPsA5, 0xA6
.db SPsAB-SPsA6, 0xAB
.db SPsAC-SPsAB, 0xAC
.db SPsAD-SPsAC, 0xAD
.db SPsAE-SPsAD, 0xAE
.db SPsAF-SPsAE, 0xAF
.db SPsB0-SPsAF, 0xB0
.db SPsB1-SPsB0, 0xB1
.db SPsB2-SPsB1, 0xB2
.db SPsB4-SPsB2, 0xB4
.db SPsB5-SPsB4, 0xB5
.db SPsB6-SPsB5, 0xB6
.db SPsB7-SPsB6, 0xB7
.db SPsB8-SPsB7, 0xB8
.db 0,0

//-------------------------------------

SetParameter: //p r17  v r18
	mov		r16,r17
	ldi		r17,SPij-SPjt
	rcall	DoSwitch //p r16 c 17 22 23 24 25 30 31
SPij:
	rjmp	putcR_FAIL

//-------------------------------------

SPs62: // RW Baudrate  UBRR == -BR * 4 - 1
	ldi		r16,Pbaud-Pstart
	rcall	SPput
	SETUPBAUD();
	ret

//-------------------------------------

SPs70: //CRW EECR --U2S custom parameter--
	ldi		r16,ucEECR-Pstart
	rjmp	SPput

//-------------------------------------

SPs81: // RW Ireg High  --UNUSED--
//	ldi		r16,1
//	sts		PirF,r16
	ldi		r16,PirH-Pstart
	rjmp	SPput
SPs82: // RW Ireg Low
//	ldi		r16,1
//	sts		PirF,r16
	ldi		r16,PirL-Pstart
	rjmp	SPput

//-------------------------------------

SPs86: // RW OCD JTAG Clock			1/4 of part frequency
	mov		r16,r18
	com		r16
	sts		JTclk,r16
	ldi		r16,Pjclk-Pstart
	rjmp	SPput

//-------------------------------------

SPs88: //  W Flash PageSizeL		Device specific
	ldi		r16,uwFlashPageSize-Pstart
	rjmp	SPput
SPs89: //  W Flash PageSizeH		Device specific
	ldi		r16,uwFlashPageSize-Pstart+1
	rjmp	SPput
SPs8A: //  W EEPROM PageSize		Device specific
	ldi		r16,ucEepromPageSize-Pstart
	rjmp	SPput

//-------------------------------------

SPs8B: //  W External Reset
	tst		r18
	brne	SPs8Brst
	cbi		JDDR,JRST
	rjmp	putcR_OK
SPs8Brst:
	cbi		JPORT,JRST
	sbi		JDDR,JRST
	rjmp	putcR_OK

//-------------------------------------

SPsA0: //  W Timers Running	//--setOCD_BCRTimersRun--
	push	r18
	rcall	JTReadBCR //r r16 r17 c r18 r19 r20 r21 r22 c r10 r12 r13 r14 r15
	pop		r18
	andi	r17,0x7F //Disable timers
	tst		r18
	breq	SPsA0off
	ori		r17,0x80
SPsA0off:
	rcall	JTWriteBCR
	rjmp	putcR_OK

//-------------------------------------

SPsA1: // Break on change of flow.
	rcall	JTReadBCR //r r16 r17 c r18 r19 r20 r21 r22 c r10 r12 r13 r14 r15
	ori		r17,0x10
	rcall	JTWriteBCR
	rjmp	putcR_OK

//-------------------------------------

SPsA2: //  W Break Addr1H
	ldi		r16,Pbr1H-Pstart
	rjmp	SPput
SPsA3: //  W Break Addr1L
	ldi		r16,Pbr1L-Pstart
	rjmp	SPput
SPsA4: //  W Break Addr2H
	ldi		r16,Pbr2H-Pstart
	rjmp	SPput
SPsA5: //  W Break Addr2L
	ldi		r16,Pbr2L-Pstart
	rjmp	SPput

//-------------------------------------

//mapping to BCR bits
//7-2 EN_PSB1 turn on only
//6-1 BMASK
//5-0 EN_PDMSB
//4-7 EN_PDSB
//3-6 PDMSB1
//2-5 PDMSB0
//1-4 PDSB1
//0-3 PDSB0

SPsA6: //  W CombBreakCtrl
	push	r18
    
	rcall	JTWriteBr1 //PDMSB = Pbr
	rcall	JTWriteBr2 //PDSB  = Pbr
	rcall	JTReadBCR //r r16 r17 c r18 r19 r20 r21 r22 c r10 r12 r13 r14 r15

	pop		r18
	mov		r19,r18
	swap	r19
	lsr		r19
	andi	r19,7
	andi	r17,0xFC //EN_PSB1 turn on only ?
	or		r17,r19
	//
	lsl		r18
	lsl		r18
	lsl		r18
	andi	r16,3 //BCR2 cleared ??
	or		r16,r18

	rcall	JTWriteBCR
	rjmp	putcR_OK

//-------------------------------------

#ifdef DAISY

SPsAB: //  W Units Before
	ldi		r16,Pub-Pstart
	rjmp	SPput
SPsAC: //  W Units After
	ldi		r16,Pua-Pstart
	rjmp	SPput
SPsAD: //  W Bits Before
	ldi		r16,Pbb-Pstart
	rjmp	SPput
SPsAE: //  W Bits After
	ldi		r16,Pba-Pstart
	rjmp	SPput

#else

SPsAB: //  W Units Before -- not implemented
SPsAC: //  W Units After  -- maybe later...
SPsAD: //  W Bits Before  -- it greatly complicates jtag shifting
SPsAE: //  W Bits After
	rjmp	putcR_OK

#endif

//-------------------------------------

SPsAF: //  W PSB0L
	ldi		r16,Psb0L-Pstart
	rcall	SPput
	ldi		r18,0
	rjmp	JTWritePSBsp
SPsB0: //  W PSB0H
	ldi		r16,Psb0H-Pstart
	rjmp	SPput
SPsB1: //  W PSB1L
	ldi		r16,Psb1L-Pstart
	rcall	SPput
	ldi		r18,1
	rjmp	JTWritePSBsp
SPsB2: //  W PSB1H
	ldi		r16,Psb1H-Pstart
	rjmp	SPput

//-------------------------------------

SPsB4: //? W
	ldi		r16,SPb4-Pstart
	rjmp	SPput
SPsB5: //? W
	ldi		r16,SPb5-Pstart
	rjmp	SPput
SPsB6: //? W
/*p	ldi		r16,lo8(RMpml2)
	sts		Ppml+0,r16
	ldi		r16,hi8(RMpml2)
	sts		Ppml+1,r16*/

	ldi		r16,SPb6-Pstart
	rjmp	SPput
SPsB7: //? W
	ldi		r16,SPb7-Pstart
	rjmp	SPput
SPsB8: //? W
	ldi		r16,SPb8-Pstart
	rjmp	SPput

//-------------------------------------

SPput:
	ldi		r30,lo8(Pstart)
	ldi		r31,hi8(Pstart)
	add		r30,r16
	adc		r31,rnull
	st		Z,r18
SPok:
	rjmp	putcR_OK

//SetParameter switch
//=============================================================================
//ReadMem

RMjt:
.db RMs20-RMij , 0x20 //Sram
.db RMs22-RMs20, 0x22 //Eeprom
.db RMs30-RMs22, 0x30 //IOShadow
.db RMs90-RMs30, 0x90 //BreakReg
.db RMsA0-RMs90, 0xA0 //PML -- w
.db RMsB0-RMsA0, 0xB0 //FLASH_JTAG -- w
.db RMsB1-RMsB0, 0xB1 //EEPROM_JTAG
.db RMsB2-RMsB1, 0xB2 //FUSE_JTAG
.db RMsB3-RMsB2, 0xB3 //LOCK_JTAG
.db RMsB4-RMsB3, 0xB4 //SIGN_JTAG
.db RMsB5-RMsB4, 0xB5 //OSCCAL_JTAG
.db 0,0

//-------------------------------------

ReadMem:	//type r5 -- count r6 -- msb r7 r8 r9 lsb --
	mov		r16,r5
	cpi		r16,0xB0
	brcc	RMJTp
	rcall	IfMcuStopped
	breq	RMok
	cpi		r16,0x90 //??
	breq	RMok //??
	rjmp	RMput
RMJTp:
	rcall	IfMcuProgramming
	breq	RMokp
RMput:
	mov		r16,r5
	ori		r16,0xEF
	cpi		r16,0xA0 //0xA0 0xB0
	brne	RMput1
	ldi		r16,7
	rcall	putc_nf
RMput1:
	ldi		r16,7
	rcall	putc_nf
	dec		r6
	brne	RMput
	rcall	flush
	ret

RMokp:
	rcall	JTShiftIR_5 //c r10 r12 r13 r14 r15 r20 r21 r22
RMok:
	mov		r16,r5 //type
	ldi		r17,RMij-RMjt
	rcall	DoSwitch //p r16 c 17 22 23 24 25 30 31
RMij:
	rjmp	putcR_FAIL

//-------------------------------------

RMs20: //Sram
//	rcall	EnableOCDR //???
//	ldi		r24,0
	rcall	JTSetBCR_SS //PC24 = 0 for DoLDr28Zp
//////
	rcall	JTShiftIR_A //xx
	mov		r24,r9
	mov		r25,r8
	rcall	DoLDI_Z
//////

RMs20next: //Sram
//---------------------------
	tst		r8 //if( >= 0x100)
	brne	RMs20ram
	mov		r16,r9
	cpi		r16,0x60
	brcc	RMs20extio //>=0x60
	cpi		r16,0x20
	brcc	RMs20io //>=0x20
//--------------------------- 0x00-0x1F
//if(r0-1 27-31)
	cpi		r16,2
	brcs	RMs20r0 // 0 1
	subi	r16,27
	brcs	RMs20ram //2-26
	rjmp	RMs20r27 //27-31
RMs20r0:
	subi	r16,-5
RMs20r27:
	ldi		r30,lo8(JT_YZ)
	ldi		r31,hi8(JT_YZ)
	add		r30,r16
	adc		r31,rnull
	rcall	DoAdiwZ1 //c r16 r17 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15
	ld		r16,Z
	rjmp	RMs20ee
//--------------------------- 0x20-0x5F
RMs20io:
	cpi		r16,0x5F
	breq	RMs20sreg
	subi	r16,0x20
	ldi		r30,lo8(ucRead)
	ldi		r31,hi8(ucRead)
	rjmp	RMs20iobm
RMs20sreg:
	rcall	DoAdiwZ1 //c r16 r17 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15
	lds		r16,JT_SREG
	rjmp	RMs20ee
//--------------------------- 0x60-0x100
RMs20extio:
	lds		r23,ucUpperExtIOLoc
	tst		r23
	breq	RMs20ram
	subi	r16,0x60
	ldi		r30,lo8(ucExtRead)
	ldi		r31,hi8(ucExtRead)
RMs20iobm:
	rcall	BitMask
	breq	RMs20adiw
//---------------------------
RMs20ram:
	rcall	DoLDr28Zp //c r16 r17 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15
	rjmp	RMs20ee
RMs20adiw:
	rcall	DoAdiwZ1 //c r16 r17 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15
	ldi		r16,0
RMs20ee:
	rcall	putc_nf
	rcall	RWMnext
	brne	RMs20next
	rcall	JTSetBCR_24
	rjmp	RMend

//-------------------------------------

RMs22: //Eeprom
//	rcall	SaveProgContext
	rcall	SaveEepRegs
	lds		r11,ucEECR
	rcall	JTShiftIR_A //xx
RMs22n:
	mov		r17,r8
	rcall	DoLDIr28  //pc r17 c r16 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15
	mov		r17,r11
	subi	r17,-3 //EEARH
	rcall	DoOUTr28 //pc r17 c r16 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15

	mov		r17,r9
	rcall	DoLDIr28  //pc r17 c r16 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15
	mov		r17,r11
	subi	r17,-2 //EEARL
	rcall	DoOUTr28 //pc r17 c r16 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15

	ldi		r17,0x01 //EERE
	rcall	DoLDIr28  //pc r17 c r16 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15
	mov		r17,r11 //EECR
	rcall	DoOUTr28 //pc r17 c r16 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15

	mov		r17,r11
	subi	r17,-1 //EEDR
	rcall	DoINr28_outOCDR
	rcall	putc_nf

	rcall	RWMnext
	brne	RMs22n
	rcall	RestoreEepRegs
	rjmp	RMend

//-------------------------------------

RMs30: //IOShadow  --  will this ever be used ? and for what ???
	rjmp	RMput // used by m16 and m323 - IO 28 29 2A 2B 2D
/*	tst		r8
	breq	RMs30ok
	mov		r16,r9
	cpi		r16,0x60
	brcs	RMs30ok
	rjmp	RMput
RMs30ok:
	rcall	JTReadCSR //r r16 r17 c r18 r19 r20 r21 r22 c r10 r12 r13 r14 r15
	ori		r17,(1<<CSR_SHADOW)
	rcall	JTWriteCSR
	rcall	JTShiftIR_A //xx

RMs30n:
	mov		r16,r9
	subi	r16,0x20
	ldi		r30,lo8(ucReadShadow)
	ldi		r31,hi8(ucReadShadow)
	rcall	BitMask
	brne	RMs30in
	ldi		r16,0
	rjmp	RMs30p
RMs30in:
	mov		r17,r9
	rcall	DoINr28_outOCDR
RMs30p:
	rcall	putc_nf
	rcall	RWMnext
	brne	RMs30n

	rcall	JTReadCSR //r r16 r17 c r18 r19 r20 r21 r22 c r10 r12 r13 r14 r15
	andi	r17,~(1<<CSR_SHADOW)
	rcall	JTWriteCSR
	rjmp	RMend*/

//-------------------------------------

RMs90: //BreakReg -- OCD registers on IR=B
	mov		r18,r9
	andi	r18,0x0F //?
	rcall	JTReadOCD //r r16 r17 pc r18 c r19 r20 r21 r22 c r10 r12 r13 r14 r15
	rcall	RMputword
	rcall	RWMnext
	brne	RMs90
	rjmp	RMend

//-------------------------------------

RMsA0: //PML
//	rcall	SaveProgContext
	rcall	JTShiftIR_A //c r10 r12 r13 r14 r15 r20 r21 r22
//p	lds		r30,Ppml
//p	lds		r31,Ppml+1
RMsA0n:
//p	icall
	rcall	RMpml1
	mov		r16,r19
	rcall	putc_nf
	mov		r16,r18
	rcall	putc_nf
	rcall	RWMnext
	brne	RMsA0n 
	rjmp	RMend

//---------------------------
//default
RMpml1: //p r8r9  r r18r19 c r16 r17
	rcall	RMp2
RMp2:
	ldi		r19,0 //NOP
	ldi		r18,0
	mov		r17,r8
	mov		r16,r9
	ldi		r20,0x20
	rcall	JTShiftDR0 //pr r16 r17 r18 r19 pc r20 p r21 c r22 r10 r12 r13 r14 r15
	ret

/*p
//Ir = r18 r19  PC = r16 r17
RMpml2: //p r8r9  r r18r19 c r16 r17   Will this ever be used ? and will it work ?
	ldi		r16,0
	ldi		r17,0
	ldi		r18,0x0C
	ldi		r19,0x94 //JMP
	ldi		r20,0x20
	ldi		r21,1 //Write
	ldi		r22,1 //idle
	rcall	JTShiftDR //pr r16 r17 r18 r19 pc r20 r22 p r21 c r10 r12 r13 r14 r15

	mov		r17,r8
	mov		r16,r9
	ldi		r20,0x10
	ldi		r22,2 //idle
	rcall	JTShiftDR //pr r16 r17 r18 r19 pc r20 r22 p r21 c r10 r12 r13 r14 r15

	ldi		r20,0x20
	ldi		r21,0 //Read
	rcall	JTShiftDR0 //pr r16 r17 r18 r19 pc r20 p r21 c r22 r10 r12 r13 r14 r15
	ret*/


//-----------------------------------------------==========
//-----------------------------------------------==========


RMsB0: //FLASH_JTAG -- PAGEREAD  --tested working--
	ldi		r16,JTPC_RF
	rcall	JTProgCommand
	rcall	RWMloadFE

	ldi		r21,7 //JTEnterPageRead
	rcall	JTShiftIR //pc r21 c r10 r12 r13 r14 r15 r20 r22

	lds		r16,ucEECR
	cpi		r16,0x1F  //new avr's have EECR=3F and new algorithm on IR=6/7
	breq	JRnewAVR

//---------------------------

	ldi		r21,1 //R
	rcall	JTGotoShiftDR //c r10
	ldi		r20,10
	rcall	JTDoShift //dump the first 8 bits
RMsB0n:
	ldi		r20,20 //no tms
	mov		r16,r6
	cpi		r16,1
	brne	RMSB0l
	ldi		r20,16 //last
RMSB0l:
	rcall	JTDoShift //low //c r10 r12 r13 r r14  pc r15 r20 p r21
	mov		r16,r14
	rcall	putc_nf
	rcall	JTDoShift //high //c r10 r12 r13 r r14  pc r15 r20 p r21
	mov		r16,r14
	rcall	putc_nf

	rcall	RWMnextFP
	brne	RMsB0n
	rcall	JTGotoSelectDR //pc r22 c r10
	rcall	JTShiftIR_5
	rjmp	RMend

//---------------------------

JRnewAVR: //20111126
	ldi		r21,1 //R
RnA:
	rcall	ReadNew
	rcall	ReadNew
	rcall	RWMnextFP
	brne	RnA
	rcall	JTShiftIR_5
	rjmp	RMend

ReadNew:
	rcall	JTGotoShiftDR //c r10
	ldi		r20,8
	rcall	JTDoShift //low //c r10 r12 r13 r r14  pc r15 r20 p r21
	mov		r16,r14
	rcall	putc_nf
	rcall	JTGotoSelectDR //pc r22 c r10
	ret

//-------------------------------------

/*RMsB0: //FLASH_JTAG -- pp interface  --tested working--
	ldi		r16,JTPC_RF
	rcall	JTProgCommand
	rcall	RWMloadFE
RMsB0n:

	ldi		r17,JTPI_RLB
	rcall	JTProgInst
	ldi		r17,JTPI_RHB
	rcall	JTProgInst
	rcall	putc_nf
	ldi		r17,JTPI_RHB | 1
	rcall	JTProgInst
	rcall	putc_nf

	rcall	RWMnextFE
	brne	RMsB0n
	rjmp	RMend*/

//-------------------------------------

RMsB1: //EEPROM_JTAG
	ldi		r16,JTPC_RE
	rcall	JTProgCommand
	rcall	RWMloadFE
RMsB1n:

	ldi		r17,JTPI_RLB
	rcall	JTProgInst
	ldi		r17,JTPI_RLB | 1
	rcall	JTProgInst
	rcall	putc_nf

	rcall	RWMnextFE
	brne	RMsB1n
	rjmp	RMend

//-------------------------------------

RMsB2: //FUSE_JTAG
	ldi		r16,JTPC_RFL
	rcall	JTProgCommand
RMsB2n:	
	ldi		r17,4
	sub		r17,r9
	andi	r17,3 // 0 1 2 3 -> 0 3 2 1
	lsl		r17
	lsl		r17
	ori		r17,JTPI_RLB //0x32
	push	r17
	rcall	JTProgInst
	pop		r17
	ori		r17,1 //RD
	rcall	JTProgInst
	rcall	putc_nf
	rcall	RWMnext
	brne	RMsB2n
	rjmp	RMend

//-------------------------------------

RMsB3: //LOCK_JTAG
	ldi		r16,3
	mov		r9,r16
	rjmp	RMsB2

//-------------------------------------

RMsB4: //SIGN_JTAG
	ldi		r16,JTPI_RLB
	rjmp	RMsB5e

//-------------------------------------

RMsB5: //OSCCAL_JTAG
	ldi		r16,JTPI_RHB
RMsB5e:
	mov		r11,r16
	ldi		r16,JTPC_RSC
	rcall	JTProgCommand
RMsB5n:	
	rcall	JTProgLLA
	mov		r17,r11
	rcall	JTProgRead
	rcall	putc_nf
	rcall	RWMnext
	brne	RMsB5n
RMend:
	ldi		r16,0 //fake checksum
	rcall	putc_nf
	rjmp	putcR_OK

//-------------------------------------

//ReadMem
//=============================================================================

BitMask: // p r16 c r17 r18 pc Z
	mov		r17,r16
	lsr		r16
	lsr		r16
	lsr		r16
	add		r30,r16
	adc		r31,rnull
	ld		r16,Z

	//r18 = 1 << (r17&7)
	ldi		r18,1
	sbrc	r17,1 //2
	ldi		r18,4
	sbrc	r17,0 //1
	lsl		r18
	sbrc	r17,2 //4
	swap	r18

	and		r16,r18
	ret

//-------------------------------------

RWMnext:
	ldi		r16,1
	add		r9,r16
	adc		r8,rnull
	adc		r7,rnull
	dec		r6
	ret

//-------------------------------------

RWMloadFE:	
	rcall	JTProgLLA
	rcall	JTProgLHA
#ifdef M256
	rcall	JTProgLEA
#endif
	ret

//-------------------------------------

RWMnextFP:
	inc		r9
	tst		r9
	brne	RFEr
	inc		r8
	tst		r8
	brne	RFEr
	inc		r7
RFPr:	
	dec		r6
	ret

//-------------------------------------

RWMnextFE:
	inc		r9
	rcall	JTProgLLA
	tst		r9
	brne	RFEr
	inc		r8
	rcall	JTProgLHA
	tst		r8
	brne	RFEr
	inc		r7
#ifdef M256
	rcall	JTProgLEA
#endif
RFEr:	
	dec		r6
	ret

//-------------------------------------

RMputword:
	push	r16
	mov		r16,r17
	rcall	putc_nf
	pop		r16
	rcall	putc_nf
	ret

//=============================================================================
//WriteMem

WMjt:
.db WMs20-WMij , 0x20 //Sram
.db WMs22-WMs20, 0x22 //Eeprom
.db WMs30-WMs22, 0x30 //IOShadow
.db WMs60-WMs30, 0x60 //EventL
.db WMsA0-WMs60, 0xA0 //PML -- w
.db WMsB0-WMsA0, 0xB0 //FLASH_JTAG -- w
.db WMsB1-WMsB0, 0xB1 //EEPROM_JTAG
.db WMsB2-WMsB1, 0xB2 //FUSE_JTAG
.db WMsB3-WMsB2, 0xB3 //LOCK_JTAG
.db 0,0

//-------------------------------------

WriteMem:	//type r5 -- count r6 -- msb r7 r8 r9 lsb --
	rcall	getc //'h' 0x68 Cmnd_Data
	mov		r16,r5
	cpi		r16,0xB0
	brcc	WMJTp
	rcall	IfMcuStopped
	breq	WMok
	cpi		r16,0x60 //??
	breq	WMok //??
	rjmp	WMget
WMJTp:
	rcall	IfMcuProgramming
	breq	WMokp
WMget:
	mov		r16,r5
	andi	r16,0xEF
	cpi		r16,0xA0 //0xA0 0xB0
	brne	WMget1
	rcall	getc
WMget1:	
	rcall	getc
	dec		r6
	brne	WMget
	ret

WMokp:
	rcall	JTShiftIR_5 //c r10 r12 r13 r14 r15 r20 r21 r22
WMok:
	mov		r16,r5 //type
	ldi		r17,WMij-WMjt
	rcall	DoSwitch //p r16 c 17 22 23 24 25 30 31
WMij:
	ret
//	rjmp	WMget
//	rjmp	putcR_FAIL

//-------------------------------------

WMs20: //Sram
//	ldi		r24,0
	rcall	JTSetBCR_SS //PC24 = 0 for DoLDr28Zp
//////
	rcall	JTShiftIR_A //xx
	mov		r24,r9
	mov		r25,r8
	rcall	DoLDI_Z
//////

WMs20next: //Sram
//---------------------------
	tst		r8 //if( >= 0x100)
	brne	WMs20ram
	mov		r16,r9
	cpi		r16,0x60
	brcc	WMs20extio //>=0x60
	cpi		r16,0x20
	brcc	WMs20io //>=0x20
//--------------------------- 0x00-0x1F
//if(r0-1 27-31)
	cpi		r16,2
	brcs	WMs20r0 // 0 1
	subi	r16,27
	brcs	WMs20ram //2-26
	rjmp	WMs20r27 //27-31
WMs20r0:
	subi	r16,-5
WMs20r27:
	ldi		r30,lo8(JT_YZ)
	ldi		r31,hi8(JT_YZ)
	add		r30,r16
	adc		r31,rnull
	rcall	DoAdiwZ1 //c r16 r17 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15
	rcall	getc
	st		Z,r16
	rjmp	WMs20ee
//--------------------------- 0x20-0x5F
WMs20io:
	cpi		r16,0x5F
	breq	WMs20sreg
	subi	r16,0x20
	ldi		r30,lo8(ucWrite)
	ldi		r31,hi8(ucWrite)
	rjmp	WMs20iobm
WMs20sreg:
	rcall	DoAdiwZ1 //c r16 r17 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15
	rcall	getc
	sts		JT_SREG,r16
	rjmp	WMs20ee
//--------------------------- 0x60-0x100
WMs20extio:
	lds		r23,ucUpperExtIOLoc
	tst		r23
	breq	WMs20ram
	subi	r16,0x60
	ldi		r30,lo8(ucExtWrite)
	ldi		r31,hi8(ucExtWrite)
WMs20iobm:
	rcall	BitMask
	breq	WMs20adiw
//---------------------------
WMs20ram:
	rcall	getc
	mov		r17,r16
	rcall	DoSTZpr28
	rjmp	WMs20ee
WMs20adiw:
	rcall	DoAdiwZ1 //c r16 r17 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15
WMs20ee:
	rcall	RWMnext
	brne	WMs20next
	rcall	DoNOP
	rcall	JTSetBCR_24
	ret

//-------------------------------------

WMs22: //Eeprom
//	rcall	SaveProgContext
	rcall	SaveEepRegs
	lds		r11,ucEECR
	rcall	JTShiftIR_A //xx
WMs22n:
	mov		r17,r8
	rcall	DoLDIr28  //pc r17 c r16 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15
	mov		r17,r11
	subi	r17,-3 //EEARH
	rcall	DoOUTr28 //pc r17 c r16 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15

	mov		r17,r9
	rcall	DoLDIr28  //pc r17 c r16 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15
	mov		r17,r11
	subi	r17,-2 //EEARL
	rcall	DoOUTr28 //pc r17 c r16 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15

	rcall	getc
	mov		r17,r16
	rcall	DoLDIr28  //pc r17 c r16 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15
	mov		r17,r11
	subi	r17,-1 //EEDR
	rcall	DoOUTr28 //pc r17 c r16 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15

	ldi		r17,0x04 //EEMWE
	rcall	DoLDIr28  //pc r17 c r16 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15
	mov		r17,r11 //EECR
	rcall	DoOUTr28 //pc r17 c r16 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15

	ldi		r17,0x02 //EEWE
	rcall	DoLDIr28  //pc r17 c r16 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15
	mov		r17,r11 //EECR
	rcall	DoOUTr28 //pc r17 c r16 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15

WMs22wait:
	mov		r17,r11
	rcall	DoINr28_outOCDR
	andi	r16,0x02 //EEWE
	brne	WMs22wait

	rcall	RWMnext
	brne	WMs22n
	rcall	RestoreEepRegs
	ret

//-------------------------------------

WMs30: //IOShadow  --  will this ever be used ? and for what ???
	rjmp	WMget
/*	tst		r8
	breq	WMs30ok
	mov		r16,r9
	cpi		r16,0x60
	brcs	WMs30ok
	rjmp	WMget
WMs30ok:
	rcall	JTReadCSR //r r16 r17 c r18 r19 r20 r21 r22 c r10 r12 r13 r14 r15
	ori		r17,(1<<CSR_SHADOW)
	rcall	JTWriteCSR
	rcall	JTShiftIR_A //xx

WMs30n:
	rcall	getc
	mov		r17,r16
	rcall	DoLDIr28  //pc r17 c r16 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15
	mov		r16,r9
	subi	r16,0x20
	ldi		r30,lo8(ucWriteShadow)
	ldi		r31,hi8(ucWriteShadow)
	rcall	BitMask
	breq	WMs30nn
	mov		r17,r9
	rcall	DoOUTr28 //pc r17 c r16 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15
WMs30nn:
	rcall	RWMnext
	brne	WMs30n

	rcall	JTReadCSR //r r16 r17 c r18 r19 r20 r21 r22 c r10 r12 r13 r14 r15
	andi	r17,~(1<<CSR_SHADOW)
	rcall	JTWriteCSR
	//rjmp	putcR_OK
	ret
*/
//-------------------------------------

WMs60: //EventL
	rcall	getc
	mov		r18,r16
	andi	r18,1 //only 0 or 1
	mov		r17,r8
	mov		r16,r9
	rcall	JTWritePSB
	ret

//	rcall	RWMnext
//	brne	WMs60
//	ret

//-------------------------------------

WMsA0: //PML
	rjmp	WMget //silently fail
/*
//	rcall	SaveProgContext
	lsl		r9
	rol		r8
	rol		r7 //byte addressing
	rcall	JTShiftIR_A //xx
WMsA0np:
	mov		r16,r7	
	rcall	DoST_RAMPZ
	push	r8
	push	r9
	lds		r23,uwFlashPageSize
WMsA0n:
	rcall	DoIJMPtoBoot // actually only needed every ~30 cycles... (30*7=210 almost 2 pages)
	mov		r24,r9
	mov		r25,r8
	rcall	DoLDI_Z //r24r25

	//DoLDI r1,getc() //msb
	rcall	getc
	mov		r17,r16
	rcall	DoLDIr28  //pc r17 c r16 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15
	ldi		r16,1
	ldi		r17,28
	rcall	DoMOV

	//DoLDI r0,getc() //lsb
	rcall	getc
	mov		r17,r16
	rcall	DoLDIr28  //pc r17 c r16 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15
	ldi		r16,0
	ldi		r17,28
	rcall	DoMOV

	ldi		r16,(1<<SPMEN)
	rcall	DoSPM

	rcall	RWMnextFP
	inc		r6
	rcall	RWMnextFP //add addr,2
	breq	WMsA0b
	dec		r23
	brne	WMsA0n
//----
WMsA0b: //write page
	pop		r24
	pop		r25
	rcall	DoLDI_Z //r24r25
	ldi		r16,(1<<PGWRT)|(1<<SPMEN) //05
	rcall	DoSPM
	ldi		r16,(1<<RWWSRE)|(1<<SPMEN) //11
	rcall	DoSPM
	tst		r6
	brne	WMsA0np
	ret*/


//-----------------------------------------------==========
//-----------------------------------------------==========


WMsB0: //FLASH_JTAG
	ldi		r16,JTPC_WF
	rcall	JTProgCommand
	rcall	GetFPS
//---------------------------
	mov		r25,r24
	dec		r25 //0x7F 0x3F
	mov		r16,r25
	and		r25,r9
	com		r16
	and		r9,r16
//---------------------------
	rjmp	WMsB0fp

WMsB0np:
	rcall	GetFPS
	ldi		r25,0
	add		r9,r24
	adc		r8,rnull
	adc		r7,rnull
WMsB0fp:
	rcall	RWMloadFE

	ldi		r21,6 //JTEnterPageWrite
	rcall	JTShiftIR //pc r21 c r10 r12 r13 r14 r15 r20 r22
	rcall	JTGotoShiftDR //c r10
	ldi		r21,1 //Write
//---------------------------
	tst		r25
	breq	WMsB0n
WMsB0p:
	ldi		r20,20 //no tms
	ldi		r16,0xFF
	rcall	JTDoShiftR16
	ldi		r16,0xFF
	rcall	JTDoShiftR16
	dec		r25
	brne	WMsB0p
//---------------------------

WMsB0n:
	ldi		r20,16 //last
	dec		r6
	breq	WMSB0l
	dec		r24
	breq	WMSB0l
	ldi		r20,20 //no tms
WMSB0l:
	rcall	JTDoShiftGetc
	rcall	JTDoShiftGetc
	tst		r6
	breq	WMsB0b
	tst		r24
	brne	WMsB0n
//----
WMsB0b:
	//not sure if 11 idle clock is required for new avrs
	//rather put it in, it won't do any harm either
	ldi		r22,11
	rcall	JTGotoSelectDR //pc r22 c r10

	rcall	JTShiftIR_5
	ldi		r17,0x37 //JTPI_WHB | 2 //0x37
	rcall	JTProgWB //write page

	tst		r6
	brne	WMsB0np
	ret

//-------------------------------------

JTDoShiftGetc:
	rcall	getc
JTDoShiftR16:
	mov		r15,r16
	lds		r16,ucEECR
	cpi		r16,0x1F  //new avr's have EECR=3F and new algorithm on IR=6/7
	breq	JDSnewAVR
	rcall	JTDoShift //low //c r10 r12 r13 r r14  pc r15 r20 p r21
	ret
JDSnewAVR: //20111126
	push	r20
	ldi		r20,8
	rcall	JTDoShift //low //c r10 r12 r13 r r14  pc r15 r20 p r21
	pop		r20
	subi	r20,8
	breq	newret
	rcall	JTGotoSelectDR //pc r22 c r10
	rcall	JTGotoShiftDR //c r10
newret:
	ret

GetFPS:
	lds		r24,uwFlashPageSize
	lds		r25,uwFlashPageSize+1
	lsr		r25
	ror		r24 //byte to word count
	ret

//-------------------------------------

/*WMsB0: //FLASH_JTAG -- pp interface  --tested working--
	ldi		r16,JTPC_WF
	rcall	JTProgCommand
	rcall	RWMloadFE
	lds		r24,uwFlashPageSize
	rjmp	WMsB0f
WMsB0np:
	lds		r24,uwFlashPageSize
WMsB0n:
	rcall	RWMnextFE
	breq	WMsB0wp
WMsB0f:
	rcall	getc
	rcall	JTProgLLB
	rcall	getc
	rcall	JTProgLHB
	rcall	JTProgLatch
	dec		r24
	brne	WMsB0n
WMsB0wp:
	ldi		r17,0x37 //JTPI_WHB | 2 //0x37
	rcall	JTProgWB //write page
	tst		r6
	brne	WMsB0np
	ret*/

//-------------------------------------

WMsB1: //EEPROM_JTAG
	ldi		r16,JTPC_WE
	rcall	JTProgCommand
	rcall	RWMloadFE
	lds		r24,ucEepromPageSize
	rjmp	WMsB1f
WMsB1np:
	lds		r24,ucEepromPageSize
WMsB1n:
	rcall	RWMnextFE
	breq	WMsB1wp
WMsB1f:
	rcall	getc
	rcall	JTProgLLB
	rcall	JTProgLatch
	dec		r24
	brne	WMsB1n
WMsB1wp:
	ldi		r17,0x33 //JTPI_WLB | 2
	rcall	JTProgWB //write page
	tst		r6
	brne	WMsB1np

	//ldi		r16,1 //fix ? for avrstudio verification error
	//rcall	Delay //fix ? seems to work :)

	ret

//-------------------------------------

WMsB2: //FUSE_JTAG
	ldi		r16,JTPC_WFB
	rcall	JTProgCommand
WMsB2n:
	rcall	getc
#ifdef ENABLE_WMsB2
	rcall	JTProgLLB
	mov		r17,r9
	cpi		r17,3
	brcc	WMsB2r
	lsl		r17
	lsl		r17
	andi	r17,0x0C
	ori		r17,0x33 //JTPI_WLB | 2 //33 37 3B
	rcall	JTProgWB
#endif
	rcall	RWMnext
	brne	WMsB2n
WMsB2r:	
	ret

//-------------------------------------

WMsB3: //LOCK_JTAG
	ldi		r16,JTPC_WLB
	rcall	JTProgCommand
	clr		r6
	inc		r6 //ldi r6,1
	clr		r9
	rjmp	WMsB2n

//-------------------------------------

//WriteMem
//=============================================================================
//=============================================================================
//CONTEXT

SaveEepRegs:
	//EEPROM - DR AL AH
	rcall	JTShiftIR_A //xx
	ldi		r30,lo8(JTEEDR)
	ldi		r31,hi8(JTEEDR)
	ldi		r23,3
	lds		r11,ucEECR
SPCee:
	inc		r11 //skip CR
	mov		r17,r11
	rcall	DoINr28_outOCDR
	st		Z+,r16
	dec		r23
	brne	SPCee
	ret


RestoreEepRegs:
	//EE DR AL AH
	rcall	JTShiftIR_A //xx
	ldi		r30,lo8(JTEEDR)
	ldi		r31,hi8(JTEEDR)
	ldi		r23,3
	lds		r11,ucEECR
RCCee:
	inc		r11 //skip CR
	ld		r17,Z+
	rcall	DoLDIr28  //pc r17 c r16 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15
	mov		r17,r11
	rcall	DoOUTr28 //pc r17 c r16 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15
	dec		r23
	brne	RCCee
	ret

//=============================================================================

SaveContext:
	lds		r16,JTCstate
	sbrc	r16,0 //1
	ret
	ori		r16,1 //bit0
	sts		JTCstate,r16

	//JTGetPC:
	rcall	JTGetIrPC
	ldi		r30,lo8(JTPC)
	ldi		r31,hi8(JTPC)
	st		Z+,r16
	st		Z+,r17
	st		Z+,rnull

	rcall	EnableOCDR

	//XXX 2013 //Save SREG  used to be here causing a bug in r28... :(

	//save registers 27-31 + 0-1
	lds		r26,ucOCDRaddress
	ldi		r23,27
	ldi		r30,lo8(JT_YZ)
	ldi		r31,hi8(JT_YZ)
SCr0:
	rcall	JTShiftIR_A //xx //c r10 r12 r13 r14 r15 r20 r21 r22
	mov		r16,r23
	mov		r17,r26
	rcall	DoOUT
	rcall	JTReadOCDR //r r16 c r17 r18 r19 r20 r21 r22 c r10 r12 r13 r14 r15
	st		Z+,r16
	inc		r23
	cpi		r23,34 // 27-31 0-1
	brcs	SCr0

	//Save SREG - moved here 09/2013
	ldi		r17,0x3F //SREG
	rcall	DoINr28_outOCDR
	sts		JT_SREG,r16
	ret

/*
SaveProgContext:
	lds		r16,JTCstate
	sbrc	r16,1 //2
	ret
	ori		r16,2 //bit1
	sts		JTCstate,r16
	rcall	JTShiftIR_A //xx

	//SPMC
	lds		r24,ucSPMCAddress
	ldi		r25,0
	rcall	DoLDr28Z_outOCDRr28 ????
	sts		JTSPMC,r16

	rjmp	SaveEepRegs*/

//=============================================================================

RestoreContext:
//---------------------------
//	ldi		r24,0
//	rcall	JTSetBCR_SS e //PC24 = 0

	rcall	JTShiftIR_A //xx
	lds		r16,JTCstate
	sts		JTCstate,rnull
/*	sbrs	r16,1 //2
	rjmp	RCpc

	lds		r24,ucSPMCAddress
	ldi		r25,0
	lds		r17,JTSPMC
	rcall	DoSTZr28

	rcall	RestoreEepRegs*/


//---------------------------
RCpc:
	//restore registers 0-1 
	ldi		r23,0
	ldi		r30,lo8(JT_YZ+5)
	ldi		r31,hi8(JT_YZ+5)
RCr0:
	ldi		r16,31
	ld		r17,Z+
	rcall	DoLDI
	mov		r16,r23
	ldi		r17,31
	rcall	DoMOV
	inc		r23
	cpi		r23,2
	brcs	RCr0
	
	//restore registers 27-29
	sbiw	r30,7
	ldi		r23,27
RCr28:	
	mov		r16,r23
	ld		r17,Z+
	rcall	DoLDI
	inc		r23
	cpi		r23,30 //XXX 2013 was 32
	brcs	RCr28

	rcall	DisableOCDR
	rcall	JTShiftIR_A //xx

	//restore SREG
	ldi		r16,31
	lds		r17,JT_SREG
	rcall	DoLDI
	ldi		r16,31
	ldi		r17,0x3F //SREG
	rcall	DoOut

//---PCload---
	lds		r24,JTPC
	lds		r25,JTPC+1
	sbiw	r24,10 //<<------------ mki use 6 --- pc24 = 0 2+2+2 == 6 --- pc24=1  4+4+2 == 10

	ldi		r16,30
	mov		r17,r24
	rcall	DoLDI
	ldi		r16,31
	mov		r17,r25
	rcall	DoLDI

	rcall	DoWDR
	rcall	DoIJMP

	//restore registers 30-31
	ldi		r16,30
	lds		r17,JT_YZ+3
	rcall	DoLDI
	ldi		r16,31
	lds		r17,JT_YZ+4
	rcall	DoLDI
	ret

//----------------------------

//---Ireg---
/*	lds		r16,PirF  unsupported for now, mki implementation seems buggy
	tst		r16
	breq	RCr
	sts		PirF,rnull

	rcall	JTSetBCR_SS //ss=1 pc24=0

	//read 0x10 bits ???
	rcall	JTShiftIR_A //xx
	ldi		r20,0x10
	ldi		r21,0 //read
	rcall	JTShiftDR0 //pr r16 r17 r18 r19 pc r20 p r21 c r22 r10 r12 r13 r14 r15

	lds		r16,PirH // Should it be ??PirH?! seems so from disasm... !?
	lds		r17,PirL //wrong way around, endianness screwup.....
	rcall	DoInstruction --- this will cause PC to increment by 2..... BUG
	32 bit instructions are also a PROBLEM

	rcall	JTSetBCR_24 //ss=0 pc24=1
RCr:*/

//----------------------------


//----------------------------
//---Ireg OLD---
//use DoInstruction instead of this ???
/*
	ldi		r20,0x10
	ldi		r21,0 //Read
	ldi		r22,0 //0 clock
	rcall	JTGotoShiftDR //c r10
	rcall	JTDoShift
	rcall	JTDoShift //Shift the PC around, is this necessary ?
	rcall	JTGotoSelectDR //pc r22 c r10


	ldi		r20,0x10
	ldi		r22,1 //1 clock
	rcall	JTGotoShiftDR //c r10
	ldi		r21,1 //Write
	lds		r15,PirL
	rcall	JTDoShift
	lds		r15,PirH
	rcall	JTDoShift
	rcall	JTGotoSelectDR //pc r22 c r10
*/

//CONTEXT
//=============================================================================
//=============================================================================
// JTag functions  IR=1 GetID

JTGetID: //01
	ldi		r21,1
	rcall	JTShiftIR //pc r21 c r10 r12 r13 r14 r15 r20 r22
	ldi		r20,0x20
	ldi		r21,0 //Read
	rcall	JTShiftDR0 //pr r16 r17 r18 r19 pc r20 p r21 c r22 r10 r12 r13 r14 r15
	ldi		r30,lo8(Pjid0)
	ldi		r31,hi8(Pjid0)
	st		Z+,r16
	st		Z+,r17
	st		Z+,r18
	st		Z+,r19

//------HACK :( EECR detection

	//high id
	swap	r18
	mov		r16,r18
	andi	r16,0x0F
	swap	r19
	andi	r19,0xF0
	or		r19,r16

	//low id
	andi	r18,0xF0
	swap	r17
	andi	r17,0x0F
	or		r18,r17

#ifdef M256
	cpi		r16,0x98
	breq	JGI1f
#endif

	cpi		r19,0x94
	brne	JGIns
	subi	r18,2
JGIns:
	ldi		r16,0x1C
	cpi		r18,3
	brcs	JGIold
JGI1f:
	ldi		r16,0x1F
JGIold:
	sts		ucEECR,r16
	ret
//------
// EECR    1C  1F   1C     1F
//  16k 94 04  05  m162 - m169 (-2)
//  32k 95 02  03  m32  - m329
//  64k 96 02  03  m64  - m649
// 128k 97 02  03  m128 - m1280
// 256k 98  01+02 = 1F m2560/1 -- not supported
//------

// JTag functions  IR=1 GetID
//=============================================================================
// JTag functions  IR=C Reset

JTResetOn:
	ldi		r16,1 //low
	rjmp	JTReset
JTResetOff:
	ldi		r16,0 //high
JTReset:
	ldi		r21,0xC
	rcall	JTShiftIR //pc r21 c r10 r12 r13 r14 r15 r20 r22
	ldi		r20,1 //1 bit
	rcall	JTShiftDR0 //pr r16 r17 r18 r19 pc r20 p r21 c r22 r10 r12 r13 r14 r15
	ret

// JTag functions  IR=C Reset
//=============================================================================
//=============================================================================
// Jtag Programming

JTProgDisable:
	ldi		r16,0
	ldi		r17,0
	rjmp	JPEoff
JTProgEnable:
	ldi		r16,0x70
	ldi		r17,0xA3
JPEoff:
	ldi		r21,4
	rcall	JTShiftIR //pc r21 c r10 r12 r13 r14 r15 r20 r22
	ldi		r20,0x10
	rcall	JTShiftDR0 //pr r16 r17 r18 r19 pc r20 p r21 c r22 r10 r12 r13 r14 r15
	ret

// IR=4 Programming Enable
//---------------------------
// IR=5 Programming Commands

JTProgLLA:
	ldi		r17,JTPI_LLA
	mov		r16,r9
	rjmp	JTProgIR5

JTProgLHA:
	ldi		r17,JTPI_LHA
	mov		r16,r8
	rjmp	JTProgIR5

#ifdef M256
JTProgLEA:
	sbrs	r7,7 //0x80
	ret
	ldi		r17,JTPI_LEA
	mov		r16,r7
	andi	r16,0x7F
	rjmp	JTProgIR5
#endif

JTProgLHB:
	ldi		r17,JTPI_LHB
	rjmp	JTProgIR5

JTProgLLB:
	ldi		r17,JTPI_LLB
	rjmp	JTProgIR5

/*
JTWritePage:
	ldi		r17,JTPI_WLB | 1
	rcall	JTProgInst
	ldi		r17,JTPI_WLB
	rcall	JTProgInst
JWPn:
	ldi		r17,JTPI_WLB | 1
	rcall	JTProgInst
	ori		r17,2
	breq	JWPn //XXX timeout ???
	ret*/

JTProgWB:
	mov		r11,r17 //33 37 3B
	rcall	JTProgInst
	mov		r17,r11
	andi	r17,0xFD //31 35 39
	rcall	JTProgInst
	mov		r17,r11 //?
	rcall	JTProgInst //?
JPWp:
	mov		r17,r11
	rcall	JTProgInst
	andi	r17,2
	breq	JPWp //XXX timeout ?
	ret

JTProgLatch:
	ldi		r17,0x37
	rcall	JTProgInst
	ldi		r17,0x77 //PageLoad
	rcall	JTProgInst
	ldi		r17,0x37
	rcall	JTProgInst
	ret

JTProgRead:
//	mov		r11,r17
	push	r17
	rcall	JTProgInst
	pop		r17
//	mov		r17,r11
	ori		r17,1 //RD
	rcall	JTProgInst
	ret

// IR=5 Programming Commands
//---------------------------
// IR=5

JTProgInst: //p r17 c r16 r20 r21
	ldi		r16,0
	rjmp	JTProgIR5

JTProgCommand: //p r16 c r17 r20 r21
	ldi		r17,JTPI_CMD
	
JTProgIR5: //r17=cmd r16=data c r20 r21
	ldi		r20,0xF
	ldi		r21,1 //Write
	ldi		r22,1 //1 idle == pulse XT1
	rcall	JTShiftDR //pr r16 r17 r18 r19 pc r20 c r22 p r21 c r10 r12 r13 r14 r15
	ret

//JTPollBsy:
//	ldi		r20,0xF
//	rcall	JTShiftDR0 //pr r16 r17 r18 r19 pc r20 p r21 c r22 r10 r12 r13 r14 r15
//	ret

// Jtag Programming
//=============================================================================
//=============================================================================
// AVR OCD IR=8&9

StopMcu:
	ldi		r21,8 //force break
	rcall	JTShiftIR //pc r21 c r10 r12 r13 r14 r15 r20 r22
	rcall	SetMcuStopped

	rcall	SaveContext

	rcall	JTReadBCR //r r16 r17 c r18 r19 r20 r21 r22 c r10 r12 r13 r14 r15
//	andi	r17,0xE0 //ClearBreakPoints
//	andi	r16,0x07
	andi	r17,0x80 //ClearBreakPoints
	ori		r17,0x40 //Set PC24
	andi	r16,0x07
	rcall	JTWriteBCR
	ret


DoSSWait:
	rcall	SetMcuRunning
	ldi		r21,9
	rcall	JTShiftIR //pc r21 c r10 r12 r13 r14 r15 r20 r22
WaitForBreak:
	clr		r5
DSSWn:
	rcall	JTReadCSR //r r16 r17 c r18 r19 r20 r21 r22 c r10 r12 r13 r14 r15
	andi	r16,CSR_BMASK
	cpi		r16,CSR_BREAK
	breq	DSSWr
	ldi		r16,4 //16us * 256 = 4096us
	rcall	DelayU
	dec		r5
	brne	DSSWn
	ldi		r21,8 //force break ??? will this ever execute ? hope not.
	rcall	JTShiftIR //pc r21 c r10 r12 r13 r14 r15 r20 r22
DSSWr:
//XXX	rcall	JTReadBCR //r r16 r17 c r18 r19 r20 r21 r22 c r10 r12 r13 r14 r15
//XXX spm ???	ori		r17,(1<<BCR_PC24)
//XXX	rcall	JTWriteBCR
	rcall	SetMcuStopped
	ret

// AVR OCD IR=8&9
//=============================================================================
// AVR OCD instructions executed via DR when IR=A

DoLDIr28:  //pc r17 c r16 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15
	ldi		r16,28
DoLDI: //r16 = r16 to r31 -- r17 = immediate
	rcall	InstrLSB
	swap	r17
	andi	r17,0x0F
	ori		r17,0xE0
	rjmp	DoInstruction //pr r16 r17 c r18 r19 r20 r21 r22 r10 r12 r13 r14 r15

//-------------------------------------

InstrLSB:
	bst		r16,4
	swap	r16
	andi	r16,0xF0
	mov		r18,r17
	andi	r18,0x0F
	or		r16,r18
	ret

//-------------------------------------

//DoMOVr_r28: //p r16 c r17 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15
//	ldi		r17,28
DoMOV: //r16=Rd r17=Rr
	rcall	InstrLSB
	swap	r17
	lsl		r17
	bld		r17,0
	andi	r17,3
	ori		r17,0x2C
	rjmp	DoInstruction //pr r16 r17 c r18 r19 r20 r21 r22 r10 r12 r13 r14 r15

//-------------------------------------

DoINr28: //pc r17 c r16 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15
	ldi		r16,28
DoIN: //r16=register r17=io addr
	ldi		r19,0xB0
DoIO:
	rcall	InstrLSB
	bld		r19,0
	swap	r17
	lsl		r17
	andi	r17,0x06
	or		r17,r19
	rjmp	DoInstruction //pr r16 r17 c r18 r19 r20 r21 r22 r10 r12 r13 r14 r15

//-------------------------------------

DoOUTr28: //pc r17 c r16 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15
	ldi		r16,28
DoOUT: //r17=io addr r16=register
	ldi		r19,0xB8
	rjmp	DoIO

DoINr28_outOCDR: //r r16 pc r17 c r16 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15
	rcall	DoINr28 //pc r17 c r16 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15
	lds		r17,ucOCDRAddress
	rcall	DoOUTr28 //pc r17 c r16 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15
	rcall	JTReadOCDR //r r16 c r17 r18 r19 r20 r21 r22 c r10 r12 r13 r14 r15
	rjmp	JTShiftIR_A //xx

//-------------------------------------

/*DoIJMPtoBoot: //XXX for SPM
	lds		r24,ulBootAddress
	lds		r25,ulBootAddress+1
	rcall	DoLDI_Z
	//DoOUT	EIND,xx for mega256x*/

DoIJMP:
	ldi		r17,0x94
	ldi		r16,0x09
	rjmp	DoInstruction //pr r16 r17 c r18 r19 r20 r21 r22 r10 r12 r13 r14 r15

//-------------------------------------

/*DoJMP: this seems to work on m162
	ldi		r17,0x94
	ldi		r16,0x0C
	rcall	DoInstruction //pr r16 r17 c r18 r19 r20 r21 r22 r10 r12 r13 r14 r15
	ldi		r17,0x94
	ldi		r16,0x0C
	rcall	DoInstruction //pr r16 r17 c r18 r19 r20 r21 r22 r10 r12 r13 r14 r15
	mov		r17,r25
	mov		r16,r24
	rjmp	DoInstruction //pr r16 r17 c r18 r19 r20 r21 r22 r10 r12 r13 r14 r15*/

//-------------------------------------

//THIS WILL CHANGE SREG......
DoAdiwZ1: //c r16 r17 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15
	ldi		r17,0x96
	ldi		r16,0x31
	rjmp	DoInstruction //pr r16 r17 c r18 r19 r20 r21 r22 r10 r12 r13 r14 r15

//-------------------------------------

DoNOP: //c r16 r17 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15
	ldi		r17,0x00
	ldi		r16,0x00
	rjmp	DoInstruction //pr r16 r17 c r18 r19 r20 r21 r22 r10 r12 r13 r14 r15

//-------------------------------------

DoLDI_Z: // r24:r25
	ldi		r16,30
	mov		r17,r24
	rcall	DoLDI
	ldi		r16,31
	mov		r17,r25
	rcall	DoLDI
	ret

//-------------------------------------

DoLDr28Zp: //c r16 r17 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15
	ldi		r17,0x91
	ldi		r16,0xC1
	rcall	DoInstruction //pr r16 r17 c r18 r19 r20 r21 r22 r10 r12 r13 r14 r15
//	rjmp	outOCDRr28

//-------------------------------------

//DoLDr28Z_outOCDRr28: BROKEN ?
//	rcall	DoLDr28Z //in r24r25
outOCDRr28:
	lds		r17,ucOCDRAddress
	rcall	DoOUTr28 //pc r17 c r16 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15
	rcall	JTReadOCDR //r r16 c r17 r18 r19 r20 r21 r22 c r10 r12 r13 r14 r15
	rjmp	JTShiftIR_A //xx

//-------------------------------------

DoLDr28Z:
	rcall	DoLDI_Z
	ldi		r17,0x81
	ldi		r16,0xC0
	rjmp	DoInstruction //pr r16 r17 c r18 r19 r20 r21 r22 r10 r12 r13 r14 r15

//-------------------------------------

DoSTZpr28: //pc r17 c r16 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15
	rcall	DoLDIr28
	ldi		r17,0x93
	ldi		r16,0xC1
	rjmp	DoInstruction //pr r16 r17 c r18 r19 r20 r21 r22 r10 r12 r13 r14 r15

//-------------------------------------

DoSTZr28: //r24r25 r17
	rcall	DoLDIr28  //pc r17 c r16 r18 r19 r20 r21 r22 r10 r12 r13 r14 r15
	rcall	DoLDI_Z
	ldi		r17,0x83
	ldi		r16,0xC0
	rjmp	DoInstruction //pr r16 r17 c r18 r19 r20 r21 r22 r10 r12 r13 r14 r15

//-------------------------------------

DoWDR:
	ldi		r17,0x95
	ldi		r16,0xA8
	rjmp	DoInstruction //pr r16 r17 c r18 r19 r20 r21 r22 r10 r12 r13 r14 r15

//-------------------------------------

DoST_RAMPZ: //r16
	lds		r17,ucRAMPZAddress
	tst		r17
	brne	DSRZ
	ret
DSRZ:	
	push	r17
DSSC:
	mov		r17,r16
	ldi		r16,27
	rcall	DoLDI //r27,[r16]

	ldi		r16,28
	pop		r17
	rcall	DoLDI //r28,[x]

	ldi		r16,29
	ldi		r17,0
	rcall	DoLDI //r29,0

	ldi		r17,0x83
	ldi		r16,0xB8 //st Y,r27
	rjmp	DoInstruction //pr r16 r17 c r18 r19 r20 r21 r22 r10 r12 r13 r14 r15

//-------------------------------------

/*DoST_SPMC: //r16
	lds		r17,ucSPMCAddress
	push	r17
	rjmp	DSSC*/

//-------------------------------------

/*DoSPM: //XXX Unimplemented for now...
	rcall	DoST_SPMC //r16
	rcall	JTSetBCR_SS //tep
	rcall	JTShiftIR_A //xx
	ldi		r17,0x95
	ldi		r16,0xE8  //spm
	rcall	DoInstruction //pr r16 r17 c r18 r19 r20 r21 r22 r10 r12 r13 r14 r15
	rcall	DoSSWait
	rcall	JTShiftIR_A //xx

	//wait for SPMEN = 0
	clr		r5
DSew:	
	lds		r24,ucSPMCAddress
	ldi		r25,0
	rcall	DoLDr28Z_outOCDRr28
	andi	r16,(1<<SPMEN)
	breq	DSr
	ldi		r16,4 //16uS //use a timer instead ?
	rcall	DelayU
	dec		r5
	brne	DSew
DSr:
	ret*/

// AVR OCD instructions executed via DR when IR=A
//=============================================================================
// AVR JTag OCD  IR=A  (Ireg + PC)

DoInstruction: //pr r16 r17 c r18 r19 r20 r21 r22 r10 r12 r13 r14 r15
	lds		r20,JTIR
	cpi		r20,0xA
	breq	DId
	rcall	JTShiftIR_A //c r10 r12 r13 r14 r15 r20 r21 r22 -- should never happen.
DId:
	ldi		r20,0x10
	ldi		r21,1 //write ?
	ldi		r22,1 //idle
	rcall	JTShiftDR //pr r16 r17 r18 r19 pc r20 r22 p r21 c r10 r12 r13 r14 r15
	ret

JTGetIrPC: //Ir = r18 r19  PC = r16 r17
	rcall	JTShiftIR_A //c r10 r12 r13 r14 r15 r20 r21 r22
	ldi		r20,0x20
	ldi		r21,0 //Read
	rcall	JTShiftDR0 //pr r16 r17 r18 r19 pc r20 p r21 c r22 r10 r12 r13 r14 r15
	ret

// AVR JTag OCD  IR=A  (Ireg + PC)
//=============================================================================
// AVR JTag OCD  IR=B  (OCD Registers)

JTSetBCR_24:
	ldi		r24,(1<<BCR_PC24)
	rjmp	JTSetBCR_SSe
JTSetBCR_SS:
	ldi		r24,(1<<BCR_EN_STEP)
JTSetBCR_SSe:
	rcall	JTReadBCR //r r16 r17 c r18 r19 r20 r21 r22 c r10 r12 r13 r14 r15
	andi	r17,0x9F
	or		r17,r24
	rcall	JTWriteBCR
	ret
/*
StoreCSRLow:
	rcall	JTReadCSR //r r16 r17 c r18 r19 r20 r21 r22 c r10 r12 r13 r14 r15
	sts		CSR_OLD,r16
	ret*/

EnableOCDR:
	rcall	JTReadCSR //r r16 r17 c r18 r19 r20 r21 r22 c r10 r12 r13 r14 r15
	ori		r17,(1<<CSR_EN_OCDR)
	rcall	JTWriteCSR
	ret

DisableOCDR:
	rcall	JTReadCSR //r r16 r17 c r18 r19 r20 r21 r22 c r10 r12 r13 r14 r15
	andi	r17,~(1<<CSR_EN_OCDR)
	andi	r16,~(1<<CSR_OCDR) //Clear OCDR Dirty
	rcall	JTWriteCSR
	ret

//Setting bits
//-------------------------------------
//Reading

/*JTReadPSB0:
	ldi		r18,0 //OCD 0 PSB0
	rjmp	JTReadOCD //r r16 r17 pc r18 c r19 r20 r21 r22 c r10 r12 r13 r14 r15
JTReadPSB1:
	ldi		r18,1 //OCD 1 PSB1
	rjmp	JTReadOCD //r r16 r17 pc r18 c r19 r20 r21 r22 c r10 r12 r13 r14 r15

JTReadBr1:
JTReadPDMSB:
	ldi		r18,2 //OCD 2 PDMSB
	rjmp	JTReadOCD //r r16 r17 pc r18 c r19 r20 r21 r22 c r10 r12 r13 r14 r15

JTReadBr2:
JTReadPDSB:
	ldi		r18,3 //OCD 3 PDSB
	rjmp	JTReadOCD //r r16 r17 pc r18 c r19 r20 r21 r22 c r10 r12 r13 r14 r15*/

JTReadBCR: //r r16 r17 c r18 r19 r20 r21 r22 c r10 r12 r13 r14 r15
	ldi		r18,8 //OCD 8 BCR
	rjmp	JTReadOCD //r r16 r17 pc r18 c r19 r20 r21 r22 c r10 r12 r13 r14 r15

JTReadBSR: //r r16 r17 c r18 r19 r20 r21 r22 c r10 r12 r13 r14 r15
	ldi		r18,9 //OCD 9 BSR
	rjmp	JTReadOCD //r r16 r17 pc r18 c r19 r20 r21 r22 c r10 r12 r13 r14 r15

JTReadOCDR: //r r16 c r17 r18 r19 r20 r21 r22 c r10 r12 r13 r14 r15
	ldi		r18,0xC //OCD C OCDR = hi8
	rcall	JTReadOCD //r r16 r17 pc r18 c r19 r20 r21 r22 c r10 r12 r13 r14 r15
	mov		r16,r17
	ret

JTReadCSR: //r r16 r17 c r18 r19 r20 r21 r22 c r10 r12 r13 r14 r15
	ldi		r18,0xD

// r18 address - returns r16 r17
JTReadOCD: //r r16 r17 pc r18 c r19 r20 r21 r22 c r10 r12 r13 r14 r15
	ldi		r21,0xB //OCD
	rcall	JTShiftIR //pc r21 c r10 r12 r13 r14 r15 r20 r22
	ldi		r20,5
	ldi		r21,1 //W
	mov		r16,r18
	rcall	JTShiftDR0 //pr r16 r17 r18 r19 pc r20 p r21 c r22 r10 r12 r13 r14 r15

	ldi		r20,21
	ldi		r21,0 //R
	rcall	JTShiftDR0 //pr r16 r17 r18 r19 pc r20 p r21 c r22 r10 r12 r13 r14 r15
	ret

//Reading
//-------------------------------------
//Writing

JTWritePSBsp: // r18 = 0 or 1
	ld		r16,Z+ //low
	ld		r17,Z+ //high
JTWritePSB: // r16 r17 r18
	push	r18
	rcall	JTWriteOCD //pc r16 r17 r18 c r19 r20 r21 r22 r10 r12 r13 r14 r15
	pop		r18
	ldi		r24,0x08 //(1<<BCR_EN_PSB0)
	tst		r18
	breq	JTWPz
	ldi		r24,0x04 //(1<<BCR_EN_PSB1)
JTWPz:
	rcall	JTReadBCR
	or		r17,r24
	rjmp	JTWriteBCR

JTWriteBr1: //JTWritePDMSB:
	lds		r16,Pbr1L
	lds		r17,Pbr1H
	ldi		r18,2 //OCD 2 PDMSB
	rjmp	JTWriteOCD

JTWriteBr2: //JTWritePDSB:
	lds		r16,Pbr2L
	lds		r17,Pbr2H
	ldi		r18,3 //OCD 3 PDSB
	rjmp	JTWriteOCD

JTWriteBCR:
	ldi		r18,8 //OCD 8 BCR
	rjmp	JTWriteOCD
JTWriteCSR:
	ldi		r18,0xD

JTWriteOCD: //pc r16 r17 r18 c r19 r20 r21 r22 r10 r12 r13 r14 r15
	ldi		r21,0xB //OCD
	rcall	JTShiftIR //pc r21 c r10 r12 r13 r14 r15 r20 r22
	ori		r18,0x10
	ldi		r20,21
	ldi		r21,1 //W
	rcall	JTShiftDR0 //pr r16 r17 r18 r19 pc r20 p r21 c r22 r10 r12 r13 r14 r15
	ret

// AVR JTag OCD  IR=B  (OCD Registers)
//=============================================================================
//=============================================================================
// JTag physical

JTDoReset: //c r10
	sbi		JPORT,JTMS
	rcall	JTPulseTCK //c r10
	rcall	JTPulseTCK
	rcall	JTPulseTCK
	rcall	JTPulseTCK
	rcall	JTPulseTCK //reset
	cbi		JPORT,JTMS
	rcall	JTPulseTCK //idle
	sbi		JPORT,JTMS
	rcall	JTPulseTCK //SelectDR
	ret

//-----------------
//From SelectDR

JTGotoShiftIR: //c r10
	sbi		JPORT,JTMS
	rcall	JTPulseTCK //SelectIR
JTGotoShiftDR: //c r10
	cbi		JPORT,JTMS
	rcall	JTPulseTCK //Capture
	rcall	JTPulseTCK //Shift
	ret

//-----------------
//From Exit1

JTGotoSelectDR: //pc r22 c r10   r22 = idle cycles (entry into idle counts as 1)
	rcall	JTPulseTCK // UpdateDR
	tst		r22
	breq	JTGSD
	cbi		JPORT,JTMS
JDInext:
	rcall	JTPulseTCK // Idle -- entry does not count as a clock	
	subi	r22,1
	brcc	JDInext //brne = entry counted (breaks debugging)   brcc = entry not counted
//----
	sbi		JPORT,JTMS
JTGSD:
	rcall	JTPulseTCK // SelectDR
	ret

/* OLD 20111126 working
JTGotoSelectDR: //pc r22 c r10   r22 = idle cycles (entry into idle counts as 1)
	tst		r22
	breq	JTGSD
	rcall	JTPulseTCK // Update
	cbi		JPORT,JTMS
JDInext:
	rcall	JTPulseTCK // Idle -- entry counts as 1 clock	
	subi	r22,1
	brcc	JDInext //brne = entry counted (breaks debugging)   brcc = entry not counted
//----
	sbi		JPORT,JTMS
	rjmp	JTGSDa
JTGSD:
	rcall	JTPulseTCK // Update
JTGSDa:
	rcall	JTPulseTCK // SelectDR
	ret*/

//-------------------------------------------------------------------

JTShiftIR_5: //c r10 r12 r13 r14 r15 r20 r21 r22
	ldi		r21,5
	rjmp	JTShiftIR
JTShiftIR_A: //c r10 r12 r13 r14 r15 r20 r21 r22
	ldi		r21,0xA //instr + PC
JTShiftIR: //pc r21 c r10 r12 r13 r14 r15 r20 r22
	sts		JTIR,r21
	mov		r15,r21
	ldi		r20,4 //bits
	ldi		r21,1 //W
	ldi		r22,0 //idle
	rcall	JTGotoShiftIR //c r10
	rcall	JTDoShift //c r10 r12 r13 r14  pc r15 r20 p r21
	rcall	JTGotoSelectDR //pc r22 c r10
	ret

//======================================

//r16 r17 r18 r19  Data
//r20 number of bits <= 32
//r21 0=Read 1=Write
//r22 idle cycles

JTShiftDR0: //pr r16 r17 r18 r19 pc r20 c r22 p r21 c r10 r12 r13 r14 r15
	ldi		r22,0 // 0 idle cycles
JTShiftDR:  //pr r16 r17 r18 r19 pc r20 r22 p r21 c r10 r12 r13 r14 r15
	rcall	JTGotoShiftDR //c r10
	mov		r15,r16
	rcall	JTDoShift //c r10 r12 r13 r14  pc r15 r20 p r21
	mov		r16,r14
	mov		r15,r17
	rcall	JTDoShift
	mov		r17,r14
	mov		r15,r18
	rcall	JTDoShift
	mov		r18,r14
	mov		r15,r19
	rcall	JTDoShift
	mov		r19,r14
	rjmp	JTGotoSelectDR //pc r22 c r10

//======================================

//r14 return value
//r15 input, shift 8 bits per call
//r20 bit count - decremented by 8, when <= 8 set TMS=1 on last bit.
//r21 0=Read 1=Write

JTDoShift: //c r10 r12 r13 r r14  pc r15 r20 p r21
	clr		r13
	inc		r13 //=1
	clr		r14 //out
	tst		r20 //DO NOT REMOVE
	brne	JDSfirst
	ret
JDSnext:
	rcall	JTPulseTCK //c r10
JDSfirst:
//----------------------
	in		r12,JPIN
	bst		r12,JTDO
	brtc	JDStc
	or		r14,r13 //out,bit
JDStc:
	sbrc	r21,0 //0=R 1=W
	bst		r15,0
	lsr		r15

	bld		r12,JTDI
	out		JPORT,r12
//----------------------
	dec		r20
	breq	JDSret
	lsl		r13
	brne	JDSnext
	rcall	JTPulseTCK //c r10
	ret
JDSret:

	sbrc	r21,3
	ret //Don't exit ShiftXR ?

	sbi		JPORT,JTMS
	
//======================================
//JTclk to frequency, based on the high pulse and 8MHz clock (JTclk = ~Pjclk)
//Pj  JT  clks  kHz  mkI AvrStudio
//FF = 0 =  5 = 800  921 (1000) this may or may not work...
//FE = 1 =  7 = 571  460 (500) recommended setting
//FD = 2 = 13 = 307  245 (200)
//FC = 3 = 19 = 210  175
//FB = 4 = 25 = 160  136
//FA = 5 = 31 = 129  111 (100)
//F9 = 6 = 37 = 108   94
//F8 = 7 = 43 =  93   81
//F3 = C = 73 =  54   49 (50)

JTPulseTCK: //c r10
	lds		r10,JTclk
	tst		r10
	brne	JPTda
	sbi		JPORT,JTCK
	nop
	rjmp	PC+1
	cbi		JPORT,JTCK
	ret

//----- 7 10 13 16 19 21
	//lds	r10,JTclk
JPTda:
	dec		r10
	brne	JPTda
//-----	

	sbi		JPORT,JTCK

//-----	7 13 19 25 31 37
	lds		r10,JTclk
JPTns:
	nop
	rjmp	PC+1
	dec		r10
	brne	JPTns
//-----	

	cbi		JPORT,JTCK

//----- 4 7 10 13 16 19
	lds		r10,JTclk
JPTc:
	dec		r10
	brne	JPTc
//-----	

	ret

// JTag physical
//=================================================================================================
//=================================================================================================

