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
;   Changes in program: 2017-09-26
;                       Implements flowchart design.
;                       
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
.include "m2560def.inc"

.def temp = r16
.def ledState = r17     ; Value to be written to LEDs
.def complement = r18   ; Used when writing to LEDs
.def counter = r19      ; Keeps track of phase of cycle

; Current duty cycle. Can have a value between 0 (0%) 
; and 19 (100%), each increment adds 5% to the duty cycle
.def dutyCycle = r20

.equ INIT_TIMER_VALUE = 206             ; 256 - 50 = 206
.equ LED_OFF = 0x00
.equ LED_ON = 0x01
.equ DUTY_CYCLE_MIN = 0
.equ DUTY_CYCLE_MAX = 20

.cseg

; Initialize starting point for program
.org 0
rjmp reset

; Initialize timer overflow interrupt vector
.org OVF0ADDR
rjmp timer_interrupt

; Initialize SW0 interrupt vector
.org INT0ADDR
rjmp sw0_interrupt

; Initialize SW1 interrupt vector
.org INT1ADDR
rjmp sw1_interrupt

.org 0x72

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; reset - called on program start and on reset interrupts
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
reset:
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;Initialize Stack Pointer
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
ldi temp, LOW(RAMEND)
out SPL, temp
ldi temp, HIGH(RAMEND)
out SPH, temp

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; Initialize ports
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
;PortB, Pin0 = output
ldi temp, 0x01
out DDRB, temp

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; Initialize timer
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
; Set prescale to 1024
ldi temp, 0x05
out TCCR0B, temp

; Enable interrupt on timer overflow
ldi temp, (1<<TOIE0)
sts TIMSK0, temp

; Set default value for timer
ldi temp, INIT_TIMER_VALUE	
out TCNT0, temp

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; Initialize switch interrupts
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
; Enable interrupts for SW0 and SW1
ldi temp, (3 << INT0)
out EIMSK, temp

; Trigger interrupts on falling edge (switch released)
ldi temp, (3 << ISC00) | (3 << ISC10)
sts EICRA, temp

sei
clr ledState
ldi dutyCycle, 9

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; main_loop
;       Repeatedly write to LEDs while waiting for
;       interrupts.
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
main_loop:
    rcall led_out
	rjmp main_loop

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; led_out
;       Output complement of current LED state.
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
led_out:
    mov complement, ledState
    com complement
    out PORTB, complement
    ret
	
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; timer_interrupt
;       Interrupt called when a timer overflow occurs, 
;       which is set up to occur every 50 ms. 
;       
;       Compares the value of a counter to the current 
;       duty cycle. Depending on if the counter value is
;       higher or lower, the LED state will turn off or on.
;
;       For example, if the duty cycle is set to 4 (20%), 
;       then the LED state will be ON 4 out of the 20 
;       iterations this interrupt is triggered per second,
;       which means that the LED will be on for 0.2 
;       seconds and off for 0.8 seconds.
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
timer_interrupt:
	; Save Status Register on stack
	in temp, SREG
	push temp
	
	; Reset starting value for timer
	ldi temp, INIT_TIMER_VALUE	
	out TCNT0, temp

	cpi counter, DUTY_CYCLE_MAX
	brlo compare_duty_cycle

	ldi counter, DUTY_CYCLE_MIN

	compare_duty_cycle:
	cp counter, dutyCycle      ; if counter < dutyCycle
	brlo set_led_on             ;     then turn LED on
   	rjmp set_led_off            ; else turn LED off
	
    set_led_on:
        ldi ledState, LED_ON
        rjmp timer_int_end

    set_led_off:
        ldi ledState, LED_OFF
		
	timer_int_end:
	    inc counter
		pop temp
		out SREG, temp
		reti

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; sw0_interrupt 
;       Triggered when switch 0 is pressed Increments the 
;       duty cycle if it's not already at DUTY_CYCLE_MAX
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
sw0_interrupt:
    lds temp, PORTD
	
	sw0_loop:
    ldi  r31, 130
    ldi  r30, 222
L1: dec  r30
    brne L1
    dec  r31
    brne L1
    nop

	lds r29, PORTD
	cp temp, r29
	brne sw0_loop

    cpi dutyCycle, DUTY_CYCLE_MAX ; If dutyCycle == 20
    breq sw0_int_end              ;     then skip to end

    inc dutyCycle                 ; else increment dutyCycle

    sw0_int_end:
		ldi temp, 0x00
		sts EIFR, temp
        reti

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; sw1_interrupt
;       Triggered when switch 1 is pressed. Decrements the
;       duty cycle if it's not already at DUTY_CYCLE_MIN
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
sw1_interrupt:
	lds temp, PORTD
	
	sw1_loop:
    ldi  r31, 130
    ldi  r30, 222
L2: dec  r30
    brne L2
    dec  r31
    brne L2
    nop

	lds r29, PORTD
	cp temp, r29
	brne sw1_loop

    cpi dutyCycle, DUTY_CYCLE_MIN ; If dutyCycle == 0
    breq sw0_int_end              ;     then skip to end

    dec dutyCycle                 ; else decrement dutyCycle

    sw1_int_end:
		ldi temp, 0x00
		sts EIFR, temp
	    reti
