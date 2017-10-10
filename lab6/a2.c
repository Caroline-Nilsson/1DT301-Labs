#ifndef DEBUG
#include <avr/io.h>
#endif

#include <string.h>

#include "display_utils.h"

int main() {
#ifndef DEBUG
    init_serial_comm(1 << TXEN1);
#endif
    Frame info_frame = create_frame(Information);
    strncpy(info_frame.line_1, "Hej", 3);
    strncpy(info_frame.line_2, "pa", 2);
    strncpy(info_frame.line_3, "dej", 3);
    set_checksum(&info_frame, calculate_checksum(&info_frame));

    Frame image_frame = create_frame(Image);
    set_checksum(&image_frame, calculate_checksum(&image_frame));

    send_frame(&info_frame);
    send_frame(&image_frame);
#ifndef DEBUG
    // Wait indefinitely (Unsure if neccesary)
    for (;;) {
        ;
    }
#endif
    return 0;
}