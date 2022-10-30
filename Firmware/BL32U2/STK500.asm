//STK500 protocol handler
//This is free for personal or non-profit use, for commercial use contact me.
//Copyright Rikus Wessels 2011
//rikusw - gmail - com

//=======================================================================================
//ISP

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

//ISP
//=======================================================================================
//HVPP
#define CTRL_DDR DDRB
#define CTRL_PIN PINB
#define CTRLPORT PORTB

#define DATA_DDR DDRD
#define DATA_PIN PIND
#define DATAPORT PORTD

#define CTRL_RST 4
#define CTRL_12V 5
#define CTRL_XT1 6
#define CTRL_PWR 7

//HVPP Commands
#define PPC_CE	0x80
#define PPC_WFU	0x40
#define PPC_WL	0x20
#define PPC_WFL	0x10
#define PPC_WEE	0x11
#define PPC_RSC 0x08
#define PPC_RFU	0x04
#define PPC_RFL	0x02
#define PPC_REE	0x03

#define ppstack_lla ppstack+0x00
//#define ppstack_lha ppstack+0x01
//#define ppstack_lea ppstack+0x02

#define ppstack_llb ppstack+0x04
#define ppstack_lhb ppstack+0x05

#define ppstack_cmd ppstack+0x08

#define ppstack_np0 ppstack+0x0C //
#define ppstack_np1 ppstack+0x0D

//#define ppstack_wr0 ppstack+0x10
//#define ppstack_wr1 ppstack+0x11
//#define ppstack_wr2 ppstack+0x12
//#define ppstack_wr3 ppstack+0x13

//#define ppstack_rlb ppstack+0x14 //
//#define ppstack_rhb ppstack+0x15
//#define ppstack_rd2 ppstack+0x16
//#define ppstack_rd3 ppstack+0x17

#define ppstack_pl  ppstack+0x18

#define ppstack_ddr ppstack+0x19
//#define ppstack_prt ppstack+0x1A //
#define ppstack_bsy ppstack+0x1B

//HVPP
//=============================================================================
//HVSP

#define SDI 0 //out
#define SII 1 //out
#define SDO 2 //in - ddr
#define SCI 3 //out
#define SDDR  DDRD
#define SPIN  PIND
#define SPORT PORTD

//used for ATtiny24 44 84 prog_enable
//#define CTRL_DDR DDRB
//#define CTRL_PIN PINB
//#define CTRLPORT PORTB

#define SPC_CE     0x14
#define SPC_WFUSE  0x15
#define SPC_WLOCK  0x16
#define SPC_WFLASH 0x17
#define SPC_WEEP   0x18

#define SPC_RSIG   0x19
#define SPC_RFUSE  0x1A
#define SPC_RFLASH 0x1B
#define SPC_REEP   0x1C
#define SPC_ROSC   0x1D
#define SPC_RLOCK  0x1E

#define SPI_WFUSE  0x05
#define SPI_WLOCK  0x05
#define SPI_WRL    0x05
#define SPI_WRH    0x06
#define SPI_RSIG   0x0A
#define SPI_RFUSE  0x0B
#define SPI_ROSC   0x0F
#define SPI_RLOCK  0x10

#define spstack_cmd spstack
#define spstack_lla spstack+1
#define spstack_lha spstack+2
#define spstack_llb spstack+3
#define spstack_lhb spstack+4
#define spstack_rlb spstack+8
#define spstack_rhb spstack+9
#define spstack_plh spstack+0x11
#define spstack_pll spstack+0x12
#define spstack_orm spstack+0x13
#define spstack_ddr spstack+0x1F

//HVSP
//=============================================================================

PMIjt:
//Misc
.db 0x00,0x08
.db PMIs00 - PMIij, PMIs01 - PMIij
.db PMIs02 - PMIij, PMIs03 - PMIij
.db PMIs04 - PMIij, PMIs05 - PMIij
.db PMIs06 - PMIij, PMIs07 - PMIij

//ISP
.db 0x10,0x2E
.db PMIs10 - PMIij, PMIs11 - PMIij
.db PMIs12 - PMIij, PMIs13 - PMIij
.db PMIs14 - PMIij, PMIs15 - PMIij
.db PMIs16 - PMIij, PMIs17 - PMIij
.db PMIs18 - PMIij, PMIs19 - PMIij
.db PMIs1A - PMIij, PMIs1B - PMIij
.db PMIs1C - PMIij, PMIs1D - PMIij
.db PMIs1E - PMIij, PMIs1F - PMIij //XXX

//HVPP
.db PMIs20 - PMIij, PMIs21 - PMIij
.db PMIs22 - PMIij, PMIs23 - PMIij
.db PMIs24 - PMIij, PMIs25 - PMIij
.db PMIs26 - PMIij, PMIs27 - PMIij
.db PMIs28 - PMIij, PMIs29 - PMIij
.db PMIs2A - PMIij, PMIs2B - PMIij
.db PMIs2C - PMIij, PMIs2D - PMIij
.db PMIs2E - PMIij, PMIs2F - PMIij //XXX

//HVSP
.db PMIs30 - PMIij, PMIs31 - PMIij
.db PMIs32 - PMIij, PMIs33 - PMIij
.db PMIs34 - PMIij, PMIs35 - PMIij
.db PMIs36 - PMIij, PMIs37 - PMIij
.db PMIs38 - PMIij, PMIs39 - PMIij
.db PMIs3A - PMIij, PMIs3B - PMIij
.db PMIs3C - PMIij, PMIs3D - PMIij

//SPI
.db	0xE0,0x04
.db	PMIsF0 - PMIij, PMIsF1 - PMIij
.db	PMIsF2 - PMIij, PMIsF3 - PMIij
.db 0,0

PutMsgISP: //X is getc and Y is putc buffer
	ld		r16,X+
	ldi		r17,PMIij-PMIjt
	rcall	DoSwitch

PMIij:
PMIs00:
PMIs1E:
PMIs1F:
PMIs2E:
PMIs2F:
PMIs3D:
	ldi		r16,STATUS_CMD_UNKNOWN
	rjmp	PMIretr16

PMIs04: //CMD_SET_DEVICE_PARAMETERS
PMIs05: //CMD_OSCCAL
PMIs07: //CMD_FIRMWARE_UPGRADE
PMIfail:
	ldi		r16,STATUS_CMD_FAILED
PMIretr16:
	st		Y+,r16
	ret

//=============================================================================
//Misc

PMIs01: //CMD_SIGN_ON
	rjmp	SendSignOn
PMIs02: //CMD_SET_PARAMETER
	ld		r24,X
	rcall	SetParameter
	andi	r24,0xFE
	cpi		r24,0x96 //+0x97
	brne	PMIs02ret
	rcall	SetupEClk
PMIs02ret:
	ret
PMIs03: //CMD_GET_PARAMETER
	rjmp	GetParameter
PMIs06: //CMD_LOAD_ADDRESS
	rcall	SetAddress
	rjmp	PMIok

//Misc
//=============================================================================
//ISP

PMIs10: //CMD_ENTER_PROGMODE_ISP
	rcall	IspEnterProg
	rjmp	PMIretr16
