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

.org 0x72 ;?
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
	ldi dataDir, (2<<ISC00)  
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
	;rcall delay
	nop

wait_release:
	sbis PIND, PIND0
		rjmp wait_release
	
	eor ledState, xorComparison
	
	reti
	
;----------------------------------------------------------------------
;
;----------------------------------------------------------------------	
delay:
	push ledState
	push xorComparison
	
    ldi  r18, 13
    ldi  r19, 252
L1: dec  r19
    brne L1
    dec  r18
    brne L1
    nop
	
	pop xorComparison
	pop ledState
	
	ret