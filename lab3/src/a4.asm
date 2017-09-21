;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;   1DT301, Computer Technology I
;   Date: YYYY-MM-DD
;   Author:
;                       Caroline Nilsson            (cn222nd)
;                       Daniel Alm Grundström       (dg222dw)
;
;   Lab number:         
;   Title:              
;
;   Hardware:           STK600, CPU ATmega2560
;
;   Function:           
;
;   Input ports:        
;
;   Output ports:       
;
;   Subroutines:        
;   Included files:     m2560def.inc
;
;   Other information:  
;
;   Changes in program: 
;                       
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

.def dataDir = r16
.def ledState = r17
.def lightStatus = r18
.def counter = r19
.def complement = r20
.def xorComparison = r21

.equ TURN_RIGHT = 0
.equ TURN_LEFT = 7
.equ BRAKES = 2
.equ COUNTER_RIGHT_RESET = 0b0000_1000
.equ COUNTER_LEFT_RESET = 0b0001_0000

.cseg

.org 0x00
rjmp start

.org int0addr
rjmp interrupt_right

.org int1addr
rjmp interrupt_left

.org int2addr
rjmp interrupt_brake

.org 0x72

start:
;Initialize stack pointer
ldi r16, HIGH(RAMEND) 
out SPH, r16
ldi r16, LOW(RAMEND) 
out SPL, r16

;set PORTB to output
ldi dataDir, 0xFF
out DDRB, dataDir

;set PORTD to input
ldi dataDir, 0x00
out DDRD, dataDir

;initialize starting state
clr lightStatus

ldi dataDir, (7<<int0)
out EIMSK, dataDir
ldi dataDir, (1<<ISC00) | (1<<ISC10) | (1<<ISC20)
sts EICRA, dataDir
sei

main_loop:
	ldi ledState, 0b1100_0011
	
	sbrc lightStatus, BRAKES
		rcall brake

	sbrc lightStatus, TURN_LEFT
		rcall blink_left
	sbrc lightStatus, TURN_RIGHT
		rcall blink_right

	rcall led_out
	rcall delay_led
	rjmp main_loop

blink_left:
	cbr ledState, 0xF0
	or ledState, counter
	clc
	lsl counter
	brcc end_left

	ldi counter, COUNTER_LEFT_RESET
	
	end_left:
		ret

blink_right:
	cbr ledState, 0x0F
	or ledState, counter
	lsr counter
	cpi counter, 1
	brge end_right

	ldi counter, COUNTER_RIGHT_RESET

	end_right:
		ret

brake:
	ser ledstate
	
	ret
led_out:
	mov complement, ledState
	com complement
	out PORTB, complement
	ret

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

delay_switch:
	ldi  r30, 130
    ldi  r29, 222
L2: dec  r29
    brne L2
    dec  r30
    brne L2
    nop
	ret


interrupt_right:
	rcall delay_switch

	sbrc lightStatus, TURN_LEFT
		reti

	cbr lightStatus, 0b1000_0000
	ldi xorComparison, 0b0000_0001
	eor lightStatus, xorComparison
	ldi counter, COUNTER_RIGHT_RESET
	reti

interrupt_left:
	rcall delay_switch

	sbrc lightStatus, TURN_RIGHT
		reti

	cbr lightStatus, 0b0000_0001
	ldi xorComparison, 0b1000_0000
	eor lightStatus, xorComparison
	ldi counter, COUNTER_LEFT_RESET
	reti
	
interrupt_brake:
	rcall delay_switch
		
	ldi xorComparison, 0b0000_0100
	eor lightStatus, xorComparison
	reti