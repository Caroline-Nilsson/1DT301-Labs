#include <avr/io.h>
#include <stdlib.h>
#include <string.h>

// Constants
const uint8_t TRANSFER_RATE = 6;            // = 2400 bps (for 1MHz)
const uint8_t INFO_FRAME_COMMAND_LEN = 5;
const uint8_t IMG_FRAME_COMMAND_LEN = 4;
const uint8_t INFO_FRAME_MESSAGE_LEN = 8;
const uint8_t FRAME_CHECKSUM_LEN = 2;

/* 
 * Structure for display protocol frame. Used both for the Information frame 
 * and the Image frame.
 */
struct Frame {
    uint8_t start;
    char address;
    char command[INFO_FRAME_COMMAND_LEN];
    char message[INFO_FRAME_MESSAGE_LEN];
    char checksum[FRAME_CHECKSUM_LEN];
    uint8_t end;
};

typedef struct Frame Frame;

// Function prototypes
void init_serial_comm();
Frame build_information_frame(const char c[], uint8_t c_len);
Frame build_image_frame();
void send_frame(const Frame *frame);
void uart_transmit(unsigned char data);
void clear_array(char arr[], uint8_t length);
uint8_t calculate_checksum(const Frame *frame);
void set_checksum(Frame *frame);

int main() {
    init_serial_comm();
    Frame information_frame = build_information_frame("#", 1);
    Frame image_frame = build_image_frame();
    send_frame(&information_frame);
    send_frame(&image_frame);

    // Wait indefinitely (Unsure if neccesary)
    for (;;) {
        ;
    }

    return 0;
}

/*
 * Sets the USART transfer rate and enables transmitting through USART.
 */
void init_serial_comm() {
    UBRR1L = TRANSFER_RATE;
    USCR1B = (1 << TXEN1);                  // Enable transmitting through USART
}

/*
 * Builds a CyberTech protocol information frame containing
 * the specified message. The information frame tells the display
 * what to display.
 */
Frame build_information_frame(const char c[], uint8_t c_len) {
    Frame frame;
    clear_array(&frame.message, INFO_FRAME_MESSAGE_LEN);
    frame.start = 0x0D;
    frame.address = 'Z';
    strncpy(frame.command, "O0001",
            INFO_FRAME_COMMAND_LEN);        // frame.command = "O0001"
    strncpy(frame.message, c, c_len);       // frame.message = c
    set_checksum(&frame, calculate_checksum(frame));
    frame.end = 0x0A;
}

/*
 * Builds a CyberTech protocol image frame. The image frame instructs the 
 * display to show the message set by the information frame.
 */
Frame build_image_frame() {
    Frame frame;
    clear_array(&frame.message, INFO_FRAME_MESSAGE_LEN);
    clear_array(&frame.command, INFO_FRAME_COMMAND_LEN);
    frame.start = 0x0D;
    frame.address = 'Z';
    strncpy(frame.command, "D001",
            IMG_FRAME_COMMAND_LEN);      // frame.command = "D001"
    set_checksum(&frame, calculate_checksum(frame));
    frame.end = 0x0A;
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

    for (uint8_t i = 0; i < INFO_FRAME_MESSAGE_LEN; i++) {
        if (frame->message[i] != 0) {
            uart_transmit((unsigned char)frame->message[i]);
        }
    }

    for (uint8_t i = 0; i < FRAME_CHECKSUM_LEN; i++) {
        uart_transmit((unsigned char)frame->checksum[i]);
    }

    uart_transmit((unsigned char)frame->end);
}

/*
 * Sends a byte of data through the serial port.
 */
void uart_transmit(unsigned char data) {

    // Wait until transmit buffer is clear
    while (! (USCRA & (1 << UDRE))) {
        ;
    }

    UDR = data; // transmit data
}

/*
 * Sets all elements of a specified array to 0.
 */
void clear_array(char **arr, uint8_t length) {
    for (uint8_t i = 0; i < length; i++) {
        *(arr)[i] = 0;
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

    for (int8_t i = 0; i < INFO_FRAME_MESSAGE_LEN; i++) {
        sum = sum + (uint8_t)frame->message[i];
    }

    return sum;
}

/*
 * Translates the specified checksum to a hex string (E.g. 63 -> '3F') and
 * sets the specified frame's checksum to the translated checksum.
 */
void set_checksum(Frame *frame, uint8_t checksum) {
    char buffer[FRAME_CHECKSUM_LEN + 1];
    itoa(checksum, buffer, 16);
    frame->checksum[0] = buffer[0];
    frame->checksum[1] = buffer[1];
}