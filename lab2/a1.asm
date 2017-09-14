.include "m2560def.inc"

.def displayMode = r16
.def counter = r17
.def loopCounter = r19
.def dataDir = r18
.def johnUpOrDown = r22
.def complement = r23
.equ UP = 0x01
.equ DOWN = 0x00

ldi r18, HIGH(RAMEND) 
out SPH, r18
ldi r18, LOW(RAMEND) 
out SPL, r18

ldi dataDir, 0xFF
out DDRB, dataDir

ldi dataDir, 0x00
out DDRC, dataDir

ldi displayMode, 0x00
ldi counter, 0x01
ldi johnUpOrDown, UP

main_loop:
	
	cpi displayMode, 0x00
	breq johnson

	cpi displayMode, 0xFF
	breq ring
	
	johnson:
		rcall johnson_counter
		rjmp main_loop

	ring:
		rcall ring_counter

	rjmp main_loop
	
ring_counter:
	mov complement, counter
	com complement
	out PORTB, complement
	rcall delay_led

	cpi displayMode, 0x00
	breq ring_end
	
	sbis PORTB, PINB7
		ldi counter, 0x01

	sbic PORTB, PINB7
		lsl counter

	ring_end:
	ret
	
johnson_counter:
	mov complement, counter
	com complement
	out PORTB, complement
	rcall delay_led
	
	cpi displayMode, 0xFF
	breq end

	cpi johnUpOrDown, UP
	breq count_up
	
	rjmp count_down
	
	count_up:
		sbis PORTB, PINB7
			rjmp count_down

		ldi johnUpOrDown, UP
		lsl counter
		inc counter
		rjmp end
	 	
	count_down:
		sbic PORTB, PINB0
			rjmp count_up
		ldi johnUpOrDown, DOWN
		lsr counter

	end:
		ret
	
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


		
		sbis PINC, PINC0
		rcall delay_switch
		
		cpi loopCounter, 0
		breq delay_led_end
		
		dec loopCounter
		
		rjmp loop_led
		
	delay_led_end:
		ret

delay_switch:
    ldi  r20, 13
    ldi  r21, 252
L2: dec  r21
    brne L2
    dec  r20
    brne L2
    nop
	
	loop_switch:
		sbis PINC, PINC0
		rjmp loop_switch
		
		cpi displayMode, 0x00
		breq johnson_to_ring
	
		cpi displayMode, 0xFF
		breq ring_to_johnson
		
		ring_to_johnson:
			lsl counter
			dec counter
			
			rjmp switch_end
			
		johnson_to_ring:
			lsr counter
			inc counter
			
		switch_end:
			com displayMode
			ret
	