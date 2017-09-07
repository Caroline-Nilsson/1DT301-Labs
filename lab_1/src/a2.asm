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
;   Function:           Reads input from the switches SW0..SW7 and lights the
;                       corresponding LED when a switch is pressed. (SW0 lights
;                       LED0, SW1 lights LED1 and so on)
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
;                       2017-09-02:
;                       Adds header and comments.
;
;                       2017-09-07:
;                       Adjusts code to handle pull up resistor on PORTB.
;                       Changes switch port to PORTC.
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
.include "m2560def.inc"
.def switchInput = r16
.def ledOutput = r17

; Set PORTB (LEDs) as output
ldi switchInput, 0xFF
out DDRB, switchInput

; Set PORTC (switches) as input
ldi ledOutput, 0x00
out DDRC, ledOutput

loop:
    in switchInput, PINC        ; Read input from switches
    out PORTB, switchInput      ; Output switch input to LEDs
    rjmp loop
