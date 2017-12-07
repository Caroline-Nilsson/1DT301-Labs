;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;   1DT301, Computer Technology I
;   Date: 2017-10-30
;   Author:
;                       Caroline Nilsson            (cn222nd)
;                       Daniel Alm Grundström       (dg222dw)
;
;   Lab number:         5
;   Title:              Display JHD202
;
;   Hardware:           STK600, CPU ATmega2560, LCD JHD202
;
;   Function:           Recieve character on the serial port
;						and displays it on LCD
;
;   Input ports:        RS232
;
;   Output ports:       PORTE
;
;   Subroutines:        init_display:			initialize Display
;						clear_display:			clear display
;						write_char:				set RS = RS_ON
;						write_cmd:				clear RS
;						write:					write to display
;						write_nibble:			write nibble to display
;												(subroutine of write)
;						short_wait: 			delay
;						long_wait:  			delay
;						dbnc_wait:  			delay
;						power_up_wait:			delay
;						wait_loop:  			delay
;						switch_output:			modify output to fit display
;						data_received_interrupt:load character and calls 
;												write
;   Included files:     m2560def.inc
;
;   Other information:  
;
;   Changes in program: 2017-10-14
;                       Implements flowchart design.
;
;                       2017-10-30
;                       Changes during lab session
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

.include "m2560def.inc"
.def temp = r16
.def data = r17
.def RS = r18

.equ BITMODE4 = 0b0000_0010
.equ CLEAR = 0b0000_0001
.equ DISP_CTRL = 0b0000_1111            ; Display on, cursor on, blink on.
.equ RS_ON = 0b0010_0000
.equ LCD_PORT = PORTE                   ; Port LCD is connected to
.equ LCD_DATA_DIR = DDRE                ; Data dir. of port LCD is connected to
.equ TRANSFER_RATE = 12                 ; = 4800 bps (1MHz) 

.cseg
.org 0x00
    jmp reset
	
.org URXC1addr
    jmp data_received_interrupt

.org 0x72

reset:

    ; Init stack pointer
    ldi temp, HIGH(RAMEND)
    out SPH, temp
    ldi temp, LOW(RAMEND)
    out SPL, temp
    
    ; set LCD output port
    ser temp
    out LCD_DATA_DIR, temp

	out DDRB, temp

    ; Initialize display
    rcall init_display

    ;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    ; Initialize Serial Communication
    ;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    ldi temp, TRANSFER_RATE
    sts UBRR1L, temp                    ;set transfer rate

    ldi temp, (1<<RXEN1) | (1<<RXCIE1)
    sts UCSR1B, temp                    ;enable UART flag for receiving
                                        ;and transmitting
    
    sei
    
main_loop:
    nop
    rjmp main_loop

; Display subroutines
init_display:
    rcall power_up_wait                 ; Wait for display to power up

    ldi data, BITMODE4                  ; Set 4-bit operation
    rcall write_nibble
    rcall short_wait
    ldi data, DISP_CTRL
    rcall write_cmd
    rcall short_wait

clear_display:
    ldi data, CLEAR
    rcall write_cmd
    rcall long_wait
    ret

; Write subroutines
write_char:
    ldi RS, RS_ON
    rjmp write

write_cmd:
    clr RS

write:
    mov temp, data
    andi data, 0b1111_0000              ; Clear lower nibble
    swap data
    or data, RS                         ; Add RS to command to write
    rcall write_nibble                  ; send high nibble
    mov data, temp
    andi data, 0b0000_1111              ; Clear high nibble
    or data, RS

write_nibble:
    rcall switch_output
    nop
    sbi LCD_PORT, 5
    nop
    nop
    cbi LCD_PORT, 5
    nop
    nop
    ret

; Wait subroutines
short_wait: 
    clr ZH
    ldi ZL, 30
    rjmp wait_loop
long_wait:  
    ldi ZH, HIGH(1000)
    ldi ZH, LOW(1000)
    rjmp wait_loop
dbnc_wait:  
    ldi ZH, HIGH(4600)
    ldi ZL, LOW(4600)
    rjmp wait_loop
power_up_wait:
    ldi ZH, HIGH(9000)
    ldi ZL, LOW(9000)

wait_loop:  
    sbiw Z, 1
    brne wait_loop
    ret

; Modify output to fit LCD JHD202C
switch_output:
    push temp
    clr temp

    sbrc data, 0                        ; If D4 set
        ori temp, 0b0000_0100           ;     then set PIN3
    sbrc data, 1                        ; If D5 set
        ori temp, 0b0000_1000           ;     then set PIN4
    sbrc data, 2                        ; If D6 set
        ori temp, 0b0000_0001           ;     then set PIN0
    sbrc data, 3                        ; If D7 set
        ori temp, 0b0000_0010           ;     then set PIN1
    sbrc data, 4                        ; If E set
        ori temp, 0b0010_0000           ;     then set PIN5
    sbrc data, 5                        ; If RS set
        ori temp, 0b1000_0000           ;     then set PIN7

    out LCD_PORT, temp
    pop temp
    ret

data_received_interrupt:
    rcall clear_display

    lds data, UDR1
	out PORTB, data
    rcall write_char

    reti