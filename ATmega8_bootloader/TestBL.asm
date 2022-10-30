



#include <m8def.inc>


#define SELBIT  2
#define SELPORT PORTD // Gnd->resistor->switch->IO (270R)
#define SELDDR  DDRD
#define SELPIN	PIND

#define LEDBIT	4
#define LEDPORT PORTD // Vcc->resistor->led->IO (>=270R)
#define LEDDDR	DDRD
#define LEDPIN	PIND


.cseg
.org 0
	cbi		SELDDR,SELBIT  //not needed ?
	sbi		SELPORT,SELBIT //pullup
	sbi		LEDPORT,LEDBIT //led off
	sbi		LEDDDR,LEDBIT  //led

next:
	rcall	Delay150
	in		r16,LEDPORT
	ldi		r17,(1<<LEDBIT)
	eor		r16,r17
	out		LEDPORT,r16

	sbic	SELPIN,SELBIT  //if(SEL pressed)
	rjmp	next

	sbi		LEDPORT,LEDBIT //led off


	clt		//go to BL
	rjmp	FLASHEND


Delay150:
	ldi		r16,150

Delay:	// r16 = delay in ms -- const r16
	push	r16
	push	r17
	push	r18
D16:
	ldi		r17,38
	D17:
		ldi		r18,48 //==195 clks * 38 //for 7.3728MHz
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
