//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
//   1DT301, Computer Technology I
//   Date: 2017-12-07
//   Author:
//                       Caroline Nilsson            (cn222nd)
//                       Daniel Alm Grundström       (dg222dw)
//
//   Lab number:         6
//   Title:              CyberTech Wall Display
//
//   Hardware:           STK600, CPU ATmega2560, CyberTech Wall Display
//
//   Function:           Utility functions to help with interfacing with the
//						 CyberTech Wall Display
//
//   Input ports:        N/A
//
//   Output ports:       N/A
//
//   Functions:			 init_serial_comm - Initializes USART
//						 create_frame - Creates and initializes a new Frame of type Information or Image
//						 send_frame - Sends a Frame through the serial port to the display
//						 uart_transmit - Transmits a single byte to the display
//						 uart_receive - Receives a single byte from the PuTTY terminal
//						 set_checksum - Sets the checksum of a Frame
//						 calculate_checksum - Calculates the checksum of a Frame
//						 clear_array - Sets all positions of an array to a specified character
//
//   Included files:     avr/io.h
//						 stdio.h
//						 string.h
//
//   Other information:  Uses USART1
//
//						 See header file 'display_utils.h' for constants and 
//						 declarations of structs FrameType and Frame 
//
//   Changes in program: 2017-12-07:
//						 Adds headers and comments.
//
//						 2017-10-31:
//						 Changes BAUD rate from 4800 to 2400
//
//						 2017-10-23:
//						 Updates USART initialization code.
//
//						 2017-10-17:
//						 Removes debug code.
//
//						 2017-10-10:
//						 Moves code from assignment 1.
//
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
#include <stdio.h>		// snprintf
#include <string.h>		// strncpy

#include <avr/io.h>		// UBRR1H, UBRR1L, UCSR1A, UCSR1B, UCSR1C, UCSZ10, UDRE1, UDR1, RXC1

#define FOSC 1000000UL // Clock Speed (1 MHz)
#define BAUD 2400
#define BAUD_PRESCALE (FOSC/16/BAUD-1)

#include "display_utils.h"

/*
 * Sets the USART transfer rate and enables specified usart control register
 * flags.
 */
void init_serial_comm(uint8_t ucsr1b_flags) {
    UBRR1H = (unsigned char)(BAUD_PRESCALE >> 8);
    UBRR1L = (unsigned char)BAUD_PRESCALE;
    UCSR1B = ucsr1b_flags;
    UCSR1C = (3 << UCSZ10); // asynchronous mode, 8-bit data length,
                            // no parity bit, 1 stop bit 
}

/*
 * Creates an empty frame of the specified type. 
 * Sets frame start, address, command and end.
 */
Frame create_frame(FrameType type) {
    Frame frame;
    clear_array(frame.line_1, INFO_FRAME_LINE_LEN, ' ');
    clear_array(frame.line_2, INFO_FRAME_LINE_LEN, ' ');
    clear_array(frame.command, INFO_FRAME_COMMAND_LEN, 0);
    
    frame.type = type;
    frame.start = 0x0D;
    frame.end = 0x0A;

    if (type == Information) {
        strncpy(frame.command, "O0001",
                INFO_FRAME_COMMAND_LEN);        // frame.command = "O0001"
    } else if (type == Image) {
        strncpy(frame.command, "D001",
                IMG_FRAME_COMMAND_LEN);         // frame.command = "D001"
		frame.address = 'Z';					// Image frame address should always be 'Z'
    }

    return frame;
}

/*
 * Send a information/image frame to the display through the serial port.
 *
 * 'line' represents the position of the line on the display and determines how
 * many lines to transmit. When 'line' is 1, both 'line_1' and 'line_2' is sent,
 * otherwise only 'line_1' is sent.
 */
void send_frame(const Frame *frame, int line) {
    uart_transmit((unsigned char)frame->start);
    uart_transmit((unsigned char)frame->address);
    
    for (uint8_t i = 0; i < INFO_FRAME_COMMAND_LEN; i++) {
        if (frame->command[i] != 0) {
            uart_transmit((unsigned char)frame->command[i]);
        }
    }

    if (frame->type == Information) {
		for (uint8_t i = 0; i < INFO_FRAME_LINE_LEN; i++) {
			uart_transmit((unsigned char)frame->line_1[i]);
		}
		
		if (line == 1) {
			for (uint8_t i = 0; i < INFO_FRAME_LINE_LEN; i++) {
				uart_transmit((unsigned char)frame->line_2[i]);
			}
		}
    }

    for (uint8_t i = 0; i < FRAME_CHECKSUM_LEN; i++) {
        uart_transmit((unsigned char)frame->checksum[i]);
    }

    uart_transmit((unsigned char)frame->end);
}

/*
 * Sends a byte of data through the serial port (USART).
 */
void uart_transmit(unsigned char data) {
    // Wait until transmit buffer is clear
    while (! (UCSR1A & (1 << UDRE1))) {
        ;
    }

    UDR1 = data; // transmit data
}

/*
 * Reads a byte from the serial port (USART).
 */
unsigned char uart_receive() {
    // Wait until data received flag set
    while ( !(UCSR1A & (1 << RXC1))) {
        ;
    }
	
    return UDR1;
}

/*
 * Sets all elements of a specified array to 'c'.
 */
void clear_array(char arr[], uint8_t length, unsigned char c) {
    for (uint8_t i = 0; i < length; i++) {
        arr[i] = c;
    }
}

/*
 * Calculates the checksum of a frame using the formula:
 *
 * checksum = sum(start, address, command, [message]) mod 256
 *
 * 'line' represents the position of the line on the display and determines how
 * many lines to include in the checksum calculation. When 'line' is 1, both 
 * 'line_1' and 'line_2' is calculated, otherwise only 'line_1' is calculated.
 */
uint8_t calculate_checksum(const Frame *frame, int line) {
    uint8_t sum = frame->start + (uint8_t)frame->address;
    
    for (int8_t i = 0; i < INFO_FRAME_COMMAND_LEN; i++) {
        sum = sum + (uint8_t)frame->command[i];
    }

    if (frame->type == Information) {
        for (int8_t i = 0; i < INFO_FRAME_LINE_LEN; i++) {
            sum = sum + (uint8_t)frame->line_1[i];
			
			if (line == 1) {
				sum = sum + (uint8_t)frame->line_2[i];
			}
        }
    }

    return sum;
}

/*
 * Translates the specified checksum to a hex string (E.g. 63 -> '3F') and
 * sets the specified frame's checksum to the translated checksum.
 */
void set_checksum(Frame *frame, uint8_t checksum) {
    char buffer[FRAME_CHECKSUM_LEN + 1];
    snprintf(buffer, FRAME_CHECKSUM_LEN + 1, "%02X", checksum);
    frame->checksum[0] = buffer[0];
    frame->checksum[1] = buffer[1];
}
