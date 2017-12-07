#include <string.h>

#include <avr/io.h>

#include "display_utils.h"

#define LINE_1 "Rad 1"
#define LINE_2 "Rad 2"
#define LINE_3 "Rad 3"

int main() {
	init_serial_comm(1 << TXEN1);

	Frame first_lines = create_frame(Information);
	Frame last_line = create_frame(Information);
	first_lines.address = 'A';
	last_line.address = 'B';

	strncpy(first_lines.line_1, LINE_1, strlen(LINE_1));
	strncpy(first_lines.line_2, LINE_2, strlen(LINE_2));
	set_checksum(&first_lines, calculate_checksum(&first_lines, 1));

	Frame image_frame = create_frame(Image);
	set_checksum(&image_frame, calculate_checksum(&image_frame, 1));

	send_frame(&first_lines, 1);
	send_frame(&image_frame, 1);

	strncpy(last_line.line_1, LINE_3, strlen(LINE_3));
	set_checksum(&last_line, calculate_checksum(&last_line, 3));

	send_frame(&last_line, 3);
	send_frame(&image_frame, 3);

	return 0;
}