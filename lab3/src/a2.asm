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

.include "m2560def.inc"

.def displayMode = r16					;determines whether to output ring or johnson
.def counter = r17						;keeps track of output value
.def dataDir = r18						;use to set input and output on PORTs
.def johnUpOrDown = r20					;whether to count johnson value up or down
.def complement = r21					;temp, to output counters complement
.equ UP = 0x01							;constant: value of up
.equ DOWN = 0x00						;constant: value of down
.equ JOHNSON = 0x00                     ;constant: Johnson display mode
.equ RING = 0xFF                        ;constant: Ring display mode
.equ SWITCH = PIND0                     ;constant: PIN of switch to check

.cseg

.org 0x00
rjmp start

.org int0addr
rjmp interrupt

.org 0x72

start:
;Initialize stack pointer
ldi r18, HIGH(RAMEND) 
out SPH, r18
ldi r18, LOW(RAMEND) 
out SPL, r18

;set PORTB to output
ldi dataDir, 0xFF
out DDRB, dataDir

;set PORTD to input
ldi dataDir, 0x00
out DDRD, dataDir

;initialize starting state
ldi displayMode, JOHNSON
ldi counter, 0x01
ldi johnUpOrDown, UP

ldi dataDir, (1<<int0)
out EIMSK, dataDir
ldi dataDir, (2<<ISC00)
sts EICRA, dataDir

sei

main_loop:
	cpi displayMode, JOHNSON			;if displaymode = johnson
	    breq johnson1					;then jump to johnson branch

    ring1:                               ;else jump to ring
	    rcall ring_counter              
        rjmp main_loop
	
	johnson1:
		rcall johnson_counter

	rjmp main_loop

;Outputs complement of the current value of counter to LEDs
led_out:
    mov complement, counter
    com complement
    out PORTB, complement
    ret

;Delay with continuous switch checking	
delay_led:
	push johnUpOrDown
	
    ldi  r18, 3
    ldi  r19, 138
    ldi  r20, 86
L1: dec  r20
    brne L1
    dec  r19
    brne L1
    dec  r18
    brne L1
    rjmp PC+1
   
	pop johnUpOrDown

	ret

;Creates the ring counter by writing the complement of counter
;to PORTB and then increments the ring counter
ring_counter:
	sbis PORTB, PINB7					;if the 7th led is lit
		ldi counter, 0x01				;then set counter to one

	sbic PORTB, PINB7					;else
		lsl counter
								;shift counter to the left
	rcall led_out
	rcall delay_led

	ret
	
;Creates the johnson counter by writing the complement of counter 
;to PORTB and then checks wheter to count up or down
johnson_counter:
	cpi johnUpOrDown, UP				;if count up is active
	breq count_up						;then jump to count up
	
	rjmp count_down						;else jump to count down
	
	;checks whether to continue to count up and 
	;increments the johnson value
	count_up:
		sbis PORTB, PINB7				;if the 7th led is lit
			rjmp count_down				;then jump to count down

		ldi johnUpOrDown, UP			
		lsl counter						;shift to the left
		inc counter
										;add one
		
		rjmp end
	 	
	;checks whether to continue to count down and
	;decrese the johnson value
	count_down:
		sbic PORTB, PINB0				;if the right most led is not lit
			rjmp count_up				;then jump to count up

		ldi johnUpOrDown, DOWN			
		lsr counter	
							;shift to the right

	end:
		rcall led_out
		rcall delay_led
		
		ret


;Delay 10 ms to avoid bouncing when switch is pressed
delay_switch:
    ldi  r31, 13
    ldi  r30, 252
L2: dec  r30
    brne L2
    dec  r31
    brne L2
    nop

	ret

interrupt:
	rcall delay_switch
	
	switch_release:
	sbis PIND, SWITCH
		rjmp switch_release
	
	cpi displayMode, JOHNSON
	breq johnson_to_ring
	
	ring_to_johnson:	
		lsl counter
		dec counter
		rcall led_out
		rcall delay_led
			
		rjmp switch_end
	
	;convert johnson value to ring value
	johnson_to_ring:
		lsr counter
		inc counter
			
	switch_end:
		com displayMode
		
	

    pop dataDir
	sei
	rjmp main_loop
		