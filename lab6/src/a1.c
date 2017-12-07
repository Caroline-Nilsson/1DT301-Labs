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
//   Function:           Writes the character '#' to the CyberTech Display
//
//   Input ports:        N/A
//
//   Output ports:       USART1:
//						     RXD1/TXD1 connected to PD2/PD3
//						     RS232 connected to CyberTech Display
//
//   Functions:			 main
//   Included files:     display_utils.h
//						 avr/io.h
//						 string.h
//
//   Other information:  More information about used functions available
//						 in 'display_utils.c'
//
//   Changes in program: 2017-12-07:
//						 Adds headers and additional comments.
//
//						 2017-10-17:
//						 Removes debug code.
//
//						 2017-10-10:
//						 Fix bugs, restructures code and adds comments.
//
//						 2017-10-09:
//						 Adds implementation.
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
#include <string.h>		// strncpy

#include <avr/io.h>		// TXEN1

#include "display_utils.h"

int main() {
	init_serial_comm(1 << TXEN1);			// Enable USART for transmitting 

	Frame info_frame = create_frame(Information);
	Frame image_frame = create_frame(Image);
	info_frame.address = 'Z';				// 'Z' is used instead of 'A' so display is cleared

	strncpy(info_frame.line_1, "#", 1);     // info_frame.line_1 = "#"
	
	set_checksum(&info_frame, calculate_checksum(&info_frame, 1));
	set_checksum(&image_frame, calculate_checksum(&image_frame, 1));

	send_frame(&info_frame, 1);
	send_frame(&image_frame, 1);

	return 0;
}