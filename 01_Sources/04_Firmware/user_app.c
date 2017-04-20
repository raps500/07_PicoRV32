#include "firmware.h"

uint32_t buff;

int main (void)
{
    uint32_t temp;
    print_str("User_app loaded. RISCV32IM up and running\r\n");
    print_hex((uint32_t) &buff, 8);
    while (1)
    {
        temp = PORTA;
        PORTA = temp;
    }
}
