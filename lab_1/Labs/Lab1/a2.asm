.include "m2560def.inc"
.def switchInput = r16
.def ledOutput = r17

; Set PORTB as output and PORTD as input
ldi switchInput, 0xFF
out DDRB, switchInput
ldi ledOutput, 0x00
out DDRD, ledOutput

loop:
	in switchInput, PIND
	com switchInput
	out PORTB, switchInput
	rjmp loop