PMIs11: //CMD_LEAVE_PROGMODE_ISP
	ld		r16,X+
	rcall	Delay
	rcall	SpiOff
	cbi		RSTDDR,RSTBIT //reset HiZ
	cbi		RSTPORT,RSTBIT//reset off
	ld		r16,X+
	rcall	Delay
	rjmp	PMIok

PMIs12: //CMD_CHIP_ERASE_ISP
	adiw	r26,2
//	ldi		r19,0
	rcall	Isp_Cmd_getc
	sbiw	r26,6
	ld		r16,X+ //eraseDelay
	ld		r17,X+ //pollMethod 0=delay 1=rdy/bsy
	tst		r17
	breq	PM12delay
	rcall	RdyBsy
	rjmp	PMIok
	PM12delay:
	rcall	Delay
	rjmp	PMIok

PMIs13: //CMD_PROGRAM_FLASH_ISP
	rjmp	ProgFlashIsp
PMIs14: //CMD_READ_FLASH_ISP
	rjmp	ReadFlashIsp
PMIs15: //CMD_PROGRAM_EEPROM_ISP
	rjmp	ProgEepISP
PMIs16: //CMD_READ_EEPROM_ISP
	rjmp	ReadEepISP

PMIs17: //CMD_PROGRAM_FUSE_ISP
PMIs19: //CMD_PROGRAM_LOCK_ISP
//	ldi		r19,0
	rcall	Isp_Cmd_getc
	st		Y+,rnull
	rjmp	PMIok

PMIs18: //CMD_READ_FUSE_ISP
PMIs1A: //CMD_READ_LOCK_ISP
PMIs1B: //CMD_READ_SIGNATURE_ISP
PMIs1C: //CMD_READ_OSCCAL_ISP
	ld		r19,X+
	rcall	Isp_Cmd_getc
	st		Y+,rnull
	st		Y+,r15
	rjmp	PMIok

PMIs1D: //CMD_SPI_MULTI -- seems not to be used ??? except by AVRDude
	rcall	Spi_Multi
	rjmp	PMIok

//ISP
//=============================================================================
//SPI

PMIsF0: //spi on
	rcall	SetupSpiPort
	rcall	SetupSpiClk
	rjmp	PMIok
PMIsF1: //spi off
	rcall	SpiOff
	rjmp	PMIok
PMIsF2: //spi pulse
	rcall	PulseSCK
PMIsF3:
	rjmp	PMIok

//SPI
//=============================================================================
//HVPP

PMIs20: //CMD_ENTER_PROGMODE_PP
	rjmp	EnterPMPP
PMIs21: //CMD_LEAVE_PROGMODE_PP
	rjmp	LeavePMPP
PMIs23: //CMD_PROGRAM_FLASH_PP
	rjmp	WriteFlashPP
PMIs24: //CMD_READ_FLASH_PP
	rjmp 	ReadFlashPP
PMIs25: //CMD_PROGRAM_EEPROM_PP
	rjmp	WriteEepromPP
PMIs26: //CMD_READ_EEPROM_PP
	rjmp 	ReadEepPP

//-----------------

PMIs22: //CMD_CHIP_ERASE_PP
	ldi		r16,PPC_CE
	rcall	SetCommand
	ldi		r18,0
	rjmp	PMIs27b

PMIs29: //CMD_PROGRAM_LOCK_PP
	ldi		r16,PPC_WL
	ldi		r18,0
	adiw	r26,1
	rjmp	PMIs27a

PMIs27: //CMD_PROGRAM_FUSE_PP
	ldi		r16,PPC_WFU
	ld		r18,X+ //0,1,2
	andi	r18,3
PMIs27a:
	rcall	SetCommand
	rcall	LoadLowByte

PMIs27b: //--------Write
	rcall	LoadZppo
	ldd		r16,Z+0x10
	out		CTRLPORT,r16
	ld		r16,X+ //pulsewidth
	inc		r16 // t2313 fuse programming fix
	rcall	Delay0
	ldd		r16,Z+0x0C
	out		CTRLPORT,r16
	rcall	PollRdyG
	st		Y+,r16
	ret

//-----------------

PMIs2A: //CMD_READ_LOCK_PP
	ldi		r19,3
	rjmp	PMIs28a

PMIs28: //CMD_READ_FUSE_PP
	ld		r19,X+ //0,1,2
PMIs28a:
	ldi		r16,PPC_RFU
	rcall	SetCommand
	ldi		r18,4   // Convert
	sub		r18,r19 // 0 1 2 3
	andi	r18,3   // 0 3 2 1

PMIs28b: //--------Read
	st		Y+,rnull
	rcall	ReadDataO
	rcall	SetDataOut
	ret
	
PMIs2B: //CMD_READ_SIGNATURE_PP
	ldi		r18,0
PMIs2Ba:
	ldi		r16,PPC_RSC
	rcall	SetCommand
	lds		r17,ppstack_lla //LoadLowAddress lla
	ld		r16,X+
	rcall	LoadCtrlData
	rjmp	PMIs28b

PMIs2C: //CMD_READ_OSCCAL_PP
	ldi		r18,1 //3 according to stk500fw
	rjmp	PMIs2Ba

//-----------------

PMIs2D: //CMD_SET_CONTROL_STACK
	ldi		r16,32
	ldi		r30,lo8(ppstack)
	ldi		r31,hi8(ppstack)
Next2D:
	ld		r17,X+
	st		Z+,r17
	dec		r16
	brne	Next2D
	rjmp	PMIok

//HVPP
//=============================================================================
//HVSP

PMIs30: //CMD_ENTER_PROGMODE_HVSP
	rcall	EnterPMSP
	rjmp	HVSP_OK

PMIs31: //CMD_LEAVE_PROGMODE_HVSP
	rcall	LeavePMSP
	rjmp	HVSP_OK

PMIs32: //CMD_CHIP_ERASE_HVSP
	ldi		r18,SPC_CE //--0x1C8
	rcall	HVSPSetCommand // p r18 c r16 r17 r19
	ldi		r16,00
	rcall	HVSPwrl //pc r16 c r17 r18 r19 Z

	//ld		r16,X+ //pollTimeout
	rcall	HVSPpollXp  // c r16 r17 //0x71c  HVSP rdy/bsy
	brcc	PMIs32z
	rjmp	HVSPr16 //return tout
PMIs32z:
	ld		r16,X+ //eraseTime
	rcall	Delay //Delay0

	ldi		r16,0 //--HVSP_send_nop--
	rcall	HVSPsc // pc r16 c r17 r19
	rjmp	HVSP_OK

PMIs33: //CMD_PROGRAM_FLASH_HVSP
	rcall	WriteFlashSP
	rjmp	HVSPr16

PMIs34: //CMD_READ_FLASH_HVSP
	ldi		r18,SPC_RFLASH
	rcall	HVSPSetCommand // p r18 c r16 r17 r19
	rcall	LoadAddressSP // c r16 r17 r19 r r24 r25 Z
	st		Y+,rnull
PMIs34n:
	rcall	ReadLow //c r16 r17 r18 r19
	rcall	ReadHigh //c r16 r17 r18 r19
	rcall	IncAddressSP // c r16 r17 r18 r19 Z
	sbiw	r24,2
	brne	PMIs34n
	rjmp	HVSP_OK

