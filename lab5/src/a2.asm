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
;   Function:           Generate random number 1 - 75
;
;   Input ports:        PORTD
;
;   Output ports:       PORTE
;
;   Subroutines:        generate_value_loop:increase value until
;											max is reached
;						reset_value:		reset value
;						init_display:		initialize Display
;						clear_display:		clear display
;						write_char:			set RS = RS_ON
;						write_cmd:			clear RS
;						write:				write to display
;						write_nibble:		write nibble to display
;											(subroutine of write)
;						short_wait: 		delay
;						long_wait:  		delay
;						dbnc_wait:  		delay
;						power_up_wait:		delay
;						wait_loop:  		delay
;						switch_output:		modify output to fit display
;						switch0_interrupt:  collects generated value
;						sw0_loop:			counterract bounching
;						subtract_loop:		calculates the two ascii values
;											of the generated value
;						subtract:			subtract 10 from generated 
;											value and increase tensNumber
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
.def value = r19
.def tensNumber = r20
.def tempValue = r21

.equ BITMODE4 = 0b0000_0010
.equ CLEAR = 0b0000_0001
.equ DISP_CTRL = 0b0000_1111            ; Display on, cursor on, blink on.
.equ RS_ON = 0b0010_0000
.equ LCD_PORT = PORTE                   ; Port LCD is connected to
.equ LCD_DATA_DIR = DDRE                ; Data dir. of port LCD is connected to
.equ SWITCH_PORT = PORTD
.equ SWITCH_DATA_DIR = DDRD
.equ PREFIX = 0b0011_0000               ; Prefix for outputting number on LCD
.equ VAL_MAX = 75
.equ VAL_MIN = 1

.cseg
.org 0x00
    jmp reset

.org int0addr
    jmp switch0_interrupt

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

    clr temp
    out SWITCH_DATA_DIR, temp 

    ; Initialize display
    rcall init_display

    ;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    ; enable external interrupt on PIND0
    ;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    ldi temp, (1<<int0)
    out EIMSK, temp
    
    ;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    ; set interrupt sense control to "Falling edge"
    ;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    ldi temp, (3<<ISC00)
    sts EICRA, temp
        
    sei
    
    rjmp reset_value

generate_value_loop:
    cpi value, VAL_MAX
    brge reset_value
    inc value
    rjmp generate_value_loop

reset_value:
    ldi value, VAL_MIN
    rjmp generate_value_loop

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

switch0_interrupt:
	in temp, SREG
	push temp

    mov tempValue, value
	lds temp, PORTD
    
sw0_loop:
    ldi  r31, 130
    ldi  r30, 222
L1: dec  r30
    brne L1
    dec  r31
    brne L1
    nop

    lds r29, PORTD
    cp temp, r29
    brne sw0_loop

    ldi tensNumber, 0

subtract_loop:
    cpi tempValue, 10
    brge subtract

	rcall clear_display

    mov data, tensNumber
    ori data, PREFIX
    rcall write_char
	rcall long_wait

    mov data, tempValue
    ori data, PREFIX
    rcall write_char

	pop temp
	out SREG, temp
    reti

subtract:
    subi tempValue, 10
    inc tensNumber
    rjmp subtract_loop