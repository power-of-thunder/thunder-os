#ifndef THUNDER_RPI4_BASES_H
#define THUNDER_RPI4_BASES_H

#define GPIO_BASE       0xFE200000UL

#define GPPUD           (GPIO_BASE + 0x94)
#define GPPUDCLK0       (GPIO_BASE + 0x98)

/* PL011 UART0 */
#define UART0_BASE      0xFE201000UL

#endif