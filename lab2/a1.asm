.include "m2560def.inc"

.def displayMode = r16
.def counter = r17
.def loopCounter = r19
.def dataDir = r18

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

main_loop:
	
	cpse displayMode, 0xFF
	rcall johnson_counter
	
	cpse displayMode, 0x00
	rcall ring_counter
	
	rjmp main_loop
	
ring_counter:
	out PORTB, counter
	rcall delay_led
	rol counter
	ret
	
johnson_counter:
	out PORTB, counter
	rcall delay_led
	
	sbis PORTB, PINB7
	rjmp count_up
	
	rjmp count_down
	
	count_up:
		lsl counter
		inc counter
		rjmp end
	 	
	count_down:
		lsr counter

	end:
		ret
	
delay_led:
	ldi loopCounter, 50
	
	loop_led:
	    ldi  r20, 3
	    ldi  r21, 152
	L1: dec  r21
	    brne L1
	    dec  r20
	    brne L1
	    nop
		
		sbis PORTC, PINC0
		rcall delay_switch
		
		sbrs loopCounter, 0x00
		ret
		dec loopCaounter
		
		rjmp loop_led
		
delay_switch:
    ldi  r20, 13
    ldi  r21, 252
L1: dec  r21
    brne L1
    dec  r20
    brne L1
    nop
	
	loop_switch:
		sbic PORTC, PINC0
		rjmp loop_switch
		
		cpse displayMode, 0xFF
		rjmp johnson_to_ring
	
		cpse displayMode, 0x00
		rjmp ring_to_johnson
		
		ring_to_jhonson:
			lsl counter
			dec counter
			
			rjmp switch_end
			
		johnson_to_ring:
			lsr counter
			inc counter
			
		switch_end:
			com displayMode
			ret
	