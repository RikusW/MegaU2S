// GPLv2 2010 Rikus Wessels
// rikusw gmail


#include <avr/io.h>
#include <avr/interrupt.h>
#include "usb_lib.h"

//---------------------------------------------------------

// this is passed from the bootloader
// ---IMPORTANT---
// .noinit MUST be set to 0x100 and .bss to 0x10E
// ---IMPORTANT---
// Do this in in Project->Configuration Options->Memory Settings

volatile u8 conf_nr 				__attribute__ ((section (".noinit")));
volatile u8 line_flags 				__attribute__ ((section (".noinit"))); // 1=coding 2=status 4=break
volatile S_line_coding line_coding	__attribute__ ((section (".noinit")));
volatile S_line_status line_status	__attribute__ ((section (".noinit")));
volatile u8 rsvd					__attribute__ ((section (".noinit")));
volatile u16 line_break				__attribute__ ((section (".noinit")));
volatile u8 select					__attribute__ ((section (".noinit")));

//---------------------------------------------------------

//When not using interrupts ensure that usb_task is called regularly,
//especially during enumeration, otherwise expect to have trouble...
#define USE_INTERRUPT // otherwise use usb_task
#ifdef  USE_INTERRUPT
#define usb_task()
#endif

#define TX_EP		0x03
#define RX_EP		0x04
#define INT_EP		0x01
#define CONTROL_EP  0x00

#define Is_device_enumerated()		(conf_nr)
#define Usb_select_endpoint(ep)		(UENUM = (u8)ep )
#define Is_usb_receive_out()		(UEINTX&(1<<RXOUTI))
#define Is_usb_read_enabled()		(UEINTX&(1<<RWAL))
#define Is_usb_write_enabled()		(UEINTX&(1<<RWAL))
#define Usb_read_byte()				(UEDATX)
#define Usb_write_byte(byte)		(UEDATX = (u8)byte)
#define Usb_ack_fifocon()			(UEINTX &= ~(1<<FIFOCON))
#define Usb_ack_receive_out()		(UEINTX &= ~(1<<RXOUTI), Usb_ack_fifocon())
#define Usb_ack_in_ready()			(UEINTX &= ~(1<<TXINI), Usb_ack_fifocon())

#define Is_usb_reset()				((UDINT &   (1<<EORSTI)))
#define Is_usb_receive_setup()		(UEINTX&((1<<RXSTPI)))

#define Usb_enable_reset_interrupt() (UDIEN  |= (1<<EORSTE))
#define Usb_enable_setup_interrupt() (UEIENX |= (1<<RXSTPE))


#ifdef __AVR_ATmega8U2__
#define BL_CALL(a) asm("call  0x1FFE-"#a :::"r16");
#else
#ifdef __AVR_ATmega16U2__
#define BL_CALL(a) asm("call  0x3FFE-"#a :::"r16");
#else
#ifdef __AVR_ATmega32U2__
#define BL_CALL(a) asm("call  0x7FFE-"#a :::"r16");
#else
#error Unsupported MCU
#endif
#endif
#endif

//---------------------------------------------------------

void set_clock(u8 u)
{
	//WARNING turning off optimization will break this...
	u8 t = SREG;
	cli();
	CLKPR = (1<<CLKPCE);
	CLKPR = u;
	SREG = t;
}

void select_mode(u8 u) __attribute__ ((naked));
void select_mode(u8 u)
{
	// Prevent USB reinit
	u |= 0x50; //== r24

	Usb_select_endpoint(CONTROL_EP);
	UDIEN = 0;
	UEIENX = 0;

 	asm("mov	r24,%0" ::"r"(u));
	asm("ldi	r30,0x53" ::);
	asm("ldi	r31,0xCA" ::);
	BL_CALL(0x7FE); //BLStart 4KB
	// the stack is reset so call == jmp
	// this never returns
}

//---------------------------------------------------------

void usb_init()
{
#ifdef USE_INTERRUPT
	sei();
	Usb_enable_reset_interrupt();

	Usb_select_endpoint(CONTROL_EP);
	do{
		UEIENX |= (1<<RXSTPE);
	}while(!(UEIENX & (1<<RXSTPE))); //just make sure...
#endif
}

//---------------------------------------------------------

u8 usb_rxready(void)
{
	usb_task();
	if(!Is_device_enumerated()) {
		return 0;
	}

	Usb_select_endpoint(RX_EP);

	if(Is_usb_receive_out()) {
		if(Is_usb_read_enabled()) {
			return 1;
		}else{
			Usb_ack_receive_out();
		}
	}
	return 0;
}

u8 usb_getc(void)
{
	register u8 u;
	while(!Is_device_enumerated()) {
		usb_task();
	}
next:
	do {
		usb_task();
		Usb_select_endpoint(RX_EP); //yes this must be done
	}while(!Is_usb_receive_out());

	if(Is_usb_read_enabled()) {
		u = Usb_read_byte();
		if(!Is_usb_read_enabled()) {
			Usb_ack_receive_out();
		}
		return u;
	}else{
		//nothing more to read so acknowledge the packet
		Usb_ack_receive_out();
		goto next;
	}
}

//---------------------------------------------------------

