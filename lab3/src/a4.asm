;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;   1DT301, Computer Technology I
;   Date: 2017-09-25
;   Author:
;                       Caroline Nilsson            (cn222nd)
;                       Daniel Alm Grundström       (dg222dw)
;
;   Lab number:         3
;   Title:              Interrupts
;
;   Hardware:           STK600, CPU ATmega2560
;
;   Function:           Simulates the rear lights on a car using LED.
;						Default light -> back lights
;						Holding down Switch0 -> blinking right
;						Holding down Switch1 -> blinking left
;						Holding down Switch2 -> brake
;						but not possible to blink right and left
;						at the same time but possible to brake and
;						blink
;
;   Input ports:       	PORTD
;
;   Output ports:      	PORTB
;
;   Subroutines:      	blink_left		-toogle LED for left blinking
;						blink_right		-toogle LED for right blinking
;						brake			-toogle LEDs for braking
;						led_out			-outputs ledState to PORTB
;						delay_led		-delay to show changes made to LEDs
;										 500 ms
;						delay_switch	-delay to avoid bouncing
;										 100 ms
;						
;   Included files:     m2560def.inc
;
;   Other information:  back lights->	LED - 0,1,6,7 is lit
;						blink right->	LED - 6,7 lit 
;						and toogle between having LED 3,2,1,0 lit
;						blink left->	LED - 0,1 lit
;						and toogle between having LED 4,5,6,7 lit
;						brake->			lit all LEDs
;
;   Changes in program: 2017-09-20
;						Implementation of flowchart design
;
;						2017-09-21
;						Bugfixes during laboratory
;
;						2017-09-25
;						Overview code and commentary,
;                       missing commentary added
;                       
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

.def temp = r16
.def ledState = r17			;LED output value
.def lightStatus = r18		;masking register for backlight modes
.def counter = r19			;used in blink subroutines
.def complement = r20		;used to output complement of ledState
.def xorComparison = r21	;used to toogle bits in lightStatus

.equ TURN_RIGHT = 0			;mask for right blinking bit
.equ TURN_LEFT = 7			;mask for left blinking bit
.equ BRAKES = 2				;mask for brake bit
.equ COUNTER_RIGHT_RESET = 0b0000_1000	;blink right starting state
.equ COUNTER_LEFT_RESET = 0b0001_0000	;blink left starting state

.cseg

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; initialize starting point for program
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
.org 0x00
rjmp start

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; initialize interrupt starting point for Switch0
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
.org int0addr
rjmp interrupt_right

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; initialize interrupt starting point for Switch1
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
.org int1addr
rjmp interrupt_left

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; initialize interrupt starting point for Switch2
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
.org int2addr
rjmp interrupt_brake

.org 0x72

start:
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; Initialize stack pointer
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
ldi r16, HIGH(RAMEND) 
out SPH, r16
ldi r16, LOW(RAMEND) 
out SPL, r16

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; set PORTB to output
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
ldi temp, 0xFF
out DDRB, temp

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; set PORTD to input
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
ldi temp, 0x00
out DDRD, temp

clr lightStatus							;initialize starting state

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; enable external interrupt on PIND0, PIND1 and PIND2
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
ldi temp, (7<<int0)
out EIMSK, temp

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; set interrupt sense control to "Any edge"
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
ldi temp, (1<<ISC00) | (1<<ISC10) | (1<<ISC20)
sts EICRA, temp
	
sei

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; sets backlight strings to ledState
; calls subroutine blink_left/blink_right/brake depending on
; lightStatus state
; calls led_out and delay_led
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
main_loop:
	ldi ledState, 0b1100_0011		;set default LED state
	
	sbrc lightStatus, BRAKES
		rcall brake

	sbrc lightStatus, TURN_LEFT
		rcall blink_left
	sbrc lightStatus, TURN_RIGHT
		rcall blink_right

	rcall led_out
	rcall delay_led
	rjmp main_loop

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; clears left side of ledState, rotate counter bit in range
; 4, 5, 6, 7 and adds it to ledState
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
blink_left:
	cbr ledState, 0xF0
	or ledState, counter
	clc									;clear carry flag
	lsl counter
	brcc end_left						;if carry is clear jump 
										;to end_left 

	ldi counter, COUNTER_LEFT_RESET		;else reset counter to
										;starting value
	
	end_left:
		ret

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; clears right side of ledState, rotate counter bit in range
; 3, 2, 1, 0 and adds it to ledState
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
blink_right:
	cbr ledState, 0x0F
	or ledState, counter
	lsr counter
	cpi counter, 1
	brge end_right						;if counter ≥1 jump to
										;end_right

	ldi counter, COUNTER_RIGHT_RESET	;else reset counter to
										;starting value

	end_right:
		ret

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; sets all bits in ledState
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
brake:
	ser ledstate
	
	ret

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; outputs complement of ledstates current value to PORTB
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
led_out:
	mov complement, ledState
	com complement
	out PORTB, complement
	ret

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; 500 ms delay to show the LED output
;
; Generated by delay loop calculator
; at http://www.bretmulvey.com/avrdelay.html
;
; Delay 500 000 cycles
; 500ms at 1 MHz
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
delay_led:
	ldi  r31, 3
    ldi  r30, 138
    ldi  r29, 86
L1: dec  r29
    brne L1
    dec  r30
    brne L1
    dec  r31
    brne L1
    rjmp PC+1
	ret

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; 100 ms delay to avoid bouncing 
;
; Generated by delay loop calculator
; at http://www.bretmulvey.com/avrdelay.html
;
; Delay 100 000 cycles
; 100ms at 1 MHz
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
delay_switch:
	ldi  r30, 130
    ldi  r29, 222
L2: dec  r29
    brne L2
    dec  r30
    brne L2
    nop
	ret

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; calls delay, break if turn left is active otherwise toogle 
; lightStatus TURN_RIGHT bit ON/OFF and reset counter
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
interrupt_right:
	rcall delay_switch

	sbrc lightStatus, TURN_LEFT
		reti

	cbr lightStatus, 0b1000_0000
	ldi xorComparison, 0b0000_0001
	eor lightStatus, xorComparison		;RIGHT_TURN bit toogle
	ldi counter, COUNTER_RIGHT_RESET	;counter = starting bit string
	
	reti

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; calls delay, break if turn right is active otherwise toogle 
; lightStatus TURN_LEFT bit ON/OFF and reset counter
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
interrupt_left:
	rcall delay_switch

	sbrc lightStatus, TURN_RIGHT
		reti

	cbr lightStatus, 0b0000_0001
	ldi xorComparison, 0b1000_0000
	eor lightStatus, xorComparison		;LEFT_TURN bit toogle
	ldi counter, COUNTER_LEFT_RESET		;counter = starting bit string
	
	reti

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; calls delay, toogle lightStatus BRAKES bit ON/OFF
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<	
interrupt_brake:
	rcall delay_switch
		
	ldi xorComparison, 0b0000_0100		
	eor lightStatus, xorComparison		;BRAKES bit toogle
	reti