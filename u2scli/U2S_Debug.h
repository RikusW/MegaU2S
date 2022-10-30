
#include "U2S.h"

U2S u2s;

class IOPort
{
public:
	IOPort(u16 a) { address = a; };
	~IOPort() {};

	u8 operator=(u8 u) { u2s.WriteByte(address,u); return 0; };
	u8 operator|=(u8 u) { u2s.WriteBit(address,0xFF,u); return 0; };
	u8 operator&=(u8 u) { u2s.WriteBit(address,u,0); return 0; };
	operator u8() { return u2s.ReadByte(address); };

	u16 address;
};



IOPort PINB(0x23);
#define PINB7 7
#define PINB6 6
#define PINB5 5
#define PINB4 4
#define PINB3 3
#define PINB2 2
#define PINB1 1
#define PINB0 0

IOPort DDRB(0x24);
#define DDB7 7
#define DDB6 6
#define DDB5 5
#define DDB4 4
#define DDB3 3
#define DDB2 2
#define DDB1 1
#define DDB0 0

IOPort PORTB(0x25);
#define PORTB7 7
#define PORTB6 6
#define PORTB5 5
#define PORTB4 4
#define PORTB3 3
#define PORTB2 2
#define PORTB1 1
#define PORTB0 0

IOPort PINC(0x26);
#define PINC7 7
#define PINC6 6
#define PINC5 5
#define PINC4 4
#define PINC2 2
#define PINC1 1
#define PINC0 0

IOPort DDRC(0x27);
#define DDC7 7
#define DDC6 6
#define DDC5 5
#define DDC4 4
#define DDC2 2
#define DDC1 1
#define DDC0 0

IOPort PORTC(0x28);
#define PORTC7 7
#define PORTC6 6
#define PORTC5 5
#define PORTC4 4
#define PORTC2 2
#define PORTC1 1
#define PORTC0 0

IOPort PIND(0x29);
#define PIND7 7
#define PIND6 6
#define PIND5 5
#define PIND4 4
#define PIND3 3
#define PIND2 2
#define PIND1 1
#define PIND0 0

IOPort DDRD(0x2A);
#define DDD7 7
#define DDD6 6
#define DDD5 5
#define DDD4 4
#define DDD3 3
#define DDD2 2
#define DDD1 1
#define DDD0 0

IOPort PORTD(0x2B);
#define PORTD7 7
#define PORTD6 6
#define PORTD5 5
#define PORTD4 4
#define PORTD3 3
#define PORTD2 2
#define PORTD1 1
#define PORTD0 0

IOPort TIFR0(0x35);
#define OCF0B 2
#define OCF0A 1
#define TOV0 0

IOPort TIFR1(0x36);
#define ICF1 5
#define OCF1C 3
#define OCF1B 2
#define OCF1A 1
#define TOV1 0

IOPort PCIFR(0x3B);
#define PCIF1 1
#define PCIF0 0

IOPort EIFR(0x3C);
#define INTF7 7
#define INTF6 6
#define INTF5 5
#define INTF4 4
#define INTF3 3
#define INTF2 2
#define INTF1 1
#define INTF0 0

IOPort EIMSK(0x3D);
#define INT7 7
#define INT6 6
#define INT5 5
#define INT4 4
#define INT3 3
#define INT2 2
#define INT1 1
#define INT0 0

IOPort GPIOR0(0x3E);
#define GPIOR07 7
#define GPIOR06 6
#define GPIOR05 5
#define GPIOR04 4
#define GPIOR03 3
#define GPIOR02 2
#define GPIOR01 1
#define GPIOR00 0

IOPort EECR(0x3F);
#define EEPM1 5
#define EEPM0 4
#define EERIE 3
#define EEMPE 2
#define EEPE 1
#define EERE 0

IOPort EEDR(0x40);
#define EEDR7 7
#define EEDR6 6
#define EEDR5 5
#define EEDR4 4
#define EEDR3 3
#define EEDR2 2
#define EEDR1 1
#define EEDR0 0

