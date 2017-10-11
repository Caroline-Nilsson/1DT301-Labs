#ifdef DEBUG
#define debug_print(...) \
            do { if (DEBUG) fprintf(stderr, __VA_ARGS__); } while (0)
#else
#include <avr/io.h>
#define debug_print(...)
#endif

#include <stdio.h>
#include <string.h>

#include "display_utils.h"

/*
 * Sets the USART transfer rate and enables specified usart control register
 * flags.
 */
void init_serial_comm(uint8_t ucsr1b_flags) {
#ifndef DEBUG
    UBRR1L = TRANSFER_RATE;
    UCSR1B = ucsr1b_flags;
#endif
}

/*
 * Creates an empty frame of the specified type. 
 * Sets frame start, address, command and end.
 */
Frame create_frame(FrameType type) {
    Frame frame;
    clear_array(frame.line_1, INFO_FRAME_LINE_LEN);
    clear_array(frame.line_2, INFO_FRAME_LINE_LEN);
    clear_array(frame.line_3, INFO_FRAME_LINE_LEN);
    clear_array(frame.command, INFO_FRAME_COMMAND_LEN);
    
    frame.type = type;
    frame.start = 0x0D;
    frame.end = 0x0A;
    frame.address = 'Z';

    if (type == Information) {
        strncpy(frame.command, "O0001",
                INFO_FRAME_COMMAND_LEN);        // frame.command = "O0001"
    } else if (type == Image) {
        strncpy(frame.command, "D001",
                IMG_FRAME_COMMAND_LEN);         // frame.command = "D001"
    }

    return frame;
}

/*
 * Send a information/image frame to the display through the serial port.
 */
void send_frame(const Frame *frame) {
    debug_print("Transmitting START\n");
    uart_transmit((unsigned char)frame->start);
    debug_print("\nTransmitting ADDRESS\n");
    uart_transmit((unsigned char)frame->address);
    debug_print("\nTransmitting COMMAND\n");
    
    for (uint8_t i = 0; i < INFO_FRAME_COMMAND_LEN; i++) {
        if (frame->command[i] != 0) {
            uart_transmit((unsigned char)frame->command[i]);
        }
    }

    debug_print("\n");

    if (frame->type == Information) {
        debug_print("Transmitting LINE_1\n");
        
        for (uint8_t i = 0; i < INFO_FRAME_LINE_LEN; i++) {
            uart_transmit((unsigned char)frame->line_1[i]);
        }

        debug_print("\nTransmitting LINE_2\n");

        for (uint8_t i = 0; i < INFO_FRAME_LINE_LEN; i++) {
            uart_transmit((unsigned char)frame->line_2[i]);
        }

        debug_print("\nTransmitting LINE_3\n");
        
        for (uint8_t i = 0; i < INFO_FRAME_LINE_LEN; i++) {
            uart_transmit((unsigned char)frame->line_3[i]);
        }

        debug_print("\n");
    }

    debug_print("Transmitting CHECKSUM\n");
    
    for (uint8_t i = 0; i < FRAME_CHECKSUM_LEN; i++) {
        uart_transmit((unsigned char)frame->checksum[i]);
    }

    debug_print("\nTransmitting END\n");
    uart_transmit((unsigned char)frame->end);
    debug_print("\n");
}

/*
 * Sends a byte of data through the serial port.
 */
void uart_transmit(unsigned char data) {
#ifndef DEBUG
    // Wait until transmit buffer is clear
    while (! (UCSR1A & (1 << UDRE1))) {
        ;
    }

    UDR1 = data; // transmit data
#endif

    debug_print("transmitting: \t %d \t %02X \t '%c'\n", (int)data, data, data);
}

/*
 * Sets all elements of a specified array to 0.
 */
void clear_array(char arr[], uint8_t length) {
    for (uint8_t i = 0; i < length; i++) {
        arr[i] = 0;
    }
}

/*
 * Calculates the checksum of a frame using the formula:
 *
 * checksum = sum(start, address, command, [message]) mod 256
 *
 */
uint8_t calculate_checksum(const Frame *frame) {
    uint8_t sum = frame->start + (uint8_t)frame->address;

    for (int8_t i = 0; i < INFO_FRAME_COMMAND_LEN; i++) {
        sum = sum + (uint8_t)frame->command[i];
    }

    if (frame->type == Information) {
        for (int8_t i = 0; i < INFO_FRAME_LINE_LEN; i++) {
            sum = sum + (uint8_t)frame->line_1[i];
            sum = sum + (uint8_t)frame->line_2[i];
            sum = sum + (uint8_t)frame->line_3[i];
        }
    }

    return sum;
}

/*
 * Translates the specified checksum to a hex string (E.g. 63 -> '3F') and
 * sets the specified frame's checksum to the translated checksum.
 */
void set_checksum(Frame *frame, uint8_t checksum) {
    char buffer[FRAME_CHECKSUM_LEN + 1];
    snprintf(buffer, FRAME_CHECKSUM_LEN + 1, "%02X", checksum);
    frame->checksum[0] = buffer[0];
    frame->checksum[1] = buffer[1];
}