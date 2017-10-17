#include <string.h>

#include <avr/io.h>

#include "display_utils.h"

int main() {
    init_serial_comm(1 << TXEN1);

    Frame info_frame = create_frame(Information);
    strncpy(info_frame.line_1, "#", 1);         // info_frame.line_1 = "#"
    set_checksum(&info_frame, calculate_checksum(&info_frame));

    Frame image_frame = create_frame(Image);
    set_checksum(&image_frame, calculate_checksum(&image_frame));
    
    send_frame(&info_frame);
    send_frame(&image_frame);

    // Wait indefinitely (Unsure if neccesary)
    for (;;) {
        ;
    }

    return 0;
}