PMIs35: //CMD_PROGRAM_EEPROM_HVSP
	rcall	WriteEepromSP
	rjmp	HVSPr16

PMIs36: //CMD_READ_EEPROM_HVSP
	ldi		r18,SPC_REEP
	rcall	HVSPSetCommand // p r18 c r16 r17 r19
	rcall	LoadAddressSP // c r16 r17 r19 r r24 r25 Z
	st		Y+,rnull
PMIs36n:
	rcall	ReadLow //c r16 r17 r18 r19
	rcall	IncAddressSP // c r16 r17 r18 r19 Z
	sbiw	r24,1
	brne	PMIs36n
	rjmp	HVSP_OK

PMIs37: //CMD_PROGRAM_FUSE_HVSP
	ldi		r18,SPC_WFUSE
	rcall	HVSPSetCommand // p r18 c r16 r17 r19
	ld		r18,X+
	andi	r18,3
	subi	r18,-SPI_WFUSE //+5 -- 5 6 7 xx8xx
	//check
PMIs37a:
	ld		r16,X+
	rcall	HVSPWrite //pc r16 c r17 p r18 c r19 Z
	rcall	HVSPpollXp  // c r16 r17 //0x71c  HVSP rdy/bsy
	rjmp	HVSPr16

PMIs38: //CMD_READ_FUSE_HVSP
	ldi		r18,SPC_RFUSE //--0x1CE
	rcall	HVSPSetCommand // p r18 c r16 r17 r19
	ld		r18,X+
	andi	r18,3
	subi	r18,-SPI_RFUSE //--0x1BF B
	rcall	HVSPRead //c r16 r17 p r18 c r19 Z
	rjmp	HVSPr_OK

PMIs39: //CMD_PROGRAM_LOCK_HVSP
	ldi		r18,SPC_WLOCK
	rcall	HVSPSetCommand // p r18 c r16 r17 r19
	adiw	r26,1
	ldi		r18,SPI_WLOCK
	rjmp	PMIs37a

PMIs3A: //CMD_READ_LOCK_HVSP
	ldi		r18,SPC_RLOCK //--0x1D2 rlck
	rcall	HVSPSetCommand // p r18 c r16 r17 r19
	ldi		r18,SPI_RLOCK //--0x1C4 78
	rcall	HVSPRead //c r16 r17 p r18 c r19 Z
	rjmp	HVSPr_OK

PMIs3B: //CMD_READ_SIGNATURE_HVSP
	ldi		r18,SPC_RSIG  //--0x1CD rsig
	rcall	HVSPSetCommand // p r18 c r16 r17 r19
	rcall	HVSPlla
	ldi		r18,SPI_RSIG //--0x1BE 68
	rcall	HVSPRead //c r16 r17 p r18 c r19 Z
	rjmp	HVSPr_OK

PMIs3C: //CMD_READ_OSCCAL_HVSP
	ldi		r18,SPC_ROSC //--0x1D1 rosc    spstack_rosc--
	rcall	HVSPSetCommand // p r18 c r16 r17 r19
	rcall	HVSPlla
	ldi		r18,SPI_ROSC //--0x1C3 78 oscc
	rcall	HVSPRead //c r16 r17 p r18 c r19 Z


HVSPr_OK:
	st		Y+,rnull
HVSPr16:
	st		Y+,r16
	ret

//=============================================================================

PMIsta:
	sts		address  ,r30
	sts		address+1,r31
PMIok:
HVSP_OK:
	st		Y+,rnull //STATUS_CMD_OK
	ret

//END PutMsgISP
//=============================================================================
//=============================================================================
//ISP

SetupEClk: //for Timer0 OC0A
	ldi		r16,0
	out		TCNT0,r16
	lds		r16,oscc
	out		OCR0A,r16

	ldi		r17,0xFF
	lds		r16,oscp
	andi	r16,7
	brne	secon
	ldi		r17,0
secon:
	ori		r16,(1<<WGM02)
	out		TCCR0B,r16

	andi	r17,(1<<COM0A0)|(1<<WGM01)|(1<<WGM00)
	out		TCCR0A,r17
	cbi		DDRB,7 //OC0A=B7
	breq	secoff
	sbi		DDRB,7 //OC0A=B7
secoff:
	ret

//-------------------------------------

SetResetActive:
	lds		r16,extrst //should be (1=AVR rst0) or (0=AT89 rst1)
	tst		r16
	breq	SRAz
	cbi		RSTPORT,RSTBIT //AVR
	rjmp	SRAr
SRAz:
	sbi		RSTPORT,RSTBIT //AT89
SRAr:
	sbi		RSTDDR,RSTBIT
	ret

//-------------------------------------

/*
SetResetActive:
	ldi		r16,1
SetReset: //r16=1 is active
	lds		r17,extrst //should be (1=AVR rst0) or (0=AT89 rst1)
	tst		r17
	breq	SRz
	ldi		r17,1 // just make sure anyway
	eor		r16,r17
SRz:
	tst		r16
	breq	SRzz
	sbi		RSTPORT,RSTBIT
	sbi		RSTDDR,RSTBIT
	ret
SRzz:
	cbi		RSTPORT,RSTBIT
	sbi		RSTDDR,RSTBIT
	ret
*/

//-------------------------------------

SetupSpiPort:
	//setup spi pins
	cbi		SPIPORT,SCKBIT
	cbi		SPIPORT,MOSIBIT
	cbi		SPIPORT,MISOBIT
	in		r16,SPIDDR
	ori		r16,(1<<SCKBIT)|(1<<MOSIBIT)
	andi	r16,~(1<<MISOBIT)
	out		SPIDDR,r16
	ret

SetupSpiClk:
	//setup hard/soft spi
	lds		r16,sckdur
	cpi		r16,4
	brcc	SSsoft
	andi	r16,0x03 //SPR0/1
	ori		r16,(1<<SPE)|(1<<MSTR)
	out		SPCR,r16
	in		r16,SPSR
	andi	r16,~(1<<SPI2X)
	out		SPSR,r16
	ret
SSsoft:
	out		SPCR,rnull
	ret

SpiOff:
	out		SPCR,rnull
	in		r16,SPIDDR
	andi	r16,~((1<<SCKBIT)|(1<<MOSIBIT))
	out		SPIDDR,r16
	ret

//-------------------------------------

.def rspi = r1

Spi_Delay:
	lds		rspi,sckdur
	rjmp	SDw
SDnext:
	rjmp	PC+1 //delay 2 clocks
SDw:
	rjmp	PC+1
	rjmp	PC+1
	rjmp	PC+1
	dec		rspi
	tst		rspi // don't - remove loop length is critical - 12 clks
	brne	SDnext
	ret

//-------------------------------------

Spi_Tx:		//r16 in - r16 out
	push	r17
	lds		r17,sckdur
	cpi		r17,4
	brcc	STsoft //if(sckdur < 4)

	out		SPDR,r16
Spi_TxW:
	in		r16,SPSR
	sbrs	r16,SPIF
	rjmp	Spi_TxW
	in		r16,SPDR
	rjmp	STret

STsoft:
	ldi		r17,8
