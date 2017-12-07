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
//   Function:           Writes three lines of text to the CyberTech Display
//
//   Input ports:        N/A
//
//   Output ports:       USART1:
//						     RXD1/TXD1 connected to PD2/PD3
//						     RS232 connected to CyberTech Display
//
//   Functions:			 main
//
//   Included files:     display_utils.h
//						 avr/io.h
//						 string.h
//
//   Other information:  More information about used functions available
//						 in 'display_utils.c'
//
//   Changes in program: 2017-12-07:
//						 Adds headers and comments.
//
//						 2017-10-17:
//						 Removes debug code.
//
//						 2017-10-10:
//						 Adds implementation.
//
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
#include <string.h>		// strncpy, strlen

#include <avr/io.h>		// TXEN1

#include "display_utils.h"

#define LINE_1 "Rad 1"
#define LINE_2 "Rad 2"
#define LINE_3 "Rad 3"

int main() {
	init_serial_comm(1 << TXEN1);

	Frame image_frame = create_frame(Image);
	set_checksum(&image_frame, calculate_checksum(&image_frame, 1));
	
	// Initializes the two information frames (one for the first two lines
	// and the other for the last line)
	Frame first_lines = create_frame(Information);
	Frame last_line = create_frame(Information);
	first_lines.address = 'A';
	last_line.address = 'B';

	strncpy(first_lines.line_1, LINE_1, strlen(LINE_1));
	strncpy(first_lines.line_2, LINE_2, strlen(LINE_2));
	set_checksum(&first_lines, calculate_checksum(&first_lines, 1));

	send_frame(&first_lines, 1);
	send_frame(&image_frame, 1);

	strncpy(last_line.line_1, LINE_3, strlen(LINE_3));
	set_checksum(&last_line, calculate_checksum(&last_line, 3));

	send_frame(&last_line, 3);
	send_frame(&image_frame, 3);

	return 0;
}