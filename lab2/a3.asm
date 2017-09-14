.include "m2560def.inc"

.def dataDir = r16
.def counter = r17

ldi r16, HIGH(RAMEND) 
out SPH, r16
ldi r16, LOW(RAMEND) 
out SPL, r16

ldi dataDir, 0xFF
out PORTB, dataDir

ldi dataDir, 0x00
out PORTC, dataDir

ldi counter, 0x00

loop:
	sbis PORTC, PINC0
		rcall switch_down
	rjmp loop
	
switch_down:
    ldi  r20, 13
    ldi  r21, 252
L1: dec  r21
    brne L1
    dec  r20
    brne L1
    nop
	
	inc counter
	out PORTB, counter
	
	loop_2:
		sbic PORTC, PINC0
			rjmp switch_released
		rjmp loop_2
	
	switch_released:
		inc counter
		out PORTB, counter
		ret