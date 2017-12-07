#include <string.h>

#include <avr/io.h>

#include "display_utils.h"

int main() {
	init_serial_comm(1 << TXEN1);

	Frame info_frame = create_frame(Information);
	info_frame.address = 'Z';
	strncpy(info_frame.line_1, "#", 1);         // info_frame.line_1 = "#"
	set_checksum(&info_frame, calculate_checksum(&info_frame, 1));

	Frame image_frame = create_frame(Image);
	set_checksum(&image_frame, calculate_checksum(&image_frame, 1));

	send_frame(&info_frame, 1);
	send_frame(&image_frame, 1);

	return 0;
}