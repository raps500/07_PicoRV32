// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.

#ifndef FIRMWARE_H
#define FIRMWARE_H

#include <stdint.h>
#include <stdbool.h>

// irq.c
uint32_t *irq(uint32_t *regs, uint32_t irqs);

// print.c
void print_chr(char ch);
void print_str(const char *p);
void print_dec(unsigned int val);
void print_hex(unsigned int val, int digits);

// sieve.c
void sieve(void);

// multest.c
uint32_t hard_mul(uint32_t a, uint32_t b);
uint32_t hard_mulh(uint32_t a, uint32_t b);
uint32_t hard_mulhsu(uint32_t a, uint32_t b);
uint32_t hard_mulhu(uint32_t a, uint32_t b);
void multest(void);

/*
typedef struct s_port_tag
{
    union
    {
        uint32_t bit31:1;
    }
} s_port;
*/

#define TIMER0              (* (volatile uint32_t *) 0xffff0030 )
#define TIMER1              (* (volatile uint32_t *) 0xffff0034 )
#define UARTTX              (* (volatile uint32_t *) 0xffff0040 )
#define UARTRX              (* (volatile uint32_t *) 0xffff0050 )
#define PORTA               (* (volatile uint32_t *) 0xffff0060 )
#define PORTA_BIT0          ((* (volatile uint32_t *) 0xffff0060 ) & 1U)

#define UART_RX_EMPTY       0x00000100U

#endif
