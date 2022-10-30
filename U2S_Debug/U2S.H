
typedef unsigned char u8;
typedef unsigned short u16;
typedef unsigned long u32;

//=============================================================================
//STK500 protocol plus extensions

class U2S
{
public:

	U2S() {};
	~U2S() {};

	u8 Connect(const char *, u8 mode = 0x81);// check this return value, it will fail if port cannot be opened
	void Disconnect();


	u8 SignOn();			// check this return value, it will fail if a stk500 is not connected
	void SetParameter(u8 a, u8 v);
	u8 GetParameter(u8 a);
	void SetAddress(u32 a);

//=====================================
//ISP

	u8 EnterProgmodeIsp();	// check this return value, it will fail if target isn't connected
	void LeaveProgmodeIsp();
	void ChipErase();

	//TODO prog/read flash/eeprom
	void ReadFlash(u8 **buf, u16 u);
	void ReadEeprom(u8 **buf, u16 u);


	#define WF_LFUSE 0xA0 //lf AC A0 00 ii
	#define WF_LOCK  0xE0 //lk AC E0 00 ii
	#define WF_EFUSE 0xA4 //ef AC A4 00 ii
	#define WF_HFUSE 0xA8 //hf AC A8 00 ii
	void WriteFuse(u8 a, u8 v); //BL can't do this
	//NOTE!! ALL unused lock/fusebits MUST be set to 1

	//                        BS1 BS2
	#define RF_LFUSE 0x00 //lf 50 00
	#define RF_LOCK  0x80 //lk 58 00
	#define RF_EFUSE 0x08 //ef 50 08
	#define RF_HFUSE 0x88 //hf 58 08
	u8 ReadFuse(u8 a);

	u8 ReadSig(u8 a);
	u8 ReadCal(u8 a);
	void GetSerial(u8 *buf); // [10]

//=====================================
//CUSTOM

	void SelectMode(u8 u);
	u8 GetMode();
	u8 GetVersion();
	u16 GetAppSize();
	u8 ModUnlock();
	void ErasePages(u8 n); //this only works in the U2S bootloader


//=====================================
//SPI

	void SpiSetSpeed(u8 u);
	bool SpiOn();
	void SpiOff();
	void SpiPulse();
	void SpiTx(u8 *buf,u8 nr);

//=====================================
//DEBUG

	u8 ReadByte(u16 a);
	void ReadBytes(u16 a, u8 c, u8 *buf);
	void WriteByte(u16 a, u8 c);
	void WriteBytes(u16 a, u8 c, u8 *buf);
	void WriteBit(u16 a, u8 an, u8 o);
	void DoDelayM(u8 u);
	void DoDelayU(u8 u);

private:
	void SendMsg();
	u8 *GetMsg();
};

//=============================================================================


