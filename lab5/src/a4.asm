.include "m2560def.inc"
.def temp = r16
.def data = r17
.def RS = r18
.def counter = r19

.equ BITMODE4 = 0b0000_0010
.equ CLEAR = 0b0000_0001
.equ DISP_CTRL = 0b0000_1111            ; Display on, cursor on, blink on.
.equ RS_ON = 0b0010_0000
.equ LCD_PORT = PORTE                   ; Port LCD is connected to
.equ LCD_DATA_DIR = DDRE                ; Data dir. of port LCD is connected to
.equ TRANSFER_RATE = 12                 ; = 4800 bps (1MHz) 
.equ PRESCALE = 0x05                    ; = 1024 = increment once per ms (1MHz)
.equ NEW_LINE = 0b0010_0011
.equ RAM_ADDR = 0x0200

.cseg
.org 0x00
    jmp reset

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

    ; Initialize display
    rcall init_display

    ;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    ; Initialize Serial Communication
    ;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    ldi temp, TRANSFER_RATE
    sts UBRR1L, temp                    ;set transfer rate

    ldi temp, (1<<RXEN1)
    sts UCSR1B, temp                    ;enable UART flag for receiving
    
    sei
    
	clr counter
	ldi XH, HIGH(RAM_ADDR)
	ldi XL, LOW(RAM_ADDR)

    rcall read_lines

main_loop:
	
	ldi XH, HIGH(RAM_ADDR)
	ldi XL, LOW(RAM_ADDR)
	
	ldi YH, HIGH(RAM_ADDR)
	ldi YL, LOW(RAM_ADDR)
	
	clr counter
four_row_loop:
	inc counter
	
	rcall write_main
	rcall delay_5sec
	rcall write_new_lines
	
	cpi counter, 4
	brlo four_row_loop
	
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

read_lines:
	lds temp, UCSR1A
	sbrs temp, RXC1			;if RXC flag is clear
		rjmp read_lines		;then jump to start
		
	lds data, UDR1			;load received data to ledState

	cpi data, NEW_LINE
	brne store_char

	inc counter

	cpi counter, 4
	brge read_lines_end

store_char:
	st X+, data

	rjmp read_lines

read_lines_end:
	ldi data, NEW_LINE
	st X+, data
    ret

	
write_main:
	
	ld data, X+
	
	cpi data, NEW_LINE
	breq write_lines_end
	
	rcall write_char

	rjmp write_main

write_lines_end:	
	ret

write_new_lines:
	push counter
	rcall clear_display
	ldi counter, 40

write_new_line:
	ldi data, 0b0010_0000
	rcall write_char
	
	dec counter
	cpi counter, 1
	brge write_new_line

	rcall write_second_line

	ldi data, 0b0000_0010
	rcall write_cmd

	pop counter
	ret

write_second_line:
	ld data, Y+
	
	cpi data, NEW_LINE
	breq write_second_line_end
	
	rcall write_char

	rjmp write_second_line

write_second_line_end:	
	ret

delay_5sec:
	push r18
	push r19
	push r20

    ldi  r18, 26
    ldi  r19, 94
    ldi  r20, 111
L1: dec  r20
    brne L1
    dec  r19
    brne L1
    dec  r18
    brne L1
    nop

	pop r20
	pop r19
	pop r18
	ret