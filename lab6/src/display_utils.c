#include <stdio.h>
#include <string.h>

#include <avr/io.h>

#define FOSC 1000000UL // Clock Speed
#define BAUD 4800
#define (BAUD_PRESCALE FOSC/16/BAUD-1)

#include "display_utils.h"

/*
 * Sets the USART transfer rate and enables specified usart control register
 * flags.
 */
void init_serial_comm(uint8_t ucsr1b_flags) {
    UBRR1H = (unsigned char)(BAUD_PRESCALE >> 8);
    UBRR1L = (unsigned char)BAUD_PRESCALE;
    UCSR1B = ucsr1b_flags;
    UCSR1C = (3 << UCSZ10); // asynchronous mode, 8-bit data length,
                            // no parity bit, 1 stop bit 
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
    uart_transmit((unsigned char)frame->start);
    uart_transmit((unsigned char)frame->address);
    
    for (uint8_t i = 0; i < INFO_FRAME_COMMAND_LEN; i++) {
        if (frame->command[i] != 0) {
            uart_transmit((unsigned char)frame->command[i]);
        }
    }

    if (frame->type == Information) {
        for (uint8_t i = 0; i < INFO_FRAME_LINE_LEN; i++) {
            uart_transmit((unsigned char)frame->line_1[i]);
        }

        for (uint8_t i = 0; i < INFO_FRAME_LINE_LEN; i++) {
            uart_transmit((unsigned char)frame->line_2[i]);
        }
        
        for (uint8_t i = 0; i < INFO_FRAME_LINE_LEN; i++) {
            uart_transmit((unsigned char)frame->line_3[i]);
        }
    }

    for (uint8_t i = 0; i < FRAME_CHECKSUM_LEN; i++) {
        uart_transmit((unsigned char)frame->checksum[i]);
    }

    uart_transmit((unsigned char)frame->end);
}

/*
 * Sends a byte of data through the serial port (UART).
 */
void uart_transmit(unsigned char data) {
    // Wait until transmit buffer is clear
    while (! (UCSR1A & (1 << UDRE1))) {
        ;
    }

    UDR1 = data; // transmit data
}

/*
 * Reads a byte from the serial port (UART).
 */
unsigned char uart_receive() {
    // Wait until data received flag set
    while (UCSR1A & (1 << RXC1) == 0) {
        ;
    }

    return UDR1;
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