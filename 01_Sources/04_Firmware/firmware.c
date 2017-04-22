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
#define IS_HEX(x) ((((x) >= 'A') && ((x) <= 'F')) || (((x) >= '0') && ((x) <= '9')))
uint8_t receiveIHex(void)
{
    uint8_t ch, end_flag, len, record_len, record_type, data, chk, rchk;
    uint8_t state = 0;
    uint32_t addr, rxd, bytes_cnt;
    uint8_t *ptr;
    
    end_flag = 0;
    ptr = (uint8_t *) 0x4000;
    bytes_cnt = 0;
    chk = 0;
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
            case 0: switch (ch)
                    {
                        case ':':
                        {
                            state = 1; // get record len
                        }
                        break;
                        case 10: case 13: // ignore
                        break;
                        default:
                            end_flag = 2;
                    }
                    len = 0;
                    addr = 0;
                    record_len = 0;
                    chk = 0;
                    record_type = 0;
                    data = 0;
                    rchk = 0; // received checksum
                break;
            case 1:
                if (IS_HEX(ch))
                {
                    record_len = (record_len << 4) | TO_DEC(ch);
                    if (len == 1)
                    {
                        len = 0;
                        state++;
                        chk = record_len;
                    }
                    else
                        len++;
                }
                else
                    end_flag = 2;
                break;
            case 2: 
                if (IS_HEX(ch))
                {
                    addr = (addr << 4) | TO_DEC(ch);
                    if (len == 3)
                    {
                        len = 0;
                        state++;
                        chk += (addr >> 8);
                        chk += addr & 255;
                        addr -= 0x4000;
                    }
                    else
                        len++;
                }
                else
                    end_flag = 2; 
                break;
            case 3: // receive record type
                if (IS_HEX(ch))
                {
                    record_type = (record_type << 4) | TO_DEC(ch);
                    if (len == 1)
                    {
                        len = 0;
                        if (record_type == 0x01)
                            state = 5; // get checksum
                        else
                            state++;
                        chk += record_type;
                    }
                    else
                        len++;
                }
                else
                    end_flag = 2;
                break;
            case 4: // get data
                if (IS_HEX(ch))
                {
                    data = (data << 4) | TO_DEC(ch);
                    if (len == 1)
                    {
                        len = 0;
                        ptr[addr++] = data;
                        if (record_len == 1)
                            state++; // get checksum
                        else
                            record_len--;
                        bytes_cnt++;
                        chk += data;
                        data = 0;
                    }
                    else
                        len++;
                }
                else
                    end_flag = 2;
                break;
            case 5:
                if (IS_HEX(ch))
                {
                    rchk = (rchk << 4) | TO_DEC(ch);
                    if (len == 1)
                    {
                        len = 0;
                        if (record_type == 0x01)
                            end_flag = 1; // end of file reached
                        else
                            state = 0;
                        chk += rchk;
                        if (chk != 0)
                            end_flag = 3;
                    }
                    else
                        len++;
                }
                else
                    end_flag = 2;
                break;
        }
        /*
        print_str("State: "); print_dec(state); print_str("\r\n");
        print_str("RLen: "); print_dec(record_len); print_str("\r\n");
        print_str("Addr: "); print_dec(addr); print_str("\r\n");
        print_str("RT: "); print_dec(record_type); print_str("\r\n");
        print_str("Data: "); print_dec(data); print_str("\r\n");
        print_str("Chk: "); print_dec(chk); print_str("\r\n");
        print_str("Len: "); print_dec(len); print_str("\r\n");
        
        print_str("\r\n");
        */
    }
    switch (end_flag)
    {
        case 1: 
            print_str("Received: "); print_dec(bytes_cnt); print_str(" bytes.\r\n");
            break;
        case 2:
            print_str("Aborted. Received invalid char: "); 
            print_dec(ch); print_str("(dec) at state: ");
            print_dec(state); print_str("(dec).\r\n");
            break;
        case 3:
            print_str("Aborted. Invalid checksum received : 0x"); 
            print_hex(rchk, 2); print_str(".\r\n");
            break;
    }
        
    return end_flag;
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
    uint8_t flag;
    
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
    for (i = 0; i < ((64-16)*1024); i++)
        ptr[i] = 0;
    
    do
    {
        print_str("Wait for iHex...\r\n");
    
        flag = receiveIHex();
        dump_buffer((uint8_t *)0x4000);
    } while (flag != 1);
    
    print_str("Executing...\r\n");
    user_app = (void (*)(void)) 0x4000;
    
    (*user_app)(); // it may or may not return
}