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
;   Function:           Lights LED2 on PORTB
;
;   Input ports:        N/A
;
;   Output ports:       PIN2 on PORTB
;
;   Subroutines:        N/A
;   Included files:     m2560def.inc
;
;   Other information:  LEDs are configured to light when PINs on PORTB are set
;                       to 0. The default state, when no LED is lit must
;                       therefore be set to 0b1111_1111.
;
;   Changes in program: 
;                       2017-09-01:
;                       Implemented flowchart design.
;
;                       2017-09-02:
;                       Added comments and .def for r16
;
;                       2017-09-07:
;                       Adjusts code to handle pull-up resistors on PORTB.
;                       Removes unnecessary loop that prevented program from 
;                       exiting after LED2 had been turned on.
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
.include "m2560def.inc"
.def ledOutput = r16

; Set PORTB to output
ldi ledOutput, 0xFF
out DDRB, ledOutput

; Turn on LED2 on PORTB
ldi ledOutput, 0b1111_1011
out PORTB, ledOutput