STnext:
	lsl		r16 //mosi
	brcc	STmo0
	sbi		SPIPORT,MOSIBIT
	rjmp	STmo1
STmo0:
	cbi		SPIPORT,MOSIBIT
STmo1:
	rcall	Spi_Delay
	sbic	SPIPIN,MISOBIT //miso
	ori		r16,1 //inc r16
	sbi		SPIPORT,SCKBIT //clk hi
	rcall	Spi_Delay
	cbi		SPIPORT,SCKBIT //clk lo
	dec		r17
	brne	STnext //while(r17)
STret:
	pop		r17
	ret

//-------------------------------------

Isp_Cmd_Tx:
	rcall	Spi_Tx
	inc		r18
	cpse	r19,r18
	ret
	mov		r15,r16
	ret

Isp_Cmd: 	//const r19-23 (const U8 poll, U8 a, U8 b, U8 c, U8 d) --r15 r16 r18--
	clr		r15
	ldi		r18,0
	mov		r16,r20
	rcall	Isp_Cmd_Tx
	mov		r16,r21
	rcall	Isp_Cmd_Tx
	mov		r16,r22
	rcall	Isp_Cmd_Tx
	mov		r16,r23
	rjmp	Isp_Cmd_Tx
//	ret

Isp_Cmd_getc: // r15 r16 r18 r19
	clr		r15
	ldi		r18,0
	ld		r16,X+
	rcall	Isp_Cmd_Tx
	ld		r16,X+
	rcall	Isp_Cmd_Tx
	ld		r16,X+
	rcall	Isp_Cmd_Tx
	ld		r16,X+
	rjmp	Isp_Cmd_Tx
//	ret

//-------------------------------------

Spi_Multi:
	ld		r20,X+ //NumTx
	ld		r21,X+ //NumRx
	ld		r23,X+ //RxStart
	st		Y+,rnull //STATUS_CMD_OK
SMnext:
	or		r20,r21 //while(r20 || r21)
	breq	SMret

	tst		r20 //if(NumTx) { NumTx--; r15 = getc(); } else r15 = 0;
	breq	SMtxz
	dec		r20
	ld		r16,X+
	rjmp	SMtx
SMtxz:
	clr		r16
SMtx:
	rcall	Spi_Tx

	tst		r23 //if(RxStart) { RxStart--; continue; }
	breq	SMrx
	dec		r23
	rjmp	SMnext
SMrx:
	dec		r21 // NumRx--;
	st		Y+,r16 // putc(r15)
	rjmp	SMnext
SMret:
	ret

/*	while(NumTx || NumRx) {
		if(NumTx) {
			NumTx--;
			r = getc();
		}else{
			r = 0;
		}
		r = spi_tx(r);

		if(RxStart) {
			RxStart--;
			continue;
		}
		if(NumRx) {
			NumRx--;
			putc(r);
		}
	}
	return OK;*/

//-------------------------------------

PulseSCK:
	//SPI off
	out		SPCR,rnull

	//pulse sck
	ldi		r16,3 //ms
	rcall	Delay
	sbi		SPIPORT,SCKBIT
	rcall	Delay
	cbi		SPIPORT,SCKBIT
	rcall	Delay

	//SPI on
	rcall	SetupSpiClk
	ret

//-------------------------------------

Disable_dW:
	lds		r17,extrst //should be (1=AVR rst0) or (0=AT89 rst1)
	tst		r17
	brne	DdW
	ret
DdW:
	ldi		r16,0 // 16/1 == 16Mhz
	rcall	SetPrescaler

	ldi		r24,0x00
	ldi		r25,0xA0 //15.36mS -- 125kHz Clock dW = 1kHz

	cbi		RSTDDR,RSTBIT
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

	ldi		r16,2 //1mS
	rcall	Delay

//----------------------

DdFail:	
Ddret:
	ldi		r16,1 // 16/2 == 8Mhz
	rcall	SetPrescaler
	ret

//-------------------------------------

IspEnterProg:
	movw	r30,r26
	adiw	r26,7

	rcall	SetResetActive
	ldd		r16,Z+1 //stabDelay
	rcall	Delay

	//SPI on
	rcall	SetupSpiPort

	ldd		r16,Z+2 //cmdexeDelay1 //stabDelay
	rcall	Delay

	rcall	Disable_dW //SetResetInactive
	sbi		RSTPIN,RSTBIT
	sbi		RSTDDR,RSTBIT
	rcall	SetupSpiClk

	ldd		r16,Z+2 //cmdexeDelay1 //stabDelay
	rcall	Delay

	rcall	SetResetActive
	ldd		r16,Z+2 //cmdexeDelay
	rcall	Delay

	ldd		r10,Z+3 //synchLoops

IEPnext:
	ldd		r19,Z+6 //pollIndex
	rcall	Isp_Cmd_getc
	sbiw	r26,4

	tst		r19 // no polling
	breq	IEPret

	ldd		r17,Z+5 //pollValue
	cp		r15,r17
	breq	IEPret

	rcall	PulseSCK

	dec		r10
	brne	IEPnext
	ldi		r16,STATUS_CMD_FAILED
	ret

IEPret:
	ldi		r16,STATUS_CMD_OK
	ret

/*
      <IspEnterProgMode>
      0 <timeout>200</timeout> Not used ???
      1 <stabDelay>100</stabDelay>
      2 <cmdexeDelay>25</cmdexeDelay>
      3 <synchLoops>32</synchLoops>
      4 <byteDelay>0</byteDelay> //?????
      6 <pollIndex>3</pollIndex>
      5 <pollValue>0x53</pollValue>
      </IspEnterProgMode>
*/

//-------------------------------------
// Flash and eeprom ISP programming code

ISPIncAddress:
	adiw	r30,1 //word address
	brcc	IIAret

	//this will only happen at the end of a page
	//unless wrong parameters are passed from the PC
	lds		r16,address+2
	inc		r16
	sts		address+2,r16
	lds		r16,address+3
	ori		r16,0x40 //enable LoadEA
	sts		address+3,r16

IIAret:
	ret

//-------------------------------------

ProgFlashIsp:
	rcall	LoadEA
	rcall	SetupProg
PMIwfl:
	clr		hbit
	rcall	WriteByte
	ldi		r16,0x08
	mov		hbit,r16
	rcall	WriteByte
	rcall	ISPIncAddress
	sbiw	r24,2
	brne	PMIwfl
	rcall	WritePage
//	rjmp	PMIsta
	sts		address  ,r30
	sts		address+1,r31
	st		Y+,r16
	ret

//-------------------------------------

ReadFlashIsp:
	rcall	LoadEA
	rcall	SetupRWFlEep
	ldi		r19,4 //poll=4
	ld		r0,X+ //0x20 -- read cmd
	st		Y+,rnull //STATUS_CMD_OK
  PMIs14next:
	mov		r20,r0
	mov		r21,r31
	mov		r22,r30
	ldi		r23,0
	rcall	Isp_Cmd
	st		Y+,r15
	ori		r20,0x08 //0x20 -> 0x28
	rcall	Isp_Cmd
	st		Y+,r15
	rcall	ISPIncAddress
	sbiw	r24,2
	brne	PMIs14next
	rjmp	PMIsta

