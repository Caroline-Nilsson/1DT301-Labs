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

.inc "m2560def.inc"

.def temp = r16
.def ledState = r17
.def counter = r18

.equ COMPARISON = 2
.equ INIT_TIMER_VALUE = 6

.cseg

;Initialize starting point for program
.org 0
rjmp reset

;Initialize timer overflow interrupt vector
.org ovf0addr
rjmp interrupt

.org 0x72
reset:
;Initialize Stack Pointer
ldi temp, LOW(RAMEND)
out SPL, temp
ldi temp, HIGH(RAMEND)
out SPH, temp

;PortB, Pin0 = output
ldi temp, 0x01
out DDRB, temp

;set prescale to 1024
ldi temp, 0x05
out TCCR0B, temp

;enable overflow flag
ldi temp, (1<<TOIE0)
out TIMSK0, temp

;set default value for timer
ldi temp, INIT_TIMER_VALUE	
out TNCT0, temp

sei
clr ledState

main_loop:
	out PORTB, ledState
	rjmp main_loop
	
interrupt:
	:save Status Register in Stack
	in temp, sreg
	push temp
	
	:set start value for timer
	ldi temp, INIT_TIMER_VALUE	
	out TNCT0, temp
	
	inc counter
	
	;if counter = 2, branch to change_led_state
	cpi counter, COMPARISON
	breq change_led_state
	
	rjmp end
	
	change_led_state:
		com ledState
		clr counter
		
	end:
		pop temp
		out sreg, temp
		reti