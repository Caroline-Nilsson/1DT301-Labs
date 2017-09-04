.include "m2560def.inc"
.def switchInput = r16
.def ledOutput = r17

; Set PortB as output
ldi ledOutput, 0xFF
out DDRB, ledOutput

; Set PortD as input
ldi switchInput, 0x00
out DDRD, switchInput

loop:
	clr switchInput
	sbis PIND, PIND5
		ldi switchInput, 0x01
	out PORTB, switchInput
	rjmp loop