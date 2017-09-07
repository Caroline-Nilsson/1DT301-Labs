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
;   Function:           Turns on LED0 when SW5 is held down.
;
;   Input ports:        PORTC
;
;   Output ports:       PORTB
;
;   Subroutines:        N/A
;   Included files:     m2560def.inc
;
;   Other information:  N/A
;
;   Changes in program: 
;                       2017-09-01:
;                       Implemented flowchart design.
;
;                       2017-09-04:
;                       Minor refactoring. Adds header and comments.
;
;                       2017-09-07:
;                       Adjusts code to handle pull up resistor on PORTB.
;                       Changes switch port to PORTC.
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
.include "m2560def.inc"
.def dataDir = r16
.def ledState = r17

; Set PortB as output
ldi dataDir, 0xFF
out DDRB, dataDir

; Set PortC as input
ldi dataDir, 0x00
out DDRC, dataDir

loop:
    ser ledState                    ; Set bits in LED state so LEDs are turned 
                                    ; off when button is released

    sbis PINC, PINC5                ; If SW5 is pressed down (PINC5 bit is zero)
        ldi ledState, 0xFE          ;   then set LED0 state to turned on

    out PORTB, ledState             ; write state to LEDs
    rjmp loop