//-------------------------------------

ProgEepISP:
	rcall	SetupProg
PMIwee:
	clr		hbit
	rcall	WriteByte
	adiw	r30,1
	sbiw	r24,1
	brne	PMIwee
	rcall	WritePage
	rjmp	PMIsta

//-------------------------------------

ReadEepISP:
	rcall	SetupRWFlEep
	ld		r0,X+ //0xA0
	ldi		r19,4
	st		Y+,rnull //STATUS_CMD_OK
PMIs16next:
	mov		r20,r0
	mov		r21,r31
	mov		r22,r30
	ldi		r23,0
	rcall	Isp_Cmd
	st		Y+,r15
	adiw	r30,1
	sbiw	r24,1
	brne	PMIs16next
	rjmp	PMIsta

//-------------------------------------

// SetupProg
.def mode  = r22
.def dlay  = r9
.def cmdwr = r23
.def cmdwp = r10
.def cmdrd = r11
//.def poll1 = rxxx12
//.def poll2 = r13
.def dlycnt = r13

.def hbit  = r14

// SetupRWFlEep
// r25:r24 = NumBytes
// r31:r30 = Address lo16

SetupProg:
	// save pgwr address
	rcall	SetupRWFlEep
	ld		mode,X+
	ld		dlay,X+
	ld		cmdwr,X+
	ld		cmdwp,X+
	ld		cmdrd,X+
	adiw	r26,2
//	ld		poll1,X+
//	ld		poll2,X+
	ret

//-------------------------------------

LoadEA:
	lds		r16,address+3
	sbrs	r16,7 //0x80
	ret
	sbrs	r16,6 //0x40
	ret
	cbr		r16,6
	sts		address+3,r16
	//------------
//	ldi		r19,0 //??
	ldi		r20,0x4D //wr ea --only used for mega256x
	ldi		r21,0x00
	lds		r22,address+2 //mode  clobber r22
	ldi		r23,0x00      //cmdwr clobber r23
	rjmp	Isp_Cmd

//-------------------------------------

PollValue:
	sbiw	r26,1
	ld		r17,X+
	cpi		r17,0xFF //could scan for a non FF value...
	brne	PVst
	mov		r16,dlay
	rcall	Delay
	ldi		r16,STATUS_CMD_OK
	ret
PVst:
	mov		dlycnt,dlay
PVnext:
	mov		r16,cmdrd
	or		r16,hbit
	rcall	Spi_Tx
	mov		r16,r31
	rcall	Spi_Tx
	mov		r16,r30
	rcall	Spi_Tx
	clr		r16
	rcall	Spi_Tx //DON'T use Isp_Cmd here, it will overwrite r22+r23

	cp		r16,r17
	ldi		r16,STATUS_CMD_OK
	breq	PVret

	dec		dlycnt
	ldi		r16,STATUS_CMD_TOUT
	breq	PVret

	ldi		r16,1
	rcall	Delay
	rjmp	PVnext
PVret:
	ret

//-------------------------------------

RdyBsy:
	mov		dlycnt,dlay
RBnext:
	ldi		r16,0xF0
	rcall	Spi_Tx
	clr		r16
	rcall	Spi_Tx
	clr		r16
	rcall	Spi_Tx
	clr		r16
	rcall	Spi_Tx //DON'T use Isp_Cmd here is will overwrite r22+r23

	bst		r16,0
	ldi		r16,STATUS_CMD_OK
	brtc	RBret

	dec		dlycnt
	ldi		r16,STATUS_RDY_BSY_TOUT
	breq	RBret

	ldi		r16,1
	rcall	Delay
	rjmp	RBnext
RBret:
	ret

//-------------------------------------

WriteByte: //r15=cmd r16=byte
	mov		r16,cmdwr
	or		r16,hbit //0x00/0x08
	rcall	Spi_Tx
	mov		r16,r31
	rcall	Spi_Tx
	mov		r16,r30
	rcall	Spi_Tx
	ld		r16,X+
	rcall	Spi_Tx
	ldi		r16,STATUS_CMD_OK
WBd:
	;if( --timed delay-- )
	sbrs	mode,1
	rjmp	WBvp
	mov		r16,dlay
	rcall	Delay
	ldi		r16,STATUS_CMD_OK
WBvp:
	;if( --value polling-- )
	sbrs	mode,2
	rjmp	WBrb
	rcall	PollValue
WBrb:
	;if( --rdy/bsy-- ) eep only
	sbrs	mode,3
	rjmp	WBret
	rcall	RdyBsy
WBret:
	ret

//-------------------------------------

WritePage:
	;if( --write page-- )
	sbrs	mode,7
	rjmp	WPret
//	{
	mov		r16,cmdwp
	rcall	Spi_Tx
	lds		r16,address+1
	rcall	Spi_Tx
	lds		r16,address
	rcall	Spi_Tx
	clr		r16
	rcall	Spi_Tx
	ldi		r16,STATUS_CMD_FAILED

	;if( --p timed delay-- )
	sbrs	mode,4
	rjmp	WPvp
	mov		r16,dlay
	rcall	Delay
	ldi		r16,STATUS_CMD_OK
WPvp:
	;if( --p value polling-- )
	sbrs	mode,5
	rjmp	WPrb
	sbiw	r30,1 //....
	rcall	PollValue
	adiw	r30,1 //....
WPrb:
	;if( --p rdy/bsy-- ) eep only
	sbrs	mode,6
	rjmp	WPret
	rcall	RdyBsy
//	}
WPret:
	ret

//ISP
//=============================================================================
//HVPP

#define stabDelay		Z+0
#define progModeDelay	Z+1
#define latchCycles		Z+2
#define toggleVtg		Z+3
#define powerOffDelay	Z+4
#define resetDelayMs	Z+5
#define resetDelayUs	Z+6

EnterPMPP:
	movw	r30,r26
	rcall	SpiOff
	sts		oscp,rnull // EClk off
	rcall	SetupEClk

	//rst 5V + vtg on
	in		r16,PORTC
	andi	r16,0x0F //CTRL_RST CTRL_XT1 CTRL_PWR = 0
	ori		r16,(1<<CTRL_12V) //SHDN = 1 = 5V
	out		PORTC,r16
//	in		r16,DDRC
//	ori		r16,0xF0
	ldi		r16,0xF4 //20120818
	out		DDRC,r16
	
	//rst 0V
//	ldi		r16,1 //delay 1ms ? 100uS ?
//	rcall	Delay0
	ldi		r16,40 //160 uS
	rcall	DelayU
	sbi		PORTC,CTRL_RST

	ldd		r16,stabDelay //100ms
	rcall	Delay0

	// setup ports
	lds		r16,ppstack_ddr
	out		CTRL_DDR,r16
	out		CTRLPORT,rnull //ppstack_prt ?
	rcall	SetDataOutS

//if(toggleVtg)
	ldd		r16,toggleVtg
	tst		r16
	breq	EPnotv
//{
	//vtg off
	sbi		PORTC,CTRL_PWR

	ldd		r16,powerOffDelay
	rcall	Delay0

	//vtg on
	cbi		PORTC,CTRL_PWR

	ldd		r16,resetDelayMs //ignore uS, it is usually 0
	rcall	Delay0
