#include <string.h>

#include <avr/io.h>

#include "display_utils.h"

#define NEW_LINE '#'

void append_to_line(Frame *info_frame, Frame *image_frame, char line[]);

int main() {
	init_serial_comm((1 << TXEN1) | (1 << RXEN1));

	//Frame first_lines = create_frame(Information);
	//Frame last_line = create_frame(Information);

	Frame image_frame = create_frame(Image);
	set_checksum(&image_frame, calculate_checksum(&image_frame, 1));

	for (;;) {
		Frame info = create_frame(Information);

		int input = uart_receive();
		info.address = (char)(16 + input);

		append_to_line(&info, &image_frame, info.line_1);
	}

	return 0;
}

void append_to_line(Frame *info_frame, Frame *image_frame, char line[]) {
	char received;
	uint8_t line_index = 0;

	int which_line = (info_frame->address == 'A')
				? 1
				: 3;

	while (((received = (char)uart_receive()) != NEW_LINE))  {

		line[line_index] = received;
		line_index = line_index + 1;

		set_checksum(info_frame, calculate_checksum(info_frame, which_line));
		send_frame(info_frame, which_line);
		send_frame(image_frame, which_line);
	}
}