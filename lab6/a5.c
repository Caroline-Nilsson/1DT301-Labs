#ifndef DEBUG
#include <avr/io.h>
#endif

#include <string.h>

#include "display_utils.h"

#define NEW_LINE '$'

void append_to_line(Frame *info_frame, Frame *image_frame, char line[]);

int main() {
#ifndef DEBUG
    init_serial_comm((1 << TXEN1) | (1 << RXEN1));
#endif
    Frame info_frame = create_frame(Information);
    Frame image_frame = create_frame(Image);
    set_checksum(&image_frame, calculate_checksum(&image_frame));
    
    append_to_line(&info_frame, &image_frame, info_frame.line_1);
    append_to_line(&info_frame, &image_frame, info_frame.line_2);
    append_to_line(&info_frame, &image_frame, info_frame.line_3);


#ifndef DEBUG
    // Wait indefinitely (Unsure if neccesary)
    for (;;) {
        ;
    }
#endif
    return 0;
}

void append_to_line(Frame *info_frame, Frame *image_frame, char line[]) {
    char received;
    uint8_t line_index = 0;

    while ( ((received = (char)uart_receive()) != NEW_LINE) 
        && (line_index < INFO_FRAME_LINE_LEN) )  {
        
        line[line_index] = received;
        line_index = line_index + 1;

        set_checksum(info_frame, calculate_checksum(info_frame));
        send_frame(info_frame);
        send_frame(image_frame);
    }
}