IOPort EEARL(0x41);
#define EEAR7 7
#define EEAR6 6
#define EEAR5 5
#define EEAR4 4
#define EEAR3 3
#define EEAR2 2
#define EEAR1 1
#define EEAR0 0

IOPort EEARH(0x42);
#define EEAR11 3
#define EEAR10 2
#define EEAR9 1
#define EEAR8 0

IOPort GTCCR(0x43);
#define TSM 7
#define PSRSYNC 0

IOPort TCCR0A(0x44);
#define COM0A1 7
#define COM0A0 6
#define COM0B1 5
#define COM0B0 4
#define WGM01 1
#define WGM00 0

IOPort TCCR0B(0x45);
#define FOC0A 7
#define FOC0B 6
#define WGM02 3
#define CS02 2
#define CS01 1
#define CS00 0

IOPort TCNT0(0x46);
#define TCNT0_7 7
#define TCNT0_6 6
#define TCNT0_5 5
#define TCNT0_4 4
#define TCNT0_3 3
#define TCNT0_2 2
#define TCNT0_1 1
#define TCNT0_0 0

IOPort OCR0A(0x47);
#define OCR0A_7 7
#define OCR0A_6 6
#define OCR0A_5 5
#define OCR0A_4 4
#define OCR0A_3 3
#define OCR0A_2 2
#define OCR0A_1 1
#define OCR0A_0 0

IOPort OCR0B(0x48);
#define OCR0B_7 7
#define OCR0B_6 6
#define OCR0B_5 5
#define OCR0B_4 4
#define OCR0B_3 3
#define OCR0B_2 2
#define OCR0B_1 1
#define OCR0B_0 0

IOPort PLLCSR(0x49);
#define PLLP2 4
#define PLLP1 3
#define PLLP0 2
#define PLLE 1
#define PLOCK 0

IOPort GPIOR1(0x4A);
#define GPIOR17 7
#define GPIOR16 6
#define GPIOR15 5
#define GPIOR14 4
#define GPIOR13 3
#define GPIOR12 2
#define GPIOR11 1
#define GPIOR10 0

IOPort GPIOR2(0x4B);
#define GPIOR27 7
#define GPIOR26 6
#define GPIOR25 5
#define GPIOR24 4
#define GPIOR23 3
#define GPIOR22 2
#define GPIOR21 1
#define GPIOR20 0

IOPort SPCR(0x4C);
#define SPIE 7
#define SPE 6
#define DORD 5
#define MSTR 4
#define CPOL 3
#define CPHA 2
#define SPR1 1
#define SPR0 0

IOPort SPSR(0x4D);
#define SPIF 7
#define WCOL 6
#define SPI2X 0

IOPort SPDR(0x4E);
#define SPDR7 7
#define SPDR6 6
#define SPDR5 5
#define SPDR4 4
#define SPDR3 3
#define SPDR2 2
#define SPDR1 1
#define SPDR0 0

IOPort ACSR(0x50);
#define ACD 7
#define ACBG 6
#define ACO 5
#define ACI 4
#define ACIE 3
#define ACIC 2
#define ACIS1 1
#define ACIS0 0

IOPort DWDR(0x51);
#define DWDR7 7
#define DWDR6 6
#define DWDR5 5
#define DWDR4 4
#define DWDR3 3
#define DWDR2 2
#define DWDR1 1
#define DWDR0 0

IOPort SMCR(0x53);
#define SM2 3
#define SM1 2
#define SM0 1
#define SE 0

IOPort MCUSR(0x54);
#define USBRF 5
#define WDRF 3
#define BORF 2
#define EXTRF 1
#define PORF 0

IOPort MCUCR(0x55);
#define PUD 4
#define IVSEL 1
#define IVCE 0

IOPort SPMCSR(0x57);
#define SPMIE 7
#define RWWSB 6
#define SIGRD 5
#define RWWSRE 4
#define BLBSET 3
#define PGWRT 2
#define PGERS 1
#define SPMEN 0

IOPort EIND(0x5C);
#define EIND0 0

