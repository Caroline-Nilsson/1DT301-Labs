#include <string.h>

#include <avr/io.h>

#include "display_utils.h"

#define NEW_LINE '#'

void get_line(char line[]);

int main() {
	init_serial_comm((1 << TXEN1) | (1 << RXEN1));

	Frame first_lines = create_frame(Information);
	Frame last_line = create_frame(Information);

	first_lines.address = uart_receive();
	get_line(first_lines.line_1);
	get_line(first_lines.line_2);
	last_line.address = uart_receive();
	get_line(last_line.line_1);

	set_checksum(&first_lines, calculate_checksum(&first_lines, 1));
	set_checksum(&last_line, calculate_checksum(&last_line, 3));

	Frame image_frame = create_frame(Image);
	set_checksum(&image_frame, calculate_checksum(&image_frame, 1));

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