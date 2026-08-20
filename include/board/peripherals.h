#ifndef THUNDER_PERIPHERALS_H
#define THUNDER_PERIPHERALS_H

#include <stdint.h>

#if defined(THUNDER_QEMU)

#include "qemu/bases.h"

#elif defined(THUNDER_RPI4)

#include "rpi4/bases.h"

#else

#define UART0_BASE 0

#endif


/* ============================================================================
 * GPIO
 * ========================================================================== */

#define GPPUD              (GPIO_BASE + 0x94)
#define GPPUDCLK0          (GPIO_BASE + 0x98)


/* ============================================================================
 * PL011 UART
 * ========================================================================== */

#define UART0_DR           (UART0_BASE + 0x00)
#define UART0_RSRECR       (UART0_BASE + 0x04)
#define UART0_FR           (UART0_BASE + 0x18)
#define UART0_ILPR         (UART0_BASE + 0x20)
#define UART0_IBRD         (UART0_BASE + 0x24)
#define UART0_FBRD         (UART0_BASE + 0x28)
#define UART0_LCRH         (UART0_BASE + 0x2C)
#define UART0_CR           (UART0_BASE + 0x30)
#define UART0_IFLS         (UART0_BASE + 0x34)
#define UART0_IMSC         (UART0_BASE + 0x38)
#define UART0_RIS          (UART0_BASE + 0x3C)
#define UART0_MIS          (UART0_BASE + 0x40)
#define UART0_ICR          (UART0_BASE + 0x44)
#define UART0_DMACR        (UART0_BASE + 0x48)
#define UART0_ITCR         (UART0_BASE + 0x80)
#define UART0_ITIP         (UART0_BASE + 0x84)
#define UART0_ITOP         (UART0_BASE + 0x88)
#define UART0_TDR         (UART0_BASE + 0x8C)


/* ============================================================================
 * UART Flag Register
 * ========================================================================== */

#define UART_FR_CTS        (1U << 0)
#define UART_FR_DSR        (1U << 1)
#define UART_FR_DCD        (1U << 2)
#define UART_FR_BUSY       (1U << 3)
#define UART_FR_RXFE       (1U << 4)
#define UART_FR_TXFF       (1U << 5)
#define UART_FR_RXFF       (1U << 6)
#define UART_FR_TXFE       (1U << 7)


/* ============================================================================
 * UART Control Register
 * ========================================================================== */

#define UART_CR_UARTEN     (1U << 0)
#define UART_CR_LBE        (1U << 7)
#define UART_CR_TXE        (1U << 8)
#define UART_CR_RXE        (1U << 9)


/* ============================================================================
 * UART Line Control Register
 * ========================================================================== */

#define UART_LCRH_BRK      (1U << 0)
#define UART_LCRH_PEN      (1U << 1)
#define UART_LCRH_EPS      (1U << 2)
#define UART_LCRH_STP2     (1U << 3)
#define UART_LCRH_FEN      (1U << 4)

#define UART_LCRH_WLEN5    (0U << 5)
#define UART_LCRH_WLEN6    (1U << 5)
#define UART_LCRH_WLEN7    (2U << 5)
#define UART_LCRH_WLEN8    (3U << 5)

#define UART_LCRH_SPS      (1U << 7)

#endif