IOPort SPL(0x5D);
#define SP7 7
#define SP6 6
#define SP5 5
#define SP4 4
#define SP3 3
#define SP2 2
#define SP1 1
#define SP0 0

IOPort SPH(0x5E);
#define SP15 7
#define SP14 6
#define SP13 5
#define SP12 4
#define SP11 3
#define SP10 2
#define SP9 1
#define SP8 0

IOPort SREG(0x5F);
#define I 7
#define T 6
#define H 5
#define S 4
#define V 3
#define N 2
#define Z 1
#define C 0

IOPort WDTCSR(0x60);
#define WDIF 7
#define WDIE 6
#define WDP3 5
#define WDCE 4
#define WDE 3
#define WDP2 2
#define WDP1 1
#define WDP0 0

IOPort CLKPR(0x61);
#define CLKPCE 7
#define CLKPS3 3
#define CLKPS2 2
#define CLKPS1 1
#define CLKPS0 0

IOPort WDTCKD(0x62);
#define WDEWIF 3
#define WDEWIE 2
#define WCLKD1 1
#define WCLKD0 0

IOPort REGCR(0x63);
#define REGDIS 0

IOPort PRR0(0x64);
#define PRTIM0 5
#define PRTIM1 3
#define PRSPI 2

IOPort PRR1(0x65);
#define PRUSB 7
#define PRUSART1 0

IOPort OSCCAL(0x66);
#define CAL7 7
#define CAL6 6
#define CAL5 5
#define CAL4 4
#define CAL3 3
#define CAL2 2
#define CAL1 1
#define CAL0 0

IOPort PCICR(0x68);
#define PCIE1 1
#define PCIE0 0

IOPort EICRA(0x69);
#define ISC31 7
#define ISC30 6
#define ISC21 5
#define ISC20 4
#define ISC11 3
#define ISC10 2
#define ISC01 1
#define ISC00 0

IOPort EICRB(0x6A);
#define ISC71 7
#define ISC70 6
#define ISC61 5
#define ISC60 4
#define ISC51 3
#define ISC50 2
#define ISC41 1
#define ISC40 0

IOPort PCMSK0(0x6B);
#define PCINT7 7
#define PCINT6 6
#define PCINT5 5
#define PCINT4 4
#define PCINT3 3
#define PCINT2 2
#define PCINT1 1
#define PCINT0 0

IOPort PCMSK1(0x6C);
#define PCINT12 4
#define PCINT11 3
#define PCINT10 2
#define PCINT9 1
#define PCINT8 0

IOPort TIMSK0(0x6E);
#define OCIE0B 2
#define OCIE0A 1
#define TOIE0 0

IOPort TIMSK1(0x6F);
#define ICIE1 5
#define OCIE1C 3
#define OCIE1B 2
#define OCIE1A 1
#define TOIE1 0

IOPort ACMUX(0x7D);
#define ACMUX2
#define ACMUX1
#define ACMUX0

IOPort DIDR1(0x7F);
#define AIN1D 1
#define AIN0D 0

IOPort TCCR1A(0x80);
#define COM1A1 7
#define COM1A0 6
#define COM1B1 5
#define COM1B0 4
#define COM1C1 3
#define COM1C0 2
#define WGM11 1
#define WGM10 0

IOPort TCCR1B(0x81);
#define ICNC1 7
#define ICES1 6
#define WGM13 4
#define WGM12 3
#define CS12 2
#define CS11 1
#define CS10 0

IOPort TCCR1C(0x82);
#define FOC1A 7
#define FOC1B 6
#define FOC1C 5

IOPort TCNT1L(0x84);
#define TCNT1L7 7
#define TCNT1L6 6
#define TCNT1L5 5
#define TCNT1L4 4
#define TCNT1L3 3
#define TCNT1L2 2
#define TCNT1L1 1
#define TCNT1L0 0

IOPort TCNT1H(0x85);
#define TCNT1H7 7
#define TCNT1H6 6
#define TCNT1H5 5
#define TCNT1H4 4
#define TCNT1H3 3
#define TCNT1H2 2
#define TCNT1H1 1
#define TCNT1H0 0

