.section ".text.boot"
.global _start

_start:
    // disable all cores but one
    mrs x1, mpidr_el1
    and x1, x1, #3
    cmp x1, #0
    bne halt

    // kernal uses 0x0000 -> 0x4007FFFF
    // set C to start at 0x40080000
    ldr x0, =0x40080000
    mov sp, x0

    // __bss are defined in linker
    // where to store C runtime variables
    ldr x4, =__bss_start
    ldr x9, =__bss_end

    // zero out bss section
    mov x5, #0
    mov x6, #0
    mov x7, #0
    mov x8, #0
    b 2f

1:
    stp x5, x6, [x4], #16

2:
    cmp x4, x9
    blo 1b

    // load kernel_main function
    ldr x3, =kernel_main
    blr x3

halt:
    wfe
    b halt