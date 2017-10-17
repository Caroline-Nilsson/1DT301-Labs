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
    Frame info_frame = create_frame(Information);
    Frame image_frame = create_frame(Image);
    uint8_t next_line = 0;

    // Image frame does not change, so checksum can be calculated directly
    set_checksum(&image_frame, calculate_checksum(&image_frame));

    for (;;) {
        strncpy(info_frame.line_3, info_frame.line_2, 24);
        strncpy(info_frame.line_2, info_frame.line_1, 24);
        strncpy(info_frame.line_1, text[next_line], strlen(text[next_line]));

        // update checksum
        set_checksum(&info_frame, calculate_checksum(&info_frame));
        
        // send the updated frames to the display
        send_frame(&info_frame);
        send_frame(&image_frame);

        next_line = next_line + 1;
        
        if (next_line >= SCROLL_LINES) {
            next_line = 0;
        }

        _delay_ms(5000);
    }
}