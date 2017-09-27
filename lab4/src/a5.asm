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
;   Changes in program: 2017-09-27
;                       Implements flowchart design.
;                       
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

.inc "m2560def.inc"

.def temp = r16
.def ledState = r17
.def complement = r18
.def dataReceived = r19     ; flag set when data has been
                            ; received 

.equ TRANSFER_RATE = 12 	;1MHz, 4800 bps
.equ TRUE = 0x01
.equ FALSE = 0x00

.cseg

.org 0x00
rjmp reset

.org URXC0addr 
rjmp data_received_interrupt

.org UDRE0addr
rjmp buffer_empty_interrupt

.org UTXC0addr
rjmp data_transmitted_interrupt

.org 0x72
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; reset - called on program start and on reset interrupts
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
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
sts UBRR0L, temp			;set transfer rate

ldi temp, (1<<RXEN0) | (1<<TXEN0)
sts UCSR0B, temp			;enable UART flag for receiving
							;and transmitting

sei
clr led_output

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; main_loop
;       Outputs ledState while waiting for interrupts
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
main_loop:
	rcall led_output
	rjmp main_loop

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; led_output
;       Output complement of ledState to PortB
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<	
led_output:
	mov complement, ledState
	com complement
	out PORTB, complement
	
	ret

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; data_received_interrupt
;       Triggered when data has been received through 
;       UART 0. Loads the received data into ledState
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<	
data_received_interrupt:
	lds ledState, UDR0		;load received data to ledState
    ldi dataReceived, TRUE

    reti

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; buffer_empty_interrupt
;       Triggered when UART data register is empty. Checks
;       if dataReceived flag is set and in that case echoes
;       it back to the receiver.
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<	
buffer_empty_interrupt: 
    cpi dataReceived, FALSE
    breq buffer_empty_end

	sts UDR0, ledState	;send data
        
    buffer_empty_end:
        reti

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; data_transmitted_interrupt
;       Triggered when data has finished transmitting. 
;       Sets dataReceived to false
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<	
data_transmitted_interrupt:
    ldi dataReceived, FALSE

    reti