IOPort ICR1L(0x86);
#define ICR1L7 7
#define ICR1L6 6
#define ICR1L5 5
#define ICR1L4 4
#define ICR1L3 3
#define ICR1L2 2
#define ICR1L1 1
#define ICR1L0 0

IOPort ICR1H(0x87);
#define ICR1H7 7
#define ICR1H6 6
#define ICR1H5 5
#define ICR1H4 4
#define ICR1H3 3
#define ICR1H2 2
#define ICR1H1 1
#define ICR1H0 0

IOPort OCR1AL(0x88);
#define OCR1AL7 7
#define OCR1AL6 6
#define OCR1AL5 5
#define OCR1AL4 4
#define OCR1AL3 3
#define OCR1AL2 2
#define OCR1AL1 1
#define OCR1AL0 0

IOPort OCR1AH(0x89);
#define OCR1AH7 7
#define OCR1AH6 6
#define OCR1AH5 5
#define OCR1AH4 4
#define OCR1AH3 3
#define OCR1AH2 2
#define OCR1AH1 1
#define OCR1AH0 0

IOPort OCR1BL(0x8A);
#define OCR1BL7 7
#define OCR1BL6 6
#define OCR1BL5 5
#define OCR1BL4 4
#define OCR1BL3 3
#define OCR1BL2 2
#define OCR1BL1 1
#define OCR1BL0 0

IOPort OCR1BH(0x8B);
#define OCR1BH7 7
#define OCR1BH6 6
#define OCR1BH5 5
#define OCR1BH4 4
#define OCR1BH3 3
#define OCR1BH2 2
#define OCR1BH1 1
#define OCR1BH0 0

IOPort OCR1CL(0x8C);
#define OCR1CL7 7
#define OCR1CL6 6
#define OCR1CL5 5
#define OCR1CL4 4
#define OCR1CL3 3
#define OCR1CL2 2
#define OCR1CL1 1
#define OCR1CL0 0

IOPort OCR1CH(0x8D);
#define OCR1CH7 7
#define OCR1CH6 6
#define OCR1CH5 5
#define OCR1CH4 4
#define OCR1CH3 3
#define OCR1CH2 2
#define OCR1CH1 1
#define OCR1CH0 0

IOPort UCSR1A(0xC8);
#define RXC1 7
#define TXC1 6
#define UDRE1 5
#define FE1 4
#define DOR1 3
#define UPE1 2
#define U2X1 1
#define MPCM1 0

IOPort UCSR1B(0xC9);
#define RXCIE1 7
#define TXCIE1 6
#define UDRIE1 5
#define RXEN1 4
#define TXEN1 3
#define UCSZ12 2
#define RXB81 1
#define TXB81 0

IOPort UCSR1C(0xCA);
#define UMSEL11 7
#define UMSEL10 6
#define UPM11 5
#define UPM10 4
#define USBS1 3
#define UCSZ11 2
#define UCSZ10 1
#define UCPOL1 0

IOPort UCSR1D(0xCB);
#define CTSEN 1
#define RTSEN 0

IOPort UBRR1L(0xCC);
#define UBRR1_7 7
#define UBRR1_6 6
#define UBRR1_5 5
#define UBRR1_4 4
#define UBRR1_3 3
#define UBRR1_2 2
#define UBRR1_1 1
#define UBRR1_0 0

IOPort UBRR1H(0xCD);
#define UBRR1_11 3
#define UBRR1_10 2
#define UBRR1_9 1
#define UBRR1_8 0

IOPort UDR1(0xCE);
#define UDR1_7 7
#define UDR1_6 6
#define UDR1_5 5
#define UDR1_4 4
#define UDR1_3 3
#define UDR1_2 2
#define UDR1_1 1
#define UDR1_0 0

IOPort CLKSEL0(0xD0);
#define RCSUT1 7
#define RCSUT0 6
#define EXSUT1 5
#define EXSUT0 4
#define RCE 3
#define EXTE 2
#define CLKS 0

