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
//   Function:           Reads 3 lines of text from a PuTTY terminal and 
//						 outputs them on the CyberTech Display.
//
//						 First waits for the address for the first two lines ('A'-'Z'),
//						 then allows two lines of max 24 characters to be entered. After
//						 each line a '#' terminating character needs to be entered.
//						
//						 The program then waits for the user to input the address of the last
//						 line ('A'-'Z') and then reads one additional line, which is also terminated
//						 with a '#'. After this terminating '#', the text is displayed on the 
//						 CyberTech Display.
//
//						 For example, entering 'A', then "Rad 1#Rad 2#", then 'B' and "Rad 3#" 
//						 outputs:
//
//						 [Rad 1                   ]
//						 [Rad 2                   ]
//						 [Rad 3                   ]
//
//   Input ports:        RS232 connected to Computer serial port
//
//   Output ports:       
//						 - RXD1/TXD1 connected to PD2/PD3
//						 - RS232 connected to CyberTech Display
//
//   Functions:			 main,
//						 get_line - Reads a line from of text from PuTTY
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
//						 2017-10-11:
//						 Adds implementation.
//
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
#include <string.h>

#include <avr/io.h>

#include "display_utils.h"

#define NEW_LINE '#'

void get_line(char line[]);

int main() {
	init_serial_comm((1 << TXEN1) | (1 << RXEN1));		// Enable USART for transmitting and receiving

	Frame image_frame = create_frame(Image);
	set_checksum(&image_frame, calculate_checksum(&image_frame, 1));

	Frame first_lines = create_frame(Information);
	Frame last_line = create_frame(Information);

	first_lines.address = uart_receive();
	get_line(first_lines.line_1);
	get_line(first_lines.line_2);
	last_line.address = uart_receive();
	get_line(last_line.line_1);

	set_checksum(&first_lines, calculate_checksum(&first_lines, 1));
	set_checksum(&last_line, calculate_checksum(&last_line, 3));

	send_frame(&first_lines, 1);
	send_frame(&image_frame, 1);

	send_frame(&last_line, 3);
	send_frame(&image_frame, 3);

	return 0;
}

void get_line(char line[]) {
	char received;
	uint8_t line_index = 0;

	do {
		received = (char)uart_receive();

		if (line_index < INFO_FRAME_LINE_LEN && received != NEW_LINE) {
			line[line_index++] = received;
		}

	} while (received != NEW_LINE);
}