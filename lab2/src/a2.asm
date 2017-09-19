;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;   1DT301, Computer Technology I
;   Date: 2017-09-19
;   Author:
;                       Caroline Nilsson            (cn222nd)
;                       Daniel Alm Grundström       (dg222dw)
;
;   Lab number:         2
;   Title:              Subroutines
;
;   Hardware:           STK600, CPU ATmega2560
;
;   Function:           Generates a random value between 1 and 6 when the user 
;                       presses down switch SW0 and, when the user releases
;                       the switch, outputs a representation of a dice value
;                       to the LEDs
;
;   Input ports:        PIN0 on PORTC
;
;   Output ports:       PORTB
;
;   Subroutines:        generate_value    - Generate a pseudorandom value
;                                           between 1 and 6
;                       set_led_state     - Set value to output to LEDs
;                       delay_switch      - Delay of 10 ms used after switch is
;                                           pressed down
;
;   Included files:     m2560def.inc
;
;   Other information:  N/A
;
;   Changes in program: 
;                       2017-09-14:
;                       Implements flowchart design.
;
;                       2017-09-19:
;                       Adds constants for LED dice states and comments.
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
.include "m2560def.inc"

.def dataDir = r16
.def randomValue = r17
.def ledState = r18
.def complement = r19

.equ LED_DICE_1 = 0b0001_0000
.equ LED_DICE_2 = 0b0100_0100
.equ LED_DICE_3 = 0b0101_0100
.equ LED_DICE_4 = 0b1100_1100
.equ LED_DICE_5 = 0b1101_0110
.equ LED_DICE_6 = 0b1110_1110

ldi r16, HIGH(RAMEND) 
out SPH, r16
ldi r16, LOW(RAMEND) 
out SPL, r16

ldi dataDir, 0xFF
out DDRB, dataDir

ldi dataDir, 0x00
out DDRC, dataDir

ldi complement, 0xFF
out PORTB, complement

loop:
	sbic PINC, PINC0                    ;Wait until switch is pressed down
        rjmp loop
	
    rcall generate_value
	rcall set_led_state
	mov complement, ledState
	com complement
	out PORTB, complement

	rjmp loop
	
;Generate a pseudorandom value by repeatedly incrementing a counter for as long
;as the switch is pressed down
generate_value:
	ldi ledState, 0xFF					;Reset LEDs
	out PORTB, ledState
	start:
		
        rcall delay_switch              ;Delay to avoid bouncing effects

        inc randomValue
        cpi randomValue, 6
        brge reset_value
        rjmp end
	
	reset_value:
		ldi randomValue, 0
		
	end:	
		sbis PINC, PINC0                ;If switch is still pressed down
			rjmp start                  ;   then jump to start
		
		ret
	
;Set LED output value to bit pattern representing different dice values
;depending of value of the pseudorandomly generated value
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
			ldi ledState, LED_DICE_1
			rjmp end_led_state

		two:
			ldi ledState, LED_DICE_2
			rjmp end_led_state

		three:
			ldi ledState, LED_DICE_3
			rjmp end_led_state

	more:
		cpi randomValue, 3
		breq four

		cpi randomValue, 4
		breq five

		rjmp six

		four:
			ldi ledState, LED_DICE_4
			rjmp end_led_state

		five:
			ldi ledState, LED_DICE_5
			rjmp end_led_state

		six:
			ldi ledState, LED_DICE_6
			rjmp end_led_state

	end_led_state:
		ret

;Delay 10 ms to avoid bouncing effects when a switch is first pressed down
delay_switch:
    ldi  r31, 13
    ldi  r30, 252
    L1: 
        dec  r30
    brne L1
    dec  r31
    brne L1
    nop

    ret
