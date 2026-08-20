#include <stddef.h>
#include <stdint.h>
#include "board/peripherals.h"

static inline void mmio_write(uintptr_t reg, uint32_t data) {
    *(volatile uint32_t*)reg = data;
}

static inline uint32_t mmio_read(uintptr_t reg) {
    return *(volatile uint32_t*)reg;
}

static inline void delay(int32_t count) {
    __asm__ volatile(
        "1: subs %[count], %[count], #1\n"
        "bne 1b"
        : [count] "+r"(count)
        :
        : "cc"
    );
}

void uart_init() {
    mmio_write(UART0_CR, 0x00000000);

    #ifdef THUNDER_RPI4
    mmio_write(GPPUD, 0x00000000);
    delay(150);

    mmio_write(GPPUDCLK0, (1 << 14) | (1 << 15));
    delay(150);

    mmio_write(GPPUDCLK0, 0x00000000);
    #endif

    mmio_write(UART0_ICR, 0x7FF);

    mmio_write(UART0_IBRD, 1);
    mmio_write(UART0_FBRD, 40);

    mmio_write(UART0_LCRH, (1 << 4) | (1 << 5) | (1 << 6));

    mmio_write(UART0_IMSC, (1 << 1) | (1 << 4) | (1 << 5) | (1 << 6) |
            (1 << 7) | (1 << 8) | (1 << 9) | (1 << 10));

    mmio_write(UART0_CR, (1 << 0) | (1 << 8) | (1 << 9));
}

void uart_putc(unsigned char c) {
    while ( mmio_read(UART0_FR) & (1 << 5) ) { }
    mmio_write(UART0_DR, c);
}

unsigned char uart_getc() {
    while ( mmio_read(UART0_FR) & (1 << 4) ) { }
    return (unsigned char)mmio_read(UART0_DR);
}

void uart_puts(const char* str) {
    for (size_t i = 0; str[i] != '\0'; i++)
        uart_putc((unsigned char)str[i]);
}

void kernel_main(uint32_t r0, uint32_t r1, uint32_t atags) {
    // Declare as unused
    (void) r0;
    (void) r1;
    (void) atags;

    uart_init();
    uart_puts("Thunder OS is alive!\r\n");

    while (1) {
        unsigned char c = uart_getc();
        uart_putc(c);
        uart_putc('\n');
        if (c == 'q')
            break;
    }

    while (1)
        __asm__ volatile("wfe");
}