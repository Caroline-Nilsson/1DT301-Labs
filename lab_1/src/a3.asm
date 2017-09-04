;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;   1DT301, Computer Technology I
;   Date: 2017-09-04
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
;   Function:           Turns on LED0 when SW5 is held down.
;
;   Input ports:        PORTD
;
;   Output ports:       PORTB
;
;   Subroutines:        N/A
;   Included files:     m2560def.inc
;
;   Other information:  As with assignment 2, we have to keep in mind that
;                       a pressed switch is registered as a 0.
;
;   Changes in program: 
;                       2017-09-01:
;                       Implemented flowchart design.
;
;                       2017-09-04:
;                       Minor refactoring. Adds header and comments.
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
.include "m2560def.inc"
.def dataDir = r16
.def ledState = r17

; Set PortB as output
ldi dataDir, 0xFF
out DDRB, dataDir

; Set PortD as input
ldi dataDir, 0x00
out DDRD, dataDir

loop:
	clr ledState                    ; Clear LED state so LED is turned off when
                                    ; button is released

	sbis PIND, PIND5                ; If SW5 is pressed down (PIND5 bit is zero)
		ldi ledState, 0x01          ;   then set LED0 state to turned on

	out PORTB, ledState             ; write state to LEDs
	rjmp loop
