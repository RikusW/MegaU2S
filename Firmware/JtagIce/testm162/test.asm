// vim:ts=4 sts=0 sw=4

//I've set it to "Don't reprogram" because I enter and leave this a lot.
//Program this first using Tools->Program AVR

#include <m162def.inc>

.cseg
.org 0

	clr		r16
	clr		r16
	ori		r16,1
	ori		r16,2
	ori		r16,4
	nop
	break
	nop
	ori		r16,8
	ori		r16,0x1
	nop
dn:
	lsr		r16
	brne	dn
	nop
	break

	nop
	nop
	sts		0x100,r16
	nop
	nop

	clr		r16	
	ldi		r17,0x04
	ldi		r30,0x00
	ldi		r31,0x01
sn:
	st		Z+,r16
	cpi		r30,0xFF
	cpc		r31,r17
	brcs	sn
	nop
	nop
	break
	nop
	nop
	jmp		0
	nop
	rjmp	dn
	nop
	rjmp	sn
loop:
	nop
	nop
	nop
	rjmp	loop


.org 0x50
xxx://PORTB 4 24
	ldi		r16,0x56
	sts		0x105,r16
	nop
	sts		0x106,r16
	nop
	sts		0,r16
	nop
	rjmp	xxx




.org 0x80
yyy:
	ldi		r16,0x78
	sts		0x107,r16
	nop
	sts		0x108,r16
	nop
	sts		1,r16
	nop
	rjmp	yyy






