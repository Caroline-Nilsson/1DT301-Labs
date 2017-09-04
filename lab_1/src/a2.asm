;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;   1DT301, Computer Technology I
;   Date: 2017-09-02
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
;   Input ports:        PORTD
;
;   Output ports:       PORTB
;
;   Subroutines:        N/A
;   Included files:     m2560def.inc
;
;   Other information:  Since a pressed switch is registered as a 0 and a
;                       released switch is registered as a 1. The bit string
;                       read from PORTD must be inverted before the output
;                       is redirected to the LEDs.
;
;   Changes in program: 
;                       2017-09-01:
;                       Implemented flowchart design.
;
;                       2017-09-02:
;                       Adds header and comments.
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
.include "m2560def.inc"
.def switchInput = r16
.def ledOutput = r17

; Set PORTB (LEDs) as output
ldi switchInput, 0xFF
out DDRB, switchInput

; Set PORTD (switches) as input
ldi ledOutput, 0x00
out DDRD, ledOutput

loop:
    in switchInput, PIND        ; Read input from switches
    com switchInput             ; Invert input bit string
    out PORTB, switchInput      ; Output inverted bit string to LEDs
    rjmp loop