IOPort CLKSEL1(0xD1);
#define RCCKSEL3 7
#define RCCKSEL2 6
#define RCCKSEL1 5
#define RCCKSEL0 4
#define EXCKSEL3 3
#define EXCKSEL2 2
#define EXCKSEL1 1
#define EXCKSEL0 0

IOPort CLKSTA(0xD2);
#define RCON 1
#define EXTON 0

IOPort USBCON(0xD8);
#define USBE 7
#define FRZCLK 5

IOPort UDCON(0xE0);
#define RSTCPU 2
#define RMWKUP 1
#define DETACH 0

IOPort UDINT(0xE1);
#define UPRSMI 6
#define EORSMI 5
#define WAKEUPI 4
#define EORSTI 3
#define SOFI 2
#define SUSPI 0

IOPort UDIEN(0xE2);
#define UPRSME 6
#define EORSME 5
#define WAKEUPE 4
#define EORSTE 3
#define SOFE 2
#define SUSPE 0

IOPort UDADDR(0xE3);
#define ADDEN 7
#define UADD6 6
#define UADD5 5
#define UADD4 4
#define UADD3 3
#define UADD2 2
#define UADD1 1
#define UADD0 0

IOPort UDFNUML(0xE4);
#define FNUM7 7
#define FNUM6 6
#define FNUM5 5
#define FNUM4 4
#define FNUM3 3
#define FNUM2 2
#define FNUM1 1
#define FNUM0 0

IOPort UDFNUMH(0xE5);
#define FNUM10 2
#define FNUM9 1
#define FNUM8 0

IOPort UDMFN(0xE6);
#define FNCERR 4

IOPort UEINTX(0xE8);
#define FIFOCON 7
#define NAKINI 6
#define RWAL 5
#define NAKOUTI 4
#define RXSTPI 3
#define RXOUTI 2
#define STALLEDI 1
#define TXINI 0

IOPort UENUM(0xE9);
#define EPNUM2 2
#define EPNUM1 1
#define EPNUM0 0

IOPort UERST(0xEA);
#define EPRST4 4
#define EPRST3 3
#define EPRST2 2
#define EPRST1 1
#define EPRST0 0

IOPort UECONX(0xEB);
#define STALLRQ 5
#define STALLRQC 4
#define RSTDT 3
#define EPEN 0

IOPort UECFG0X(0xEC);
#define EPTYPE1 7
#define EPTYPE0 6
#define EPDIR 0

IOPort UECFG1X(0xED);
#define EPSIZE2 6
#define EPSIZE1 5
#define EPSIZE0 4
#define EPBK1 3
#define EPBK0 2
#define ALLOC 1

IOPort UESTA0X(0xEE);
#define CFGOK 7
#define OVERFI 6
#define UNDERFI 5
#define DTSEQ1 3
#define DTSEQ0 2
#define NBUSYBK1 1
#define NBUSYBK0 0

IOPort UESTA1X(0xEF);
#define CTRLDIR 2
#define CURRBK1 1
#define CURRBK0 0

IOPort UEIENX(0xF0);
#define FLERRE 7
#define NAKINE 6
#define NAKOUTE 4
#define RXSTPE 3
#define RXOUTE 2
#define STALLEDE 1
#define TXINE 0

IOPort UEDATX(0xF1);
#define DAT7 7
#define DAT6 6
#define DAT5 5
#define DAT4 4
#define DAT3 3
#define DAT2 2
#define DAT1 1
#define DAT0 0

IOPort UEBCLX(0xF2);
#define BYCT7 7
#define BYCT6 6
#define BYCT5 5
#define BYCT4 4
#define BYCT3 3
#define BYCT2 2
#define BYCT1 1
#define BYCT0 0

IOPort UEINT(0xF4);
#define EPINT4 4
#define EPINT3 3
#define EPINT2 2
#define EPINT1 1
#define EPINT0 0

IOPort PS2CON(0xFA);
#define PS2EN 0

IOPort UPOE(0xFB);
#define UPWE1 7
#define UPWE0 6
#define UPDRV1 5
#define UPDRV0 4
#define SCKI 3
#define DATAI 2
#define DPI 1
#define DMI 0

