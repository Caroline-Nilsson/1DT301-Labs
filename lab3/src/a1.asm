;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;   1DT301, Computer Technology I
;   Date: YYYY-MM-DD
;   Author:
;                       Caroline Nilsson            (cn222nd)
;                       Daniel Alm Grundström       (dg222dw)
;
;   Lab number:         
;   Title:              
;
;   Hardware:           STK600, CPU ATmega2560
;
;   Function:           
;
;   Input ports:        
;
;   Output ports:       
;
;   Subroutines:        
;   Included files:     m2560def.inc
;
;   Other information:  
;
;   Changes in program: 
;                       
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

.include "m2560def.inc"

.def dataDir = r16
.def ledState = r17
.def xorComparison = r18

.equ XOR_BIT_STRING = 0b0000_0001

.cseg

.org 0x00
rjmp reset

.org int0addr
rjmp interrupt

.org 0x72 
reset: 
	ldi dataDir, LOW(RAMEND)
	out SPL, dataDir
	ldi dataDir, HIGH(RAMEND)
	out SPH, dataDir
	
	ser dataDir
	out DDRB, dataDir

	clr dataDir
	out DDRD, dataDir

	ser ledState
	ldi xorComparison, XOR_BIT_STRING
	
	ldi dataDir, (1<<int0)
	out EIMSK, dataDir
	ldi dataDir, (3<<ISC00)  
	sts EICRA, dataDir
	
	sei
	
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

main_loop:
	out PORTB, ledState

	rjmp main_loop

;----------------------------------------------------------------------
;
;----------------------------------------------------------------------

interrupt:
	eor ledState, xorComparison
	rcall delay
	reti	
;----------------------------------------------------------------------
;
;----------------------------------------------------------------------	
delay:
    ldi  r30, 2
    ldi  r19, 4
    ldi  r20, 187
L1: dec  r20
    brne L1
    dec  r19
    brne L1
    dec  r30
    brne L1
    nop
	ret
