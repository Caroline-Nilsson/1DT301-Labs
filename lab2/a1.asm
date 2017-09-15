.include "m2560def.inc"

.def displayMode = r16					;determens wheter to output ring or johnson
.def counter = r17						;keeps track of output value
.def loopCounter = r19					;counts number of loops in delay led
.def dataDir = r18						;use to set input and output on PORTs
.def johnUpOrDown = r22					;whether to count johnson value up or down
.def complement = r23					;temp, to output counters complement
.equ UP = 0x01							;constant: value of up
.equ DOWN = 0x00						;constant: value of down

;TODO: define constants for johnson mode and ring mode

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
ldi displayMode, 0x00
ldi counter, 0x01
ldi johnUpOrDown, UP

main_loop:
	
	cpi displayMode, 0x00				;if displaymode = johnson
	breq johnson						;then jump to johnson branch

	cpi displayMode, 0xFF				;if displaymode = ring
	breq ring							;then jump to ring
	
	johnson:
		rcall johnson_counter
		rjmp main_loop

	ring:
		rcall ring_counter

	rjmp main_loop

;Creates the ring counter by writing the complement of counter
;to PORTB and then increments the ring counter
ring_counter:
	; TODO: Move this to beginning of main_loop
	mov complement, counter
	com complement
	out PORTB, complement
	rcall delay_led

	cpi displayMode, 0x00				;if displaymode = johnson
	breq ring_end						;then jump to end
	
	sbis PORTB, PINB7					;if the 7th led is lit
		ldi counter, 0x01				;then set counter to one

	sbic PORTB, PINB7					;else
		lsl counter						;shift counter to the left

	ring_end:
	ret
	
;Creates the johnson counter by writing the complement of counter 
;to PORTB and then checks wheter to count up or down
johnson_counter:
	; TODO: Move this to beginning of main_loop
	mov complement, counter
	com complement
	out PORTB, complement
	rcall delay_led
	
	cpi displayMode, 0xFF				;if displaymode = ring
	breq end							;then jump to end

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

;Delay with continuous switch checking	
delay_led:
	ldi loopCounter, 50
	
	loop_led:
    ldi  r31, 13
    ldi  r30, 252
L1: dec  r30
    brne L1
    dec  r31
    brne L1
    nop


		
		sbis PINC, PINC0				;if right most switch is pressed
		rcall delay_switch				;then jump to delay switch
		
		cpi loopCounter, 0				;if loopcounter = 0
		breq delay_led_end				;then jump to end
		
		dec loopCounter					;subtract one
		
		rjmp loop_led
		
	delay_led_end:
		ret

;Delay to avoid bouncing when switch is pressed
delay_switch:
    ldi  r20, 13
    ldi  r21, 252
L2: dec  r21
    brne L2
    dec  r20
    brne L2
    nop
	
	;wait for button release
	loop_switch:
		sbis PINC, PINC0				;if switch to the right most is still pressed
		rjmp loop_switch				;then jump to loop switch
		
	cpi displayMode, 0x00				;if displaymode = johnson
	breq johnson_to_ring				;then jump to johnson to ring
	
	cpi displayMode, 0xFF				;if displaymode = ring
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
	