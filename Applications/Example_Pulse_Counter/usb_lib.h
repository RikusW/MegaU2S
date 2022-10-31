// GPLv2 2010 Rikus Wessels
// rikusw gmail


#ifndef _USB_LIB_H_
#define _USB_LIB_H_

//---------------------------------------------------------

typedef signed char s8;
typedef signed short s16;
typedef signed long s32;
typedef unsigned char u8;
typedef unsigned short u16;
typedef unsigned long u32;

//---------------------------------------------------------

// 0x00 == Default value in eeprom.
// 0x01 - 0x0F  == App
// 0x80 == DebugMode
// 0x81 == Bootloader
// 0x82 == ISP Programmer
// 0x83 - 0x8F == Reserved
// OR with 0x20 to prevent the led flashing.

void select_mode(u8 u);

//---------------------------------------------------------

//This is for a 16MHz crystal
#define SC_16M	0 
#define SC_8M	1 //default - set by bootloader
#define SC_4M	2
#define SC_2M	3
#define SC_1M	4
#define SC_500K	5
#define SC_250K	6
#define SC_125K	7
#define SC_62K5 8

void set_clock(u8);

//---------------------------------------------------------

void usb_init();
void usb_task(); // not needed when using interrupts

u8 usb_txready();
u8 usb_getc();

#define usb_peek usb_rxready
u8 usb_rxready();
void usb_putc_nf(u8);
void usb_putc(u8);
void usb_flush();

//---------------------------------------------------------

#define led_on() (PORTC &= ~(1<<PORTC2))
#define led_off() (PORTC &= (1<<PORTC2))
#define select_pressed() (!(PINC & (1<<PINC4)))

// done by bootloader
#define setup_led() (DDRC |= (1<<DDC2))
#define setup_select_switch() DDRC &= ~(1<<DDC4); PORTC |= (1<<PORTC4)

//---------------------------------------------------------
// CDC USART stuff

typedef struct
{
   u32 dwDTERate;
   u8 bCharFormat;
   u8 bParityType;
   u8 bDataBits;
}S_line_coding;

// type for set control line state message
// cdc spec 1.1 chapter 6.2.14
typedef union
{
   u8 all;
   struct {
      u8 DTR:1;
      u8 RTS:1;
      u8 unused:6;
   };
}S_line_status;

// type for hardware handshake support 
// cdc spec 1.1 chapter 6.3.5
typedef union
{
   u16 all;
   struct {
      u16 bDCD:1;
      u16 bDSR:1;
      u16 bBreak:1;
      u16 bRing:1;
      u16 bFraming:1;
      u16 bParity:1;
      u16 bOverRun:1;
      u16 reserved:9;
   };
}S_serial_state;

//---------------------------------------------------------
//variables passed from the bootloader

#define LF_CODING	1
#define LF_STATUS	2
#define LF_BREAK	4

extern volatile u8 conf_nr;

extern volatile u8 line_flags;
// These bits will be set when any of the following 3 change
// 1=coding 2=status 4=break
extern volatile S_line_coding line_coding;
extern volatile S_line_status line_status;
extern volatile u16 line_break;

extern volatile u8 select; // can be accessed as the first parameter of main(int argc)

//---------------------------------------------------------

#endif /* _USB_LIB_H_ */
