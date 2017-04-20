#include "firmware.h"

uint8_t exe_buffer[1024] = { 0 };
uint8_t receiveFrame(uint8_t *buffer, uint32_t buffer_size);

int main (void)
{
    volatile uint32_t temp;
    int32_t j, i;
    uint8_t *ptr;
    
    
    print_str("RISCV32IM up and running\r\n");
    
    print_str("Timer 0: "); print_hex(TIMER0, 8); print_str("\r\n");
    print_str("Timer 1: "); print_hex(TIMER1, 8); print_str("\r\n");
    TIMER1 = 0;
    print_str("Timer 0: "); print_hex(TIMER0, 8); print_str("\r\n");
    print_str("Timer 1: "); print_hex(TIMER1, 8); print_str("\r\n");
    
    receiveFrame(exe_buffer, 1024);
    
    ptr = exe_buffer;
    // dump  buffer
    for (i = 0; i < 32; i++)
    {
        print_hex((uint32_t) ptr, 8); print_str("  "); 
        for (j = 0; j < 16; j++)
        {
            print_hex(*ptr++, 2); print_chr(32); 
        }
        ptr -= 16;
        for (j = 0; j < 16; j++)
        {
            print_chr(*ptr < 32 ? '.':*ptr);
            ptr++;
        }
    }
    
    
    
    while (1)
    {
        temp = PORTA;
        PORTA = temp;
    }
    
}

/**
 * Receive up to 1024 bytes 
 */
uint32_t t = 0;

#define TOGGLELED { t ^= 1; PORTA = t; }

uint8_t receiveFrame(uint8_t *buffer, uint32_t buffer_size)
{

    uint16_t counter = 0;
    volatile uint32_t time_ = 0;
    uint32_t delayTime;
    uint32_t n;

    uint8_t p, t;
    uint8_t k = 8;
    uint32_t dataPointer = 0;

    //*** synchronisation and bit rate estimation **************************
    time_ = 0;
    // wait for edge
    p = PORTA_BIT0;
    while (p == PORTA_BIT0);

    p = PORTA_BIT0;

    TIMER0 = 0; // reset timer

    for (n = 0; n < 16; n++)
    {
        // wait for edge
        while (p == PORTA_BIT0);
        delayTime = TIMER0;
        TIMER0 = 0; // reset timer
        p = PORTA_BIT0;

        //store[counter++] = t;

        if (n >= 8)time_ += delayTime; // time accumulator for mean period calculation only the last 8 times are used
    }

    delayTime = time_ * 3 / 4 / 8;
    if ( delayTime < 60 ) delayTime = 60;
    // delay 3/4 bit
    while (TIMER0 < delayTime);

    //****************** wait for start bit ***************************
    while (p == PORTA_BIT0) // while not startbit ( no change of PORTA_BIT0 means 0 bit )
    {
        // wait for edge
        while (p == PORTA_BIT0);
        p = PORTA_BIT0;
        TIMER0 = 0;

        // delay 3/4 bit
        while (TIMER0 < delayTime);
        TIMER0 = 0;
        t = PORTA_BIT0;

        counter++;
    }

    p = PORTA_BIT0;
    TOGGLELED;
    buffer[dataPointer] = 0;
    //****************************************************************
    //receive data bits
    k = 8;
    for (n = 0; n < (buffer_size * 8); n++)
    {
        counter++;

        buffer[dataPointer] = buffer[dataPointer] << 1;
        if (p != t) buffer[dataPointer] |= 1;
        p = t;
        k--;
        if (k == 0)
        {
            dataPointer++;
            k = 8;
            buffer[dataPointer] = 0;
        }
        // wait for edge
        while (p == PORTA_BIT0);
        TIMER0 = 0;
        p = PORTA_BIT0;

        TOGGLELED;
        // delay 3/4 bit
        while (TIMER0 < delayTime);

        t = PORTA_BIT0;
        TOGGLELED;

    }
    TOGGLELED;
    print_str("Delay time: "); print_hex(delayTime, 8); print_str("\r\n");
    return true;

}