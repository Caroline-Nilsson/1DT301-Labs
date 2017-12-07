#include <string.h>

#include <avr/io.h>

#define F_CPU 1000000UL     // 1MHz
#include <util/delay.h>

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

		// send last lines to display
		send_frame(&first_lines, 1);
		send_frame(&image_frame, 1);
		
		_delay_ms(10);
		
		// update checksum
		set_checksum(&last_line, calculate_checksum(&last_line, 3));

		// send first two lines to display
		send_frame(&last_line, 3);
		send_frame(&image_frame, 3);

		next_line = next_line + 1;

		if (next_line >= SCROLL_LINES) {
			next_line = 0;
		}

		_delay_ms(5000);
	}
}