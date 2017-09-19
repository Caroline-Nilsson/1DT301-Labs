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
;   Function:           Counts number of times switch SW0 changes values, i.e.
;                       how many times the switch goes from 0 to 1 and 1 to 0.
;
;                       The counter is outputted to the LEDs in binary form
;                       each time the counter gets incremented.
;
;   Input ports:        PIN0 on PORTC
;
;   Output ports:       PORTB
;
;   Subroutines:        wait_for_switch_press   - Delays execution of the 
;                                                 Program until SW0 is press
;                       on_switch_down          -
;                       wait_for_switch_release -
;                       on_switch_up            -
;                       led_out                 -
;                       delay_switch            -   
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
;                       Refactors the code by breaking smaller subroutines into
;                       multiple smaller ones. Adds comments 
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
.include "m2560def.inc"

.def dataDir = r16
.def counter = r17
.def complement = r18
	
ldi r16, HIGH(RAMEND) 
out SPH, r16
ldi r16, LOW(RAMEND) 
out SPL, r16

ldi dataDir, 0xFF
out DDRB, dataDir

ldi dataDir, 0x00
out DDRC, dataDir

ldi counter, 0x00
rcall led_out

main_loop:
    rcall wait_for_switch_press
	rcall on_switch_down

    rcall wait_for_switch_release
    rcall on_switch_up	

	rjmp main_loop
	
;Pauses execution of program until SW0 is pressed down
wait_for_switch_press:
    loop:
        sbic PINC, PINC0                ;If SW0 is not pressed down
            rjmp loop                   ;   then continue waiting
    ret                                 ;return when SW0 gets pressed down

;Handles what should happen when SW0 gets pressed down
on_switch_down:
    rcall delay_switch                  ;Delay to avoid bouncing effects
	inc counter
    rcall led_out                       ;Output new counter value
	ret

;Pauses execution of program until SW0 is released
wait_for_switch_release:
	loop_2:
	    sbis PINC, PINC0                ;If SW0 is still pressed down
		    rjmp loop_2                 ;   then continue waiting
    ret                                 ;return when SW0 gets released

;Handles what should happen when SW0 gets released
on_switch_up:
	inc counter
    rcall led_out                       ;Output new counter value
    ret

;Outputs a binary representation of the current counter value to the LEDs
led_out:
    mov complement, counter 
    com complement
    out PORTB, complement

;Delay of 10 ms. Used to avoid effects of switch bouncing 
delay_switch:
    ldi  r31, 13
    ldi  r30, 252
    L1:
        dec  r30
    brne L1
    dec  r31
    brne L1
    nop

    ret
