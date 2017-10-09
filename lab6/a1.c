#include <avr/io.h>
#include <stdlib.h>

/* 
 * Structure for display protocol frame. Used both for Instruction frame 
 * and Image frame.
 */
struct Frame {
    uint8_t start;
    unsigned char address;
    unsigned char command[5];
    unsigned char message[8];
    unsigned char checksum[2];
    uint8_t end;
};

typedef struct Frame Frame;

void init_serial_comm();
Frame build_instruction_frame(char c);
Frame build_image_frame();
void send_frame(Frame *frame);
void uart_transmit(unsigned char data);
void clear_array(char arr[], uint8_t length);
void set_checksum(Frame *frame);

const uint8_t TRANSFER_RATE = 6;        // = 2400 bps (for 1MHz)

int main() {
    init_serial_comm();
    Frame instruction_frame = build_instruction_frame("#");
    Frame image_frame = build_image_frame();
    send_frame(&instruction_frame);
    send_frame(&image_frame);

    // Wait indefinitely (Unsure if neccesary)
    for (;;) {
        ;
    }

    return 0;
}

void init_serial_comm() {
    UBRR1L = TRANSFER_RATE;
    USCR1B = (1 << TXEN1);              // Enable transmitting through USART
}

Frame build_instruction_frame(const char c[]) {
    Frame frame;
    clear_array(&frame.message, 8);
    frame.start = 0x0D;
    frame.adress = 'Z';
    frame.command = "O0001";
    frame.message = c;
    set_checksum(&frame);
    frame.end = 0x0A;
}

Frame build_image_frame() {
    Frame frame;
    clear_array(&frame.message, 8);
    clear_array(&frame.command, 5);
    frame.start = 0x0D;
    frame.adress = 'Z';
    frame.command = "D001";
    set_checksum(&frame);
    frame.end = 0x0A;
}

/*
 * Send a information/image frame to display.
 */
void send_frame(Frame *frame) {
    uart_transmit((unsigned char)frame->start);
    uart_transmit(frame->adress);

    for (uint8_t i = 0; i < 5; i++) {
        if (frame->command[i] != 0) {
            uart_transmit(frame->command[i]);
        }
    }

    for (uint8_t i = 0; i < 8; i++) {
        if (frame->message[i] != 0) {
            uart_transmit(frame->message[i]);
        }
    }

    for (uint8_t i = 0; i < 2; i++) {
        uart_transmit(frame->checksum[i]);
    }

    uart_transmit(frame->end);
}

void uart_transmit(unsigned char data) {

    // Wait until transmit buffer is clear
    while (! (USCRA & (1 << UDRE))) {
        ;
    }

    UDR = data; // transmit data
}

void clear_array(char **arr, uint8_t length) {
    for (uint8_t i = 0; i < length; i++) {
        *(arr)[i] = 0;
    }
}

/*
 * Calculates and sets checksum for a specified frame.
 */
void set_checksum(Frame *frame) {
    uint8_t sum = frame->start + (uint8_t)frame->adress;

    for (int8_t i = 0; i < 5; i++) {
        sum = sum + frame->command[i];
    }

    for (int8_t i = 0; i < 8; i++) {
        sum = sum + (uint8_t)frame->message[i];
    }

    frame->checksum[0] = itoa(sum % 0xF, &(frame->checksum[0]), 16);
    frame->checksum[1] = itoa(sum / 0xF, &(frame->checksum[1]), 16);
}