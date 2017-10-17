#include <string.h>

#include <avr/io.h>

#include "display_utils.h"

#define NEW_LINE '$'

void get_line(char line[]);

int main() {
    init_serial_comm((1 << TXEN1) | (1 << RXEN1));

    Frame info_frame = create_frame(Information);

    info_frame.address = uart_receive();
    get_line(info_frame.line_1);
    get_line(info_frame.line_2);
    get_line(info_frame.line_3);

    set_checksum(&info_frame, calculate_checksum(&info_frame));

    Frame image_frame = create_frame(Image);
    set_checksum(&image_frame, calculate_checksum(&image_frame));
    
    send_frame(&info_frame);
    send_frame(&image_frame);

    return 0;
}

void get_line(char line[]) {
    char received;
    uint8_t line_index = 0;

    do {
        received = (char)uart_receive();

        if (line_index < INFO_FRAME_LINE_LEN) {
            line[line_index] = received;
        }

    } while (received != NEW_LINE);
}