//}
EPnotv:

	ldd		r16,latchCycles
EPnextl:
	rcall	PulseXT1
	dec		r16
	brne	EPnextl

	cbi		PORTC,CTRL_12V //enable 12V - for ST662A to reach 12V in time

	ldd		r16,stabDelay //100ms
	rcall	Delay0

	//rst 12V
	cbi		PORTC,CTRL_RST

	ldd		r16,stabDelay //100ms
	rcall	Delay0

	lds		r16,ppstack_np0 //HACK to make tiny2313 read sig correctly
	out		CTRLPORT,r16 //this also fixes the t2313 CE bug
	
//	ldd		r16,progModeDelay
	ldi		r16,1
	rcall	Delay0

	st		Y+,rnull //STATUS_CMD_OK
	ret

#undef stabDelay
#undef progModeDelay
#undef latchCycles
#undef toggleVtg
#undef powerOffDelay
#undef resetDelayMs
#undef resetDelayUs

#define stabDelay		Z+0
#define resetDelay		Z+1

LeavePMPP:
	movw	r30,r26

	sbi		PORTC,CTRL_12V //rst 5V
	sbi		PORTC,CTRL_RST //rst 0V

	ldd		r16,stabDelay
	rcall	Delay0

	out		CTRL_DDR,rnull
	out		CTRLPORT,rnull
	out		DATA_DDR,rnull
	out		DATAPORT,rnull

	ldd		r16,resetDelay
	rcall	Delay0

	//vtg off
//	in		r16,DDRC
//	andi	r16,0x0F
	ldi		r16,0x04 //20120818
	out		DDRC,r16
	out		PORTC,rnull

	ldd		r16,stabDelay //necessary ?
	rcall	Delay0

	st		Y+,rnull
	ret

#undef stabDelay
#undef resetDelay

//-------------------------------------

LoadAddressPP:
	ldi		r31,hi8(address+4)
	ldi		r30,lo8(address+4)
	ld		r16,-Z
	andi	r16,0x80
	brne	LAn
	sbiw	r30,1
LAn:
	ld		r16,-Z
	ldd		r17,Z+4
	rcall	LoadCtrlData
	cpi		r30,lo8(address)
	brne	LAn
	ret

IncAddressPP:
	ldi		r31,hi8(address)
	ldi		r30,lo8(address)
IAn:
	ld		r16,Z
	subi	r16,0xFF //+1
	st		Z+,r16
	ldd		r17,Z+3 //ppstack_lla lha lea
	rcall	LoadCtrlData
	breq	IAn //from subi
	ret

//-------------------------------------

ReadFlashPP:
	ld		r25,X+
	ld		r24,X+
	ldi		r16,PPC_RFL
	rcall	SetCommand
	rcall	LoadAddressPP
	st		Y+,rnull
RFPPn:
	rcall	ReadData
	ldi		r18,1 //??stk500 use 3??
	rcall	ReadDataH
	rcall	SetDataOut
	rcall	IncAddressPP
	sbiw	r24,2
	brne	RFPPn
	st		Y+,rnull
	ret

ReadEepPP:
	ld		r25,X+
	ld		r24,X+
	ldi		r16,PPC_REE
	rcall	SetCommand
	rcall	LoadAddressPP
	st		Y+,rnull
REPPn:
	rcall	ReadData
	rcall	SetDataOut
	rcall	IncAddressPP
	sbiw	r24,1
	brne	REPPn
	st		Y+,rnull
	ret

//-------------------------------------

WriteFlashPP:
	set
	ldi		r16,PPC_WFL
	rjmp	WFP
WriteEepromPP:
	clt
	ldi		r16,PPC_WEE
WFP:
	ld		r25,X+ //sizeH
	ld		r24,X+ //sizeL
	ld		r21,X+ //mode
	ld		r20,X+ //pollTO
	rcall	SetCommand
	rcall	LoadAddressPP
	sbrs	r21,0
	rjmp	WFPwfb
	//------WriteFlashPages-------
	//ww mov		r23,r25
	movw	r22,r24

	//r25:r24 = 1 << (r21 & 7); == pagesize
//------
	push	r21
	lsr		r21
	andi	r21,7
	ldi		r25,1
	ldi		r24,0
	breq	WFPl  //256
	ldi		r25,0
	ldi		r24,1
WFPlsl:
	dec		r21
	brmi	WFPl
	lsl		r24
	rol		r25
	rjmp	WFPlsl
WFPl:
	pop		r21
//------

WFPn:
	sub		r22,r24
	sbc		r23,r25
	brcs	WFProk
	push	r24
	push	r25
	//------------------
WFPwfp:
	rcall	LoadLowByte
	sbiw	r24,1

	brtc	wfph
	rcall	LoadHighByte
	sbiw	r24,1
wfph:
	rcall	LatchData

//if(pagefull)
	mov		r16,r24
	or		r16,r25
	brne	WFPnf
//{
	//if(wp)
	sbrs	r21,7
	rjmp	WFPpp
	//{
	rcall	PPWritePage
	rcall	PollRdy
	brcs	WFPr //tout
	//}
WFPpp:
	rcall	IncAddressPP
	pop		r25
	pop		r24
	rjmp	WFPn
//}else{
WFPnf:
	rcall	IncAddressPP
	rjmp	WFPwfp
//}
	//------------------
	//------WriteFlashPages-------
	//------WriteFlashBytes-------
WFPwfb:
	rcall	LoadLowByte
	rcall	PPWriteLowByte
	rcall	PollRdy
	brcs	WFPr

	brtc	wfbh
	sbiw	r24,1
	rcall	LoadHighByte
	rcall	PPWriteHighByte
	rcall	PollRdy
	brcs	WFPr
wfbh:
	rcall	IncAddressPP
	sbiw	r24,1
	brne	WFPwfb
	//------WriteFlashBytes-------
WFProk:
	ldi		r16,STATUS_CMD_OK

//if(last page)
	sbrs	r21,6
	rjmp	WFPr
//{
	rcall	PollRdy
	brcs	WFPr
	ldi		r16,0
	rcall	SetCommand //--> nop
//}
WFPr:
	st		Y+,r16
	ret

//-------------------------------------

SetCommand: //const r16
	lds		r17,ppstack_cmd
	out		CTRLPORT,r17
	out		DATAPORT,r16

PulseXT1: //no flags affected
	sbi		PORTC,CTRL_XT1
	rjmp	PC+1
	nop
	cbi		PORTC,CTRL_XT1
	ret

LoadHighByte:
	lds		r17,ppstack_lhb
	rjmp	LLBa
LoadLowByte:
	lds		r17,ppstack_llb
LLBa:
	ld		r16,X+

LoadCtrlData: //no flags affected
	out		DATAPORT,r16
LoadCtrl:
	out		CTRLPORT,r17
	rjmp	PulseXT1

LatchData: //no flags affected
	lds		r17,ppstack_pl //PL
	out		CTRLPORT,r17
	rjmp	PC+1
	lds		r17,ppstack_np1
	out		CTRLPORT,r17
	ret

