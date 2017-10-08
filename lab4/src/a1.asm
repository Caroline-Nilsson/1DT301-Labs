;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;   1DT301, Computer Technology I
;   Date: 2017-10-08
;   Author:
;                       Caroline Nilsson            (cn222nd)
;                       Daniel Alm Grundström       (dg222dw)
;
;   Lab number:         4
;   Title:              Timers & USART
;
;   Hardware:           STK600, CPU ATmega2560
;
;   Function:           Toggles LED0 on/off every 0.5 seconds using timers and
;						overflow interrupts.
;
;   Input ports:        N/A
;
;   Output ports:       PORTB, PINB0
;
;   Subroutines:        N/A
;   Included files:     m2560def.inc
;
;   Other information:  N/A
;
;   Changes in program: 2017-10-08
;						Adds file header with program description.
;                       
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

.include "m2560def.inc"

.def temp = r16
.def ledState = r17
.def counter = r18

.equ COMPARISON = 2
.equ PRESCALE = 0x05			; = 1024, for 1MHz -> 1 count/ms
.equ INIT_TIMER_VALUE = 5		; counter overflow every 250 ms = 1/4 sec 

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

;set prescale
ldi temp, PRESCALE
out TCCR0B, temp

;enable overflow flag
ldi temp, (1<<TOIE0)
sts TIMSK0, temp

;set default value for timer
ldi temp, INIT_TIMER_VALUE	
out TCNT0, temp

sei
clr ledState

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; Repeatedly outputs ledState while waiting for interrupt
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
main_loop:
	out PORTB, ledState
	rjmp main_loop

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; Timer0 overflow interrupt, triggered every 250 ms. Toggles led
; every 2 times the interrupt is triggered.
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
interrupt:
	;save Status Register on stack 
	in temp, SREG
	push temp
	
	;set start value for timer so next interrupt occurs after 250 ms
	ldi temp, INIT_TIMER_VALUE	
	out TCNT0, temp
	
	inc counter
	
	;if counter = 2, branch to change_led_state
	cpi counter, COMPARISON
	breq change_led_state
	
	rjmp end
	
	; Toggle LED0
	change_led_state:
		com ledState
		clr counter
		
	end:
		pop temp
		out SREG, temp
		reti
