;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;   1DT301, Computer Technology I
;   Date: 2017-09-07
;   Author:
;                       Caroline Nilsson            (cn222nd)
;                       Daniel Alm Grundström       (dg222dw)
;
;   Lab number:         1
;   Title:              How to use the PORTs. Digital input /output.
;                       Subroutine call.
;
;   Hardware:           STK600, CPU ATmega2560
;
;   Function:           Repeatedly lights LEDs sequentially right to left.
;                       
;                       I.e:
;                       0000 0001 -> 0000 0010 -> 0000 0100 -> ... ->
;                       1000 0000 -> 0000 0001 -> 0000 0010 -> ...
;
;   Input ports:        N/A
;
;   Output ports:       PORTB
;
;   Subroutines:        delay - delays execution
;   Included files:     m2560def.inc
;
;   Other information:  Since a subroutine is used, the stack pointer must
;                       be initialized so the processor knows where in the 
;                       code to jump when the subroutine returns. 
;
;   Changes in program: 
;                       2017-09-01:
;                       Implements flowchart design
;
;                       2017-09-04:
;                       Adds header, comments and some minor refactoring
;
;                       2017-09-07:
;                       Adjusts code to handle pull up resistor on PORTB.
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
.include "m2560def.inc"
.def dataDir = r16
.def ledState = r17
.def waitH = r25
.def waitL = r24
.equ INITIAL_LED_STATE = 0xFF


; Initialize SP, Stack Pointer
ldi r20, HIGH(RAMEND)                   ; R20 = high part of RAMEND address
out SPH,R20                             ; SPH = high part of RAMEND address
ldi R20, low(RAMEND)                    ; R20 = low part of RAMEND address
out SPL,R20                             ; SPL = low part of RAMEND address

; Set PORTB to output
ldi dataDir, 0xFF
out DDRB, dataDir

ldi ledState, INITIAL_LED_STATE         ; Set initial LED state

loop:
    out PORTB, ledState                 ; Write state to LEDs
    ldi waitH, HIGH(500)
	ldi waitL, LOW(500)
	rcall wait_milliseconds             ; Delay to make changes visible
    rol ledState                        ; Rotate LED state to the left 
    rjmp loop

wait_milliseconds:
	loop:
		cpi waitL, 0x00
		breq low_zero
		rjmp wait
		
	low_zero:
		cpi waitH, 0x00
		breq high_zero
		rjmp wait
		
	high_zero:
		ret
			
	wait:
		sbiw waitH:waitL, 0x01
	    
		ldi  r18, 2
	    ldi  r19, 74
	L1: dec  r19
	    brne L1
	    dec  r18
	    brne L1
	    rjmp PC+1
		
	    rjmp loop