u8 usb_txready(void)
{
	usb_task();

	Usb_select_endpoint(TX_EP);
	return Is_device_enumerated() && Is_usb_write_enabled();
}

void usb_putc(u8 c)
{
	usb_putc_nf(c);
	usb_flush();
}

void usb_flush()
{
	Usb_select_endpoint(TX_EP);
	Usb_ack_in_ready();
}

// flush only when the buffer is full (32bytes)
void usb_putc_nf(u8 c)
{
	do{
		usb_task();
	}while(!Is_device_enumerated());

	Usb_select_endpoint(TX_EP);

	// Wait Endpoint ready
	while(!Is_usb_write_enabled());
	Usb_write_byte(c);

	// buffer full, so flush
	// there is double buffering so this would rarely be used ?
	if(!Is_usb_write_enabled()) {
		Usb_ack_in_ready();
	}
}

//---------------------------------------------------------

#ifdef USE_INTERRUPT

ISR(USB_GEN_vect)
{
	u8 eunum = UENUM;
	if(Is_usb_reset()) {
		asm("clr r2" :::"r2");//r2 MUST be set to 0
		BL_CALL(2); //usb_reset 0x3FFE for 32U2
	}

	Usb_select_endpoint(CONTROL_EP);
	do{
		UEIENX |= (1<<RXSTPE); //IMPORTANT -- This MUST be done.
	}while(!(UEIENX & (1<<RXSTPE)));

	UENUM = eunum;
}

ISR(USB_COM_vect)
{
	u8 eunum = UENUM;
	Usb_select_endpoint(CONTROL_EP);
	if(Is_usb_receive_setup()) {
		asm("clr r2" :::"r2");//r2 MUST be set to 0
		BL_CALL(4); //usb_process_request 0x3FFD for 32U2
	}
	UENUM = eunum;
}

#else

// call the usb task in the bootloader for ep0 management
void usb_task() __attribute__ ((naked));
void usb_task()
{
	asm("push r2" ::);
	asm("push r16"::);
	BL_CALL(0); // usb_task 0x3FFF for 32U2
	asm("pop  r16"::);
	asm("pop  r2" ::);
	asm("ret"::);
}

#endif

//---------------------------------------------------------

/* In the bootloader
.org FLASHEND-2
4 (-4)	rjmp	usb_process_request // r2=0 r16
2 (-2)	rjmp	usb_reset // r2=0 r16
0 (-0)	rjmp	usb_task  // see above
Why -5?? The gcc FLASHEND is a byte address, AVR asm FLASHEND is a word address.
*/

/*
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
*/

//---------------------------------------------------------
// To send back the serial state to the PC

/*
#define  SETUP_CDC_BN_SERIAL_STATE		0x20
#define  USB_SETUP_GET_CLASS_INTER		0xA1

//#define  USB_SETUP_DIR_DEVICE_TO_HOST        (1<<7)
//#define  USB_SETUP_TYPE_CLASS                (1<<5)
//#define  USB_SETUP_RECIPIENT_INTERFACE       (1)
//#define  USB_SETUP_GET_CLASS_INTER           (USB_SETUP_DIR_DEVICE_TO_HOST |USB_SETUP_TYPE_CLASS |USB_SETUP_RECIPIENT_INTERFACE)    // 0xA1


u8 cdc_update_serial_state()
{
   if(serial_state_saved.all != serial_state.all)
   {
      serial_state_saved.all = serial_state.all;
      
      Usb_select_endpoint(INT_EP);
      if (Is_usb_write_enabled())
      {
         Usb_write_byte(USB_SETUP_GET_CLASS_INTER);   // bmRequestType
         Usb_write_byte(SETUP_CDC_BN_SERIAL_STATE);   // bNotification
         
         Usb_write_byte(0x00);   // wValue (zero)
         Usb_write_byte(0x00);
         
         Usb_write_byte(0x00);   // wIndex (Interface)
         Usb_write_byte(0x00);
         
         Usb_write_byte(0x02);   // wLength (data count = 2)
         Usb_write_byte(0x00);
         
         Usb_write_byte(LSB(serial_state.all));   // data 0: LSB first of serial state
         Usb_write_byte(MSB(serial_state.all));   // data 1: MSB follows
         Usb_ack_in_ready();
      }
      return 1;
   }
   return 0;
}//*/

//---------------------------------------------------------

/* OLD


// select = r24 passed from the bootloader
void __low_level_init(u8) __attribute__ ((section (".init3"),naked));
void __low_level_init(u8 u)
{
	select = u;
}

void usb_putc(u8 c)
{
	usb_putbuffer(&c, 1);
}

void usb_putbuffer(u8 *buffer, u8 nb_data)
{
	if(!Is_device_enumerated()) {
		return;
	}

	Usb_select_endpoint(TX_EP);
next:
	while(!Is_usb_write_enabled()); // Wait Endpoint ready
	while(nb_data) {
		Usb_write_byte(*buffer);
		buffer++;
		nb_data--;

		if(!Is_usb_write_enabled()) {
			Usb_ack_in_ready();
			goto next;
		}
	}
	Usb_ack_in_ready();
}*/

//---------------------------------------------------------
