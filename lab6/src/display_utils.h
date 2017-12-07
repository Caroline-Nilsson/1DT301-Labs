#ifndef DISPLAY_UTILS_H
#define DISPLAY_UTILS_H

#include <stdint.h>		// uint8_t

// Constants
#define TRANSFER_RATE 6                 // = 2400 bps (for 1MHz)

#define INFO_FRAME_COMMAND_LEN  5
#define IMG_FRAME_COMMAND_LEN  4
#define INFO_FRAME_LINE_LEN 24
#define FRAME_CHECKSUM_LEN  2

enum FrameType {
    Information,
    Image
};

typedef enum FrameType FrameType;

/* 
 * Structure for display protocol frame. Used both for the Information frame 
 * and the Image frame.
 */
struct Frame {
    FrameType type;
    uint8_t start;
    char address;
    char command[INFO_FRAME_COMMAND_LEN];
    char line_1[INFO_FRAME_LINE_LEN];
    char line_2[INFO_FRAME_LINE_LEN];
    char checksum[FRAME_CHECKSUM_LEN];
    uint8_t end;
};

typedef struct Frame Frame;

// Function prototypes
void init_serial_comm(uint8_t ucsr1b_flags);
Frame create_frame(FrameType type);
void send_frame(const Frame *frame, int line);
void uart_transmit(unsigned char data);
unsigned char uart_receive();
void clear_array(char arr[], uint8_t length, unsigned char c);
uint8_t calculate_checksum(const Frame *frame, int line);
void set_checksum(Frame *frame, uint8_t checksum);

#endif /* DISPLAY_UTILS_H */