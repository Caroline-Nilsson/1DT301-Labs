.include "m2560def.inc"

.def dataDir = r16
.def randomValue = r17
.def ledState = r18

ldi r16, HIGH(RAMEND) 
out SPH, r16
ldi r16, LOW(RAMEND) 
out SPL, r16

ldi dataDir, 0xFF
out PORTB, dataDir

ldi dataDir, 0x00
out PORTC, dataDir

loop:
	
	sbis PORTC, PINC0
		rcall generate_value
	
	sbic PORTC, PINC0
		rcall set_led_state
	
	rjmp loop
	
generate_value:
    ldi  r20, 13
    ldi  r21, 252
L1: dec  r21
    brne L1
    dec  r20
    brne L1
    nop
	
	inc randomValue
	cpi randomValue, 6
	brge reset_value
	rjmp end
	
	reset_value:
		ldi randomValue, 0
		
	end:
		ret
	
set_led_state:
	cpi randomValue, 3
	brlo less 
	rjmp more
	
	less:
		cpi randomValue, 0
		breq one
		cpi randomValue, 1
		breq two
		rjmp three
		
		one:
			ldi ledState, 0b0001_0000
			rjmp end_led_state
		two:
			ldi ledState, 0b0100_0100
			rjmp end_led_state
		three:
			ldi ledState, 0b0101_0100
			rjmp end_led_state
	more:
		cpi randomValue, 3
		breq four
		cpi randomValue, 4
		breq five
		rjmp six
		four:
			ldi ledState, 0b1100_1100
			rjmp end_led_state
		five:
			ldi ledState, 0b1101_0110
			rjmp end_led_state
		six:
			ldi ledState, 0b1110_1110
			rjmp end_led_state
	end_led_state:
		out PORTB, ledState
		ret