PPWritePage:
PPWriteLowByte:
	ldi		r18,0xC //ppstack_np0
	rjmp	PPWB
PPWriteHighByte:
	ldi		r18,0xD //ppstack_np1
PPWB:
	rcall	LoadZppo
	ldd		r17,Z+4
	out		CTRLPORT,r17
	jmp		PC+1
	jmp		PC+1
	ld		r17,Z
	out		CTRLPORT,r17
	ret

//----------

ReadData:
	ldi		r18,0
ReadDataO:
	out		DATA_DDR,rnull
	ldi		r17,0xFF
	out		DATAPORT,r17
ReadDataH:
	rcall	LoadZppo
	ldd		r16,Z+0x14 //ppstack_rlb
	out		CTRLPORT,r16
	rjmp	PC+1
	rjmp	PC+1
	in		r16,DATA_PIN
	st		Y+,r16
	ret

SetDataOut:
	ldd		r16,Z+0x0C //ppstack_np0
	out		CTRLPORT,r16
SetDataOutS:
	ldi		r16,0xFF
	out		DATAPORT,rnull
	out		DATA_DDR,r16
	ret

//---------------------

PollRdyG:
	ld		r20,X+
PollRdy:
	tst		r20
	breq	PRok

//-------------
	mov		r16,r20 // r16:r17 = r20 << 3
	ldi		r17,0
	ldi		r18,3
PRdn:
	dec		r18
	brmi	PRd
	lsl		r16
	rol		r17
	rjmp	PRdn
PRd:
//-------------
	lds		r19,ppstack_bsy // r18 = 1 << r19
	ldi		r18,1
PRmn:
	dec		r19 //convert rdy/bsy bitnr to bitmask
	brmi	PRm
	lsl		r18
	rjmp	PRmn
PRm:
//-------------


PRp:
//-------------
	ldi		r19,250 //125us
PRdelay:
	nop
	dec		r19
	brne	PRdelay
//-------------
	in		r19,CTRL_PIN
	and		r19,r18
	brne	PRok
	subi	r16,1
	sbci	r17,0
	brne	PRp
//-------------

	ldi		r16,STATUS_RDY_BSY_TOUT
	sec
	ret
PRok:
	ldi		r16,STATUS_CMD_OK
	clc
	ret

//---------------------

LoadZppo:
	ldi		r30,lo8(ppstack)
	ldi		r31,hi8(ppstack)
	add		r30,r18
	adc		r31,rnull
	ret

//HVPP
//=============================================================================
//HVSP

#define StabDelay		Z+0
#define CmdexeDelay		Z+1
#define SynchCycles		Z+2
#define LatchCycles		Z+3
#define ToggleVtg		Z+4
#define PowoffDelay		Z+5
#define ResetDelayMs	Z+6
#define ResetDelayUs	Z+7

EnterPMSP:
	movw	r30,r26

	ldd		r16,LatchCycles
	sts		LatchC,r16

	//rst low 5V + vtg off
	in		r16,PORTC
	andi	r16,0x0F // CTRL_XT1 = 0
	ori		r16,(1<<CTRL_12V)|(1<<CTRL_RST)|(1<<CTRL_PWR)
	out		PORTC,r16
//	in		r16,DDRC
//	ori		r16,0xF0
	ldi		r16,0xF4 //20120817
	out		DDRC,r16

	out		SPORT,rnull
#ifdef SPORT_SCI
	ldi		r16,(1<<SDI)|(1<<SII)|(1<<SCI) // not used
#else
	ldi		r16,(1<<SDI)|(1<<SII)
#endif
	out		SDDR,r16

	//used for ATtiny24 44 84 prog_enable
	out		CTRLPORT,rnull
	lds		r16,spstack_ddr
	out		CTRL_DDR,r16

//---------------------------

	//rst low 12V
	rcall	Delay1ms
	cbi		PORTC,CTRL_12V
	rcall	Delay1ms

	//vtg on
	cbi		PORTC,CTRL_PWR
	rcall	Delay1ms

	ldd		r16,SynchCycles //??? 0 will give 256 cycles ??? 20120817
EPnextls:
	rcall	HVSPpulse  ///?? PulseXT1
	dec		r16
	brne	EPnextls

	//rst 12V
	rcall	Delay1ms
	cbi		PORTC,CTRL_RST

	ldi		r16,10
	rcall	Delay

	out		CTRL_DDR,rnull

	st		Y+,rnull //STATUS_CMD_OK
	ret

#undef StabDelay
#undef ProgModeDelay
#undef LatchCycles
#undef ToggleVtg
#undef PowerOffDelay
#undef ResetDelayMs
#undef ResetDelayUs

#define StabDelay	Z+0
#define ResetDelay	Z+1

LeavePMSP:
	movw	r30,r26

	//RST = 0V (5V)
	sbi		PORTC,CTRL_RST
	sbi		PORTC,CTRL_12V

	ldd		r16,StabDelay
	rcall	Delay

	//DDR = 0
	out		SDDR,rnull
	out		SPORT,rnull

	ldd		r16,ResetDelay
	rcall	Delay

	//PORTC
	ldi		r16,0x04 //20120818  RST + PWR = 0V
	lds		r17,misc
	sbrc	r17,0
	ldi		r16,0x94 //20120817  RST + PWR = 5V
	out		DDRC,r16
	out		PORTC,rnull

//	cbi		PORTC,CTRL_RST
//	cbi		PORTC,CTRL_PWR

	ldd		r16,StabDelay
	rcall	Delay

	ret

#undef StabDelay
#undef ResetDelay

//-----------------------------------------------

WriteFlashSP:
	sbi		GPIOR0,0
	ldi		r18,SPC_WFLASH
	rjmp	WFS
WriteEepromSP:
	cbi		GPIOR0,0
	ldi		r18,SPC_WEEP
WFS:
	rcall	HVSPSetCommand // p r18 c r16 r17 r19
	rcall	LoadAddressSP // c r16 r17 r19 r r24 r25 Z

	ld		r21,X+ //mode
	ld		r10,X+ //pollTO
	sbrs	r21,0
	rjmp	WFSwfb
//------WriteFlashPages-------
	movw	r22,r24

	//r25:r24 = 1 << (r21 & 7); == pagesize
//------
	push	r21
	lsr		r21
	andi	r21,7
	ldi		r25,1
	ldi		r24,0
	breq	WFSl  //256
	ldi		r25,0
	ldi		r24,1
WFSlsl:
	dec		r21
	brmi	WFSl
	lsl		r24
	rol		r25
	rjmp	WFSlsl
WFSl:
	pop		r21
//------

//===========================
WFSn:
	sub		r22,r24
	sbc		r23,r25
	brcs	WFSrok
	push	r24
	push	r25
//------------------
//do {
WFSwfp:
	//rcall	LoadLowByte
	ld		r16,X+
	lds		r17,spstack_llb
	rcall	HVSPsend // pr r16=sdi=sdo p r17=sii c r19
	lds		r17,spstack_pll

	sbiw	r24,1

	sbis	GPIOR0,0
	rjmp	WFSh
	//rcall	LoadHighByte
	ld		r16,X+
	lds		r17,spstack_lhb
	rcall	HVSPsend // pr r16=sdi=sdo p r17=sii c r19
	lds		r17,spstack_plh
	sbiw	r24,1
