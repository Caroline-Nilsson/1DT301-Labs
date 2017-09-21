;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;   1DT301, Computer Technology I
;   Date: 2017-09-07
;   Author:
;                       Caroline Nilsson            (cn222nd)
;                       Daniel Alm Grundström       (dg222dw)
;
;   Lab number:         2
;   Title:              Subroutines
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
;   Subroutines:        wait_milliseconds - Delays executions n milliseconds.
;   Included files:     m2560def.inc
;
;   Other information:  N/A
;
;   Changes in program: 
;                       2017-09-14:
;                       Implements flowchart design
;
;                       2017-09-19:
;                       Adds header, comments and some minor refactoring
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
.include "m2560def.inc"
.def dataDir = r16
.def ledState = r17
.def complement = r18
.def waitH = r25
.def waitL = r24
.equ INITIAL_LED_STATE = 0x01

; Initialize SP, Stack Pointer
ldi r20, HIGH(RAMEND)                   ; R20 = high part of RAMEND address
out SPH,R20                             ; SPH = high part of RAMEND address
ldi R20, low(RAMEND)                    ; R20 = low part of RAMEND address
out SPL,R20                             ; SPL = low part of RAMEND address

; Set PORTB to output
ldi dataDir, 0xFF
out DDRB, dataDir

ldi ledState, INITIAL_LED_STATE         ;Set initial LED state

loop1:
	mov complement, ledState            
	com complement
    out PORTB, complement               ;Write complement of LED state to LEDs

    ldi waitH, HIGH(100)
	ldi waitL, LOW(100)
	rcall wait_milliseconds             ;Delay to make changes visible

    sbis PORTB, PINB7                   ;If leftmost LED is lit
		ldi ledstate, INITIAL_LED_STATE ;   then reset LED State
	sbic PORTB, PINB7                   ;Else
		lsl ledState                    ;   Shift LED state to the left 
    rjmp loop1

;Wait n milliseconds. The number of milliseconds to wait is provided through
;registers 25:24.
wait_milliseconds:
	loop2:
		cpi waitL, 0x00             ;If lower bit of register pair 'wait' is 0
		breq low_zero               ;   then jump to low_zero
		rjmp wait                   ;Else jump to wait
		
	low_zero:
		cpi waitH, 0x00             ;If higher bit of register pair 'wait' is 0
		breq high_zero              ;   then jump to high_zero
		rjmp wait                   ;Else jumpt to wait
		
	high_zero:
		ret
			
	wait:
		sbiw waitH:waitL, 0x01      ;Decrement register pair 'wait'
	    
        ;Delay 1 ms
		ldi  r20, 2
	    ldi  r19, 74
	L1: dec  r19
	    brne L1
	    dec  r20
	    brne L1
	    rjmp PC+1
		
	    rjmp loop2
