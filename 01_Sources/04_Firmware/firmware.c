#include "firmware.h"


uint8_t receiveFrame(uint8_t *buffer, uint32_t buffer_size);

uint32_t tbuff;

int main (void)
{
    volatile uint32_t temp;
    int32_t j, i;
    uint8_t *ptr;
    void (*user_app)(void);
    
    print_str("RISCV32IM up and running\r\n");
    
    print_str("Timer 0: "); print_hex(TIMER0, 8); print_str("\r\n");
    print_str("Timer 1: "); print_hex(TIMER1, 8); print_str("\r\n");
    TIMER1 = 0;
    print_str("Timer 0: "); print_hex(TIMER0, 8); print_str("\r\n");
    print_str("Timer 1: "); print_hex(TIMER1, 8); print_str("\r\n");
    
    ptr = (uint8_t *)&tbuff;
    print_str("tbuff: "); print_hex(tbuff, 8); print_str("\r\n");
    *ptr = 0xAB; 
    print_str("tbuff: "); print_hex(tbuff, 8); print_str("\r\n");
    ptr[1] = 0xBE;
    print_str("tbuff: "); print_hex(tbuff, 8); print_str("\r\n");
    ptr[2] = 0xEF;
    print_str("tbuff: "); print_hex(tbuff, 8); print_str("\r\n");
    ptr[3] = 0xFA;
    print_str("tbuff: "); print_hex(tbuff, 8); print_str("\r\n");
    ptr[2]++;
    ptr[0]++;
    print_str("tbuff: "); print_hex(tbuff, 8); print_str("\r\n");
        
    ptr = (uint8_t *) 0x4000; // start of user RAM
    print_str("Zeroing buffer...");
    for (i = 0; i < ((128-16)*1024); i++)
        ptr[i] = 0;
    
    
    print_str("Wait for binary...");
    receiveFrame(ptr, (128-16)*1024);
    
    print_str("Executing...");
    user_app = (void (*)(void)) 0x4000;
    
    (*user_app)(); // it may or may not return
}

/**
 * Receive up to 1024 bytes 
 */
uint32_t t = 0;

#define TOGGLELED { t ^= 1; PORTA = t; }

uint8_t receiveFrame(uint8_t *buffer, uint32_t buffer_size)
{
    uint32_t rxd;
    int32_t idx;
    uint8_t flag = 0;
    #define TIMEOUT 50*1000 // 1 ms timeout
    for (;;)
    {
        rxd = UARTRX;
        TIMER0 = 0;
        while (((rxd & UART_RX_EMPTY) != 0U) && (TIMER0 < TIMEOUT))
        {
            if (flag == 0)
                TIMER0 = 0; // reset timer to avoid timeout before the first char is received
            rxd = UARTRX;
        }
        if ((TIMER0 >= TIMEOUT))
            break;
        print_chr(rxd & 255);
        
        buffer[idx++] = (uint8_t) rxd & 255;
        flag = 1;
        TOGGLELED
    }
    print_str("Received: "); print_dec(idx); print_str(" bytes.\r\n");
    
}