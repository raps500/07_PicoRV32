#include "firmware.h"


uint8_t receiveFrame(uint8_t *buffer, uint32_t buffer_size);

uint32_t tbuff;



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
    #define TIMEOUT 50*10000 // 10 ms timeout
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
        //print_chr(rxd & 255);
        
        buffer[idx++] = (uint8_t) rxd & 255;
        flag = 1;
        TOGGLELED
    }
    print_str("Received: "); print_dec(idx); print_str(" bytes.\r\n");
    
}

#define TO_DEC(x) ( (x) >= 'A' ? ((x) - 55):((x) - 48) )

void receiveIHex(void)
{
    uint8_t ch, chk, end_flag, len, record_len, record_type, data;
    uint8_t state = 0;
    uint32_t addr, rxd, idx;
    uint8_t *ptr;
    end_flag = 0;
    idx = 0;
    ptr = (uint8_t *) 0x4000;
    
    while (end_flag == 0) 
    {
        rxd = UARTRX;
        
        while ((rxd & UART_RX_EMPTY) == 0U)
        {
            rxd = UARTRX;
        }
        ch = rxd & 255;
        switch(state)
        {
            case 0: if (ch == ':') 
                    {
                        state = 1; // get record len
                        TOGGLELED
                    }
                    len = 0;
                    addr = 0;
                    record_len = 0;
                    chk = 0;
                    record_type = 0;
                    data = 0;
                break;
            case 1: 
                record_len = (record_len << 4) | TO_DEC(ch);
                if (len == 1)
                {
                    len = 0;
                    state = 2;
                    TOGGLELED
                }
                else
                    len++;
                break;
            case 2: 
                addr = (addr << 4) | TO_DEC(ch);
                if (len == 3)
                {
                    len = 0;
                    state = 3;
                    addr -= 0x4000;
                    TOGGLELED
                }
                else
                    len++;
                break;
            case 3: // receive record type
                record_type = (record_type << 4) | TO_DEC(ch);
                if (len == 1)
                {
                    len = 0;
                    if (record_type == 0x01)
                        state = 5; // get checksum
                    else
                        state = 4;
                    TOGGLELED
                }
                else
                    len++;
                break;
            case 4: // get data
                data = (data << 4) | TO_DEC(ch);
                if (len == 1)
                {
                    len = 0;
                    ptr[addr++] = data;
                    if (record_len == 1)
                        state = 5; // get checksum
                    else
                        record_len--;
                    idx++;
                    data = 0;
                    TOGGLELED
                }
                else
                    len++;
                break;
            case 5:
                TOGGLELED
                chk = (chk << 4) | TO_DEC(ch);
                if (len == 1)
                {
                    len = 0;
                    if (record_type == 0x01)
                        end_flag = 1; // end of file reached
                    else
                        state = 0;
                }
                else
                    len++;
                break;
        }
        
        print_str("State: "); print_dec(state); print_str("\r\n");
        print_str("RLen: "); print_dec(record_len); print_str("\r\n");
        print_str("Addr: "); print_dec(addr); print_str("\r\n");
        print_str("RT: "); print_dec(record_type); print_str("\r\n");
        print_str("Data: "); print_dec(data); print_str("\r\n");
        print_str("Chk: "); print_dec(chk); print_str("\r\n");
        print_str("Len: "); print_dec(len); print_str("\r\n");
        
        print_str("\r\n");
        
    }
    print_str("Received: "); print_dec(idx); print_str(" bytes.\r\n");
    
}
// Dumps 512 bytes of buffer
void dump_buffer(uint8_t *ptr)
{
    int32_t i, j;
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
}

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
    print_str("Zeroing buffer...\r\n");
    for (i = 0; i < ((128-16)*1024); i++)
        ptr[i] = 0;
    
    
    print_str("Wait for binary...\r\n");
    //receiveFrame(ptr, (128-16)*1024);
    receiveIHex();
    dump_buffer((uint8_t *)0x4000);
    print_str("Executing...\r\n");
    user_app = (void (*)(void)) 0x4000;
    
    (*user_app)(); // it may or may not return
}