WFSh:
	//rcall	LatchData
	ldi		r16,0
	rcall	HVSPsend // pr r16=sdi=sdo p r17=sii c r19

//while(!pagefull)
	mov		r16,r24
	or		r16,r25
	breq	WFSfp

	rcall	IncAddressSP // c r16 r17 r18 r19 Z
	rjmp	WFSwfp
//------------------

WFSfp:
	//if(wp)
	sbrs	r21,7
	rjmp	WFSpp
	//{
	ldi		r18,SPI_WRL
	rcall	HVSPRead //c r16 r17 p r18 c r19 Z
	mov		r17,r10
	rcall	HVSPpoll // c r16 p r17
	brcs	WFSr //tout
	//}
WFSpp:
	rcall	IncAddressSP // c r16 r17 r18 r19 Z
	pop		r25
	pop		r24
	rjmp	WFSn
//===========================

//------WriteFlashPages-------
//------WriteFlashBytes-------
WFSwfb:
	ld		r16,X+
	rcall	HVSPwrl //pc r16 c r17 r18 r19 Z
	mov		r17,r10
	rcall	HVSPpoll // c r16 p r17
	brcs	WFSr

	sbis	GPIOR0,0
	rjmp	WFSbh
	sbiw	r24,1
	ld		r16,X+
	rcall	HVSPwrh //pc r16 c r17 r18 r19 Z
	mov		r17,r10
	rcall	HVSPpoll // c r16 p r17
	brcs	WFSr
WFSbh:
	rcall	IncAddressSP // c r16 r17 r18 r19 Z
	sbiw	r24,1
	brne	WFSwfb
//------WriteFlashBytes-------
WFSrok:
//if(last page)
	sbrs	r21,6
	rjmp	WFSro
//{
	mov		r17,r10
	rcall	HVSPpoll // c r16 p r17
	brcs	WFSr
	ldi		r16,0
	rcall	HVSPsc // pc r16 c r17 r19 //--> nop

WFSro:
	ldi		r16,0 //STATUS_CMD_OK
//}
WFSr:
	ret

//-----------------------------------------------

ReadLow: //c r16 r17 r18 r19
	lds		r17,spstack_rlb
	rjmp	RHi
ReadHigh: //c r16 r17 r18 r19
	lds		r17,spstack_rhb
RHi:
	ldi		r16,0
	rcall	HVSPSend // pr r16=sdi=sdo p r17=sii c r19
	ldi		r16,0
	lds		r18,spstack_orm
	or		r17,r18
	rcall	HVSPSend // pr r16=sdi=sdo p r17=sii c r19
	st		Y+,r16
	ret

//-----------------------------------------------

LoadAddressSP: // c r16 r17 r19 r r24 r25 Z
	ld		r25,X+ //sizeH
	ld		r24,X+ //sizeL

	ldi		r31,hi8(address+2)
	ldi		r30,lo8(address+2)
LASn:
	ld		r16,-Z
	ldd		r17,Z+5 //lha lla
	rcall	HVSPSend // pr r16=sdi=sdo p r17=sii c r19
	cpi		r30,lo8(address)
	brne	LASn
	ret

IncAddressSP: // c r16 r17 r18 r19 Z
	ldi		r31,hi8(address)
	ldi		r30,lo8(address)
IASn:
	ld		r16,Z
	subi	r16,0xFF //+1
	st		Z+,r16
	mov		r18,r16
	ldd		r17,Z+4 //ppstack_lla lha lea
	rcall	HVSPSend // pr r16=sdi=sdo p r17=sii c r19
	tst		r18
	breq	IASn //from subi
	//dec	count
	ret




//-----------------------------------------------


HVSPSetCommand: // p r18 c r16 r17 r19
	rcall	LoadZppo // p r18 c Z
	ld		r16,Z
HVSPsc: // pc r16 c r17 r19
	lds		r17,spstack_cmd
	rcall	HVSPsend // pr r16=sdi=sdo p r17=sii c r19
	ret

HVSPlla:
	ld		r16,X+
	lds		r17,spstack_lla
	rcall	HVSPsend // pr r16=sdi=sdo p r17=sii c r19
	ret

HVSPwrh: //pc r16 c r17 r18 r19 Z
	ldi		r18,SPI_WRH
	lds		r17,spstack_llb
	rcall	HVSPsend // pr r16=sdi=sdo p r17=sii c r19
	rjmp	HVSPRead //c r16 r17 p r18 c r19 Z

HVSPwrl: //pc r16 c r17 r18 r19 Z
	ldi		r18,SPI_WRL
HVSPWrite: //pc r16 c r17 p r18 c r19 Z
	lds		r17,spstack_llb
	rcall	HVSPsend // pr r16=sdi=sdo p r17=sii c r19
HVSPRead: //c r16 r17 p r18 c r19 Z
	rcall	LoadZppo // p r18 c Z
	ldi		r16,0
	ld		r17,Z
	rcall	HVSPsend // pr r16=sdi=sdo p r17=sii c r19
	ldi		r16,0
	lds		r18,spstack_orm
	or		r17,r18
	rcall	HVSPsend // pr r16=sdi=sdo p r17=sii c r19
	ret

//-----------------------------------------------
//HVSP physical

HVSPpollXp: // c r16 r17
	ld		r17,X+
HVSPpoll: // c r16 p r17
	clc
	ldi		r16,0 //STATUS_CMD_OK
	tst		r17
	breq	HPr
HPn:
	ldi		r16,1
	rcall	Delay
	clc
	ldi		r16,0 //STATUS_CMD_OK
	sbic	SPIN,SDO
	rjmp	HPr
	dec		r17
	brne	HPn
	sec
	ldi		r16,0x81 //STATUS_RDY_BSY_TOUT
HPr:
	ret

HVSPsend: // pr r16=sdi=sdo p r17=sii c r19 r20
	push	r17
	ldi		r20,8   //<-----
HSnext:
	rcall	HVSPpulse
	in		r19,SPIN
	bst		r16,7
	bld		r19,SDI
	bst		r17,7
	bld		r19,SII
	bst		r19,SDO
	andi	r19,0x03
	out		SPORT,r19
	lsl		r16
	lsl		r17
	//sbrc	SPIN,SDO
	brtc	HSz
	ori		r16,1
HSz:
	dec		r20   //<-----
	brne	HSnext
	rcall	HVSPpulse
	cbi		SPORT,SDI
	cbi		SPORT,SII
	rcall	HVSPpulse
	rcall	HVSPpulse
	pop		r17
	ret

HVSPpulse:
	lds		r19,LatchC //tiny 15 == 16clks... else 1
Hp:
#ifdef SPORT_SCI
	sbi		SPORT,SCI //not used
	rjmp	PC+1
	cbi		SPORT,SCI
#else
	sbi		PORTC,CTRL_XT1
	rjmp	PC+1
	cbi		PORTC,CTRL_XT1
#endif
	dec		r19
	brne	HPn
	ret

//HVSP extra code
//-----------------------------------------------

Delay1ms:
	ldi		r16,1
	rjmp	Delay

//HVSP
//=============================================================================




