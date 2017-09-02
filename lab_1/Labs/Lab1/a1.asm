.include "m2560def.inc"

ldi r16, 0x20
out DDRB, r16

loop:
	out PORTB, r16
	rjmp loop