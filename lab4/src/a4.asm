;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;   1DT301, Computer Technology I
;   Date: 2017-10-12
;   Author:
;                       Caroline Nilsson            (cn222nd)
;                       Daniel Alm Grundström       (dg222dw)
;
;   Lab number:         4
;   Title:              Timer and USART
;
;   Hardware:           STK600, CPU ATmega2560
;
;   Function:           Program that polls the serial port for input characters
;						and outputs them in ASCII binary to PORTB. In addition,
;						the received character is echoed back to the receiver.
;
;   Input ports:        RS232
;
;   Output ports:       PORTB, RS232
;
;   Subroutines:        led_output - outputs complement of register ledState
;									 to PORTB 
;   Included files:     m2560def.inc
;
;   Other information:  Putty is used to enter characters on the computer.
;
;   Changes in program: 2017-10-12
;						Adds comment header.
;
;						2017-09-27
;                       Implements flowchart design.
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
.include "m2560def.inc"

.def temp = r16
.def ledState = r17
.def complement = r18

.equ TRANSFER_RATE = 12 	;1MHz, 4800 bps

.org 0
rjmp reset

.org 0x72
reset:
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;Initialize Stack Pointer
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
ldi temp, LOW(RAMEND)
out SPL, temp
ldi temp, HIGH(RAMEND)
out SPH, temp

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; Initialize port
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
ser temp
out DDRB, temp

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; Initialize Serial Communication
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
ldi temp, TRANSFER_RATE
sts UBRR1L, temp			;set transfer rate

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; Enable recieve data and transfer data
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
ldi temp, (1<<TXEN1) | (1<<RXEN1) 
sts UCSR1B, temp			;enable UART flag for receiving
							;and transmitting

clr ledState
rcall led_output
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; Check for received data
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
main_loop:
	lds temp, UCSR1A
	sbrs temp, RXC1			;if RXC flag is clear
		rjmp main_loop		;then jump to start
		
	lds ledState, UDR1		;load received data to ledState
	
	rcall led_output
	
	ldi  r31, 6
    ldi  r30, 19
    ldi  r29, 174
L1: dec  r29
    brne L1
    dec  r30
    brne L1
    dec  r31
    brne L1
    rjmp PC+1


	echo:	
		lds temp, UCSR1A
		sbrs temp, UDRE1	;if transferbuffer !set
			rjmp echo		;then jump to echo
		
		sts UDR1, ledState	;send data
		
	rjmp main_loop

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; Output ledState to PortB
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<	
led_output:
	mov complement, ledState
	com complement
	out PORTB, complement
	
	ret