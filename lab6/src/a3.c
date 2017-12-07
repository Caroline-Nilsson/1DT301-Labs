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
//   Function:           Scrolls 5 lines of text on the CyberTech Display, with 5 seconds between each scroll
//
//   Input ports:        N/A
//
//   Output ports:       
//						 - RXD1/TXD1 connected to PD2/PD3
//						 - RS232 connected to CyberTech Display
//
//   Functions:			 main,
//						 scroll_text - Runs loop which scrolls the text in 'text' on the CyberTech Display
//
//   Included files:     display_utils.h
//						 avr/io.h
//						 util/delay.h
//						 string.h
//
//   Other information:  More information about used functions available
//						 in 'display_utils.c' 
//						 
//						 Lines in 'text' need to be exactly 24 characters long
//
//   Changes in program: 2017-12-07:
//						 Adds headers and comments.
//
//						 2017-10-17:
//						 Removes debug code.
//
//						 2017-10-11:
//						 Adds implementation.
//
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
#include <string.h>			// strncpy

#include <avr/io.h>			// TXEN1

#define F_CPU 1000000UL     // 1MHz
#include <util/delay.h>		// _delay_ms

#include "display_utils.h"

static const uint8_t SCROLL_LINES = 5;
static const char *text[] = {
	"Assignment #6           ",
	"Computer Technology     ",
	"Computer Science 2017   ",
	"Daniel Alm Grundstrom   ",
	"Caroline Nilsson        "
};

void scroll_text();

int main() {
	init_serial_comm(1 << TXEN1);
	scroll_text();

	return 0;
}

void scroll_text() {
	Frame first_lines = create_frame(Information);
	Frame last_line = create_frame(Information);
	Frame image_frame = create_frame(Image);
	uint8_t next_line = 0;

	first_lines.address = 'A';
	last_line.address = 'B';

	// Image frame does not change, so checksum can be calculated directly
	set_checksum(&image_frame, calculate_checksum(&image_frame, 1));

	for (;;) {
		strncpy(last_line.line_1, first_lines.line_2, INFO_FRAME_LINE_LEN);
		strncpy(first_lines.line_2, first_lines.line_1, INFO_FRAME_LINE_LEN);
		strncpy(first_lines.line_1, text[next_line], INFO_FRAME_LINE_LEN);

		// update checksum
		set_checksum(&first_lines, calculate_checksum(&first_lines, 1));

		// write first two lines to display
		send_frame(&first_lines, 1);
		send_frame(&image_frame, 1);
		
		_delay_ms(10);	// Short delay to make sure display has time to receive and act on command
		
		// update checksum
		set_checksum(&last_line, calculate_checksum(&last_line, 3));

		// write last line to display
		send_frame(&last_line, 3);
		send_frame(&image_frame, 3);

		next_line = next_line + 1;

		if (next_line >= SCROLL_LINES) {
			next_line = 0;
		}

		_delay_ms(5000);
	}
}