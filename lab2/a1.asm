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
;   Function:           Counts up a counter and display it's value as either a 
;                       Ring counter or Johnson counter. The display mode can 
;                       be toggled between ring/johnson by pressing switch SW0.
;
;   Input ports:        PIN0 on PORTC
;
;   Output ports:       PIN2 on PORTB
;
;   Subroutines:        led_out           - Outputs counter to LEDs
;                       delay_led         - Delay to make changes to LEDs 
;                                           visible. Also continuously checks 
;                                           if switch is pressed.
;                       ring_counter      - Counts up ring counter
;                       johnson_counter   - Counts johnson counter up/down
;                       check_switch      - Checks if switch gets pressed
;                       on_switch_pressed - Handles what should happen when 
;                                           switch gets pressed
;                       delay_short       - Short delay of 2 ms used between 
;                                           switch checks
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
;                       Refactors code by breaking down large subroutines
;                       into smaller subroutines.
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
.include "m2560def.inc"

.def displayMode = r16					;determines whether to output ring or johnson
.def counter = r17						;keeps track of output value
.def dataDir = r18						;use to set input and output on PORTs
.def loopCounter = r19					;counts number of loops in delay led
.def johnUpOrDown = r20					;whether to count johnson value up or down
.def complement = r21					;temp, to output counters complement
.equ UP = 0x01							;constant: value of up
.equ DOWN = 0x00						;constant: value of down
.equ JOHNSON = 0x00                     ;constant: Johnson display mode
.equ RING = 0xFF                        ;constant: Ring display mode
.equ SWITCH = PINC0                     ;constant: PIN of switch to check

;Initialize stack pointer
ldi r18, HIGH(RAMEND) 
out SPH, r18
ldi r18, LOW(RAMEND) 
out SPL, r18

;set PORTB to output
ldi dataDir, 0xFF
out DDRB, dataDir

;set PORTC to input
ldi dataDir, 0x00
out DDRC, dataDir

;initialize starting state
ldi displayMode, JOHNSON
ldi counter, 0x01
ldi johnUpOrDown, UP

main_loop:
    rcall led_out
	rcall delay_led
	
	cpi displayMode, JOHNSON			;if displaymode = johnson
	    breq johnson					;then jump to johnson branch

    ring:                               ;else jump to ring
	    rcall ring_counter              
        rjmp main_loop
	
	johnson:
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
	ldi loopCounter, 50
	
	loop_led:
        rcall delay_short		
        rcall check_switch
	
	    cpi loopCounter, 0				;if loopcounter = 0
	    breq delay_led_end				;then jump to end
	
        dec loopCounter
        rjmp loop_led
		
	delay_led_end:
		ret

;Creates the ring counter by writing the complement of counter
;to PORTB and then increments the ring counter
ring_counter:
	sbis PORTB, PINB7					;if the 7th led is lit
		ldi counter, 0x01				;then set counter to one

	sbic PORTB, PINB7					;else
		lsl counter						;shift counter to the left

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
		inc counter						;add one
		rjmp end
	 	
	;checks whether to continue to count down and
	;decrese the johnson value
	count_down:
		sbic PORTB, PINB0				;if the right most led is not lit
			rjmp count_up				;then jump to count up

		ldi johnUpOrDown, DOWN			
		lsr counter						;shift to the right

	end:
		ret


;Checks if the switch is pressed and in that case calls on_switch_pressed
check_switch:
	sbic PINC, SWITCH				    ;if switch is not pressed
        rjmp check_switch_end           ;then jump to end of subroutine

    switch_pressed_down:
        rcall delay_switch

        ;wait until button is released
        loop_switch:
            sbis PINC, SWITCH           ;if switch to the right most is still pressed
            rjmp loop_switch			;then jump to loop switch
        
        ;When the button has been released we consider the switch pressed
        rcall on_switch_pressed

    check_switch_end:
    ret

	
;Handles what should happen when the switch gets pressed
on_switch_pressed:
	cpi displayMode, JOHNSON			;if displaymode = johnson
	breq johnson_to_ring				;then jump to johnson to ring
	
	cpi displayMode, RING 				;if displaymode = ring
	breq ring_to_johnson				;then jump to ring to johnson
		
	;convert ring value to johnson value
	ring_to_johnson:
		lsl counter
		dec counter
			
		rjmp switch_end
	
	;convert johnson value to ring value
	johnson_to_ring:
		lsr counter
		inc counter
			
	switch_end:
		com displayMode					;toogle displaymode between ring and johnson
    ret

;Delay for 2 ms
delay_short:
    ldi  r31, 13
    ldi  r30, 252
    L1:
        dec  r30
    brne L1
    dec  r31
    brne L1
    nop

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
