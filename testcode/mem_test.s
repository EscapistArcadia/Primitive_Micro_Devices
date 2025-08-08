.section .text
.globl _start
_start:
    addi x1, x0, 4
    # nop             # nops in between to prevent hazard
    # nop
    # nop
    # nop
    # nop
    addi x3, x1, 8
    # nop
    # nop
    # nop
    # nop
    # nop

  addi    x2, x0, 10        # x2 = 10
     add     x4, x1, x2        # x4 = x1 + x2
     sub     x5, x4, x1        # x5 = x4 - x1
     sll     x6, x5, x2        # x6 = x5 << (x2[4:0])  (shift amount from x2 = 10)
     srl     x7, x6, x1        # x7 = x6 >> (x1[4:0])  (logical shift)
     sra     x8, x7, x2        # x8 = x7 >>> (x2[4:0]) (arithmetic shift)
     and     x9, x8, x1        # x9 = x8 & x1
     or      x10, x9, x2       # x10 = x9 | x2
     xor     x11, x10, x1      # x11 = x10 ^ x1
     slt     x12, x11, x2      # x12 = (x11 < x2) ? 1 : 0
     sltu    x13, x12, x1      # x13 = (x12 < x1) ? 1 : 0
     addi    x14, x13, 20      # x14 = x13 + 20
     add     x15, x14, x2      # x15 = x14 + x2
     sub     x16, x15, x1      # x16 = x15 - x1
     sll     x17, x16, x2      # x17 = x16 << (x2[4:0])
     srl     x18, x17, x1      # x18 = x17 >> (x1[4:0])
     sra     x19, x18, x2      # x19 = x18 >>> (x2[4:0])
     and     x20, x19, x1      # x20 = x19 & x1
     or      x21, x20, x2      # x21 = x20 | x2
     xor     x22, x21, x1      # x22 = x21 ^ x1
     slt     x23, x22, x2      # x23 = (x22 < x2) ? 1 : 0
     sltu    x24, x23, x1      # x24 = (x23 < x1) ? 1 : 0

     addi    x25, x24, -30      # x25 = x24 + 30
     add     x26, x25, x2      # x26 = x25 + x2
     sub     x27, x26, x1      # x27 = x26 - x1
     sll     x28, x27, x2      # x28 = x27 << (x2[4:0])
     srl     x29, x28, x1      # x29 = x28 >> (x1[4:0])
     sra     x30, x29, x2      # x30 = x29 >>> (x2[4:0])
     and     x31, x30, x1      # x31 = x30 & x1

     addi    x1, x1, 1         # x1 = previous x1 + 1
     addi    x2, x2, 2         # x2 = previous x2 + 2
     add     x3, x3, x1        # x3 = x3 + x1
     sub     x4, x4, x2        # x4 = x4 - x2
     sll     x5, x5, x1        # x5 = x5 << (x1[4:0])
     srl     x6, x6, x2        # x6 = x6 >> (x2[4:0])
     sra     x7, x7, x1        # x7 = x7 >>> (x1[4:0])
     and     x8, x8, x2        # x8 = x8 & x2
     or      x9, x9, x1        # x9 = x9 | x1
     xor     x10, x10, x2      # x10 = x10 ^ x2
     slt     x11, x11, x1      # x11 = (x11 < x1) ? 1 : 0
     sltu    x12, x12, x2      # x12 = (x12 < x2) ? 1 : 0
     addi    x13, x13, 3       # x13 = x13 + 3
     add     x14, x14, x2      # x14 = x14 + x2
     sub     x15, x15, x1      # x15 = x15 - x1
     sll     x16, x16, x2      # x16 = x16 << (x2[4:0])
     srl     x17, x17, x1      # x17 = x17 >> (x1[4:0])
     sra     x18, x18, x2      # x18 = x18 >>> (x2[4:0])
     and     x19, x19, x1      # x19 = x19 & x1
     or      x20, x20, x2      # x20 = x20 | x2
     xor     x21, x21, x1      # x21 = x21 ^ x1
     slt     x22, x22, x2      # x22 = (x22 < x2) ? 1 : 0
     sltu    x23, x23, x1      # x23 = (x23 < x1) ? 1 : 0

     addi    x24, x24, 4       # x24 = x24 + 4
     add     x25, x25, x2      # x25 = x25 + x2
     sub     x26, x26, x1      # x26 = x26 - x1
     sll     x27, x27, x2      # x27 = x27 << (x2[4:0])
     srl     x28, x28, x1      # x28 = x28 >> (x1[4:0])
     sra     x29, x29, x2      # x29 = x29 >>> (x2[4:0])
     and     x30, x30, x1      # x30 = x30 & x1
     or      x31, x31, x2      # x31 = x31 | x2

     addi    x1, x1, 5         # Increment x1
     addi    x2, x2, 6         # Increment x2
     add     x3, x3, x2        # x3 = x3 + x2
     sub     x4, x4, x1        # x4 = x4 - x1
     sll     x5, x5, x2        # x5 = x5 << (x2[4:0])
     srl     x6, x6, x1        # x6 = x6 >> (x1[4:0])
     sra     x7, x7, x2        # x7 = x7 >>> (x2[4:0])
     and     x8, x8, x1        # x8 = x8 & x1
     or      x9, x9, x2        # x9 = x9 | x2
     xor     x10, x10, x1      # x10 = x10 ^ x1
     slt     x11, x11, x2      # x11 = (x11 < x2) ? 1 : 0
     sltu    x12, x12, x1      # x12 = (x12 < x1) ? 1 : 0
     addi    x13, x13, 7       # x13 = x13 + 7
     add     x14, x14, x2      # x14 = x14 + x2
     sub     x15, x15, x1      # x15 = x15 - x1
     sll     x16, x16, x2      # x16 = x16 << (x2[4:0])
     srl     x17, x17, x1      # x17 = x17 >> (x1[4:0])
     sra     x18, x18, x2      # x18 = x18 >>> (x2[4:0])
     and     x19, x19, x1      # x19 = x19 & x1
     or      x20, x20, x2      # x20 = x20 | x2
     xor     x21, x21, x1      # x21 = x21 ^ x1
     slt     x22, x22, x2      # x22 = (x22 < x2) ? 1 : 0
     sltu    x23, x23, x1      # x23 = (x23 < x1) ? 1 : 0
     addi    x24, x24, 8       # x24 = x24 + 8
     add     x25, x25, x2      # x25 = x25 + x2
     sub     x26, x26, x1      # x26 = x26 - x1
     sll     x27, x27, x2      # x27 = x27 << (x2[4:0])
     srl     x28, x28, x1      # x28 = x28 >> (x1[4:0])
     sra     x29, x29, x2      # x29 = x29 >>> (x2[4:0])
     and     x30, x30, x1      # x30 = x30 & x1
     or      x31, x31, x2      # x31 = x31 | x2

     addi    x1, x1, 9         # x1 = x1 + 9
     addi    x2, x2, -10        # x2 = x2 + 10
     add     x3, x3, x1        # x3 = x3 + x1
     sub     x4, x4, x2        # x4 = x4 - x2
     sll     x5, x5, x1        # x5 = x5 << (x1[4:0])
     srl     x6, x6, x2        # x6 = x6 >> (x2[4:0])
     sra     x7, x7, x1        # x7 = x7 >>> (x1[4:0])
     and     x8, x8, x2        # x8 = x8 & x2
     or      x9, x9, x1        # x9 = x9 | x1
     xor     x10, x10, x2      # x10 = x10 ^ x2
     slt     x11, x11, x1      # x11 = (x11 < x1) ? 1 : 0
     sltu    x12, x12, x2      # x12 = (x12 < x2) ? 1 : 0
     addi    x13, x13, 11      # x13 = x13 + 11
     add     x14, x14, x1      # x14 = x14 + x1
     sub     x15, x15, x2      # x15 = x15 - x2
     sll     x16, x16, x1      # x16 = x16 << (x1[4:0])
     srl     x17, x17, x2      # x17 = x17 >> (x2[4:0])
     sra     x18, x18, x1      # x18 = x18 >>> (x1[4:0])
     and     x19, x19, x2      # x19 = x19 & x2
     or      x20, x20, x1      # x20 = x20 | x1
     xor     x21, x21, x2      # x21 = x21 ^ x2
     slt     x22, x22, x1      # x22 = (x22 < x1) ? 1 : 0
     sltu    x23, x23, x2      # x23 = (x23 < x2) ? 1 : 0
     addi    x24, x24, 12      # x24 = x24 + 12
     add     x25, x25, x1      # x25 = x25 + x1
     sub     x26, x26, x2      # x26 = x26 - x2
     sll     x27, x27, x1      # x27 = x27 << (x1[4:0])
     srl     x28, x28, x2      # x28 = x28 >> (x2[4:0])
     sra     x29, x29, x1      # x29 = x29 >>> (x1[4:0])
     and     x30, x30, x2      # x30 = x30 & x2
     or      x31, x31, x1      # x31 = x31 | x1

     addi    x2, x0, -10        # x2 = 10
     add     x4, x1, x2        # x4 = x1 + x2
     sub     x5, x4, x1        # x5 = x4 - x1
     sll     x6, x5, x2        # x6 = x5 << (x2[4:0])  (shift amount from x2 = 10)
     srl     x7, x6, x1        # x7 = x6 >> (x1[4:0])  (logical shift)
     sra     x8, x7, x2        # x8 = x7 >>> (x2[4:0]) (arithmetic shift)
     and     x9, x8, x1        # x9 = x8 & x1
     or      x10, x9, x2       # x10 = x9 | x2
     xor     x11, x10, x1      # x11 = x10 ^ x1
     slt     x12, x11, x2      # x12 = (x11 < x2) ? 1 : 0
     sltu    x13, x12, x1      # x13 = (x12 < x1) ? 1 : 0
     addi    x14, x13, -20      # x14 = x13 + 20
     add     x15, x14, x2      # x15 = x14 + x2
     sub     x16, x15, x1      # x16 = x15 - x1
     sll     x17, x16, x2      # x17 = x16 << (x2[4:0])
     srl     x18, x17, x1      # x18 = x17 >> (x1[4:0])
     sra     x19, x18, x2      # x19 = x18 >>> (x2[4:0])
     and     x20, x19, x1      # x20 = x19 & x1
     or      x21, x20, x2      # x21 = x20 | x2
     xor     x22, x21, x1      # x22 = x21 ^ x1
     slt     x23, x22, x2      # x23 = (x22 < x2) ? 1 : 0
     sltu    x24, x23, x1      # x24 = (x23 < x1) ? 1 : 0

     addi    x25, x24, -30      # x25 = x24 + 30
     add     x26, x25, x2      # x26 = x25 + x2
     sub     x27, x26, x1      # x27 = x26 - x1
     sll     x28, x27, x2      # x28 = x27 << (x2[4:0])
     srl     x29, x28, x1      # x29 = x28 >> (x1[4:0])
     sra     x30, x29, x2      # x30 = x29 >>> (x2[4:0])
     and     x31, x30, x1      # x31 = x30 & x1

     addi    x1, x1, -1         # x1 = previous x1 + 1
     addi    x2, x2, -2         # x2 = previous x2 + 2
     add     x3, x3, x1        # x3 = x3 + x1
     sub     x4, x4, x2        # x4 = x4 - x2
     sll     x5, x5, x1        # x5 = x5 << (x1[4:0])
     srl     x6, x6, x2        # x6 = x6 >> (x2[4:0])
     sra     x7, x7, x1        # x7 = x7 >>> (x1[4:0])
     and     x8, x8, x2        # x8 = x8 & x2
     or      x9, x9, x1        # x9 = x9 | x1
     xor     x10, x10, x2      # x10 = x10 ^ x2
     slt     x11, x11, x1      # x11 = (x11 < x1) ? 1 : 0
     sltu    x12, x12, x2      # x12 = (x12 < x2) ? 1 : 0
     addi    x13, x13, -3       # x13 = x13 + 3
     add     x14, x14, x2      # x14 = x14 + x2
     sub     x15, x15, x1      # x15 = x15 - x1
     sll     x16, x16, x2      # x16 = x16 << (x2[4:0])
     srl     x17, x17, x1      # x17 = x17 >> (x1[4:0])
     sra     x18, x18, x2      # x18 = x18 >>> (x2[4:0])
     and     x19, x19, x1      # x19 = x19 & x1
     or      x20, x20, x2      # x20 = x20 | x2
     xor     x21, x21, x1      # x21 = x21 ^ x1
     slt     x22, x22, x2      # x22 = (x22 < x2) ? 1 : 0
     sltu    x23, x23, x1      # x23 = (x23 < x1) ? 1 : 0

     addi    x24, x24, -4       # x24 = x24 + 4
     add     x25, x25, x2      # x25 = x25 + x2
     sub     x26, x26, x1      # x26 = x26 - x1
     sll     x27, x27, x2      # x27 = x27 << (x2[4:0])
     srl     x28, x28, x1      # x28 = x28 >> (x1[4:0])
     sra     x29, x29, x2      # x29 = x29 >>> (x2[4:0])
     and     x30, x30, x1      # x30 = x30 & x1
     or      x31, x31, x2      # x31 = x31 | x2

     addi    x1, x1, 5         # Increment x1
     addi    x2, x2, -6         # Increment x2
     add     x3, x3, x2        # x3 = x3 + x2
     sub     x4, x4, x1        # x4 = x4 - x1
     sll     x5, x5, x2        # x5 = x5 << (x2[4:0])
     srl     x6, x6, x1        # x6 = x6 >> (x1[4:0])
     sra     x7, x7, x2        # x7 = x7 >>> (x2[4:0])
     and     x8, x8, x1        # x8 = x8 & x1
     or      x9, x9, x2        # x9 = x9 | x2
     xor     x10, x10, x1      # x10 = x10 ^ x1
     slt     x11, x11, x2      # x11 = (x11 < x2) ? 1 : 0
     sltu    x12, x12, x1      # x12 = (x12 < x1) ? 1 : 0
     addi    x13, x13, -7       # x13 = x13 + 7
     add     x14, x14, x2      # x14 = x14 + x2
     sub     x15, x15, x1      # x15 = x15 - x1
     sll     x16, x16, x2      # x16 = x16 << (x2[4:0])
     srl     x17, x17, x1      # x17 = x17 >> (x1[4:0])
     sra     x18, x18, x2      # x18 = x18 >>> (x2[4:0])
     and     x19, x19, x1      # x19 = x19 & x1
     or      x20, x20, x2      # x20 = x20 | x2
     xor     x21, x21, x1      # x21 = x21 ^ x1
     slt     x22, x22, x2      # x22 = (x22 < x2) ? 1 : 0
     sltu    x23, x23, x1      # x23 = (x23 < x1) ? 1 : 0
     addi    x24, x24, -8       # x24 = x24 + 8
     add     x25, x25, x2      # x25 = x25 + x2
     sub     x26, x26, x1      # x26 = x26 - x1
     sll     x27, x27, x2      # x27 = x27 << (x2[4:0])
     srl     x28, x28, x1      # x28 = x28 >> (x1[4:0])
     sra     x29, x29, x2      # x29 = x29 >>> (x2[4:0])
     and     x30, x30, x1      # x30 = x30 & x1
     or      x31, x31, x2      # x31 = x31 | x2

     addi    x1, x1, -9         # x1 = x1 + 9
     addi    x2, x2, -10        # x2 = x2 + 10
     add     x3, x3, x1        # x3 = x3 + x1
     sub     x4, x4, x2        # x4 = x4 - x2
     sll     x5, x5, x1        # x5 = x5 << (x1[4:0])
     srl     x6, x6, x2        # x6 = x6 >> (x2[4:0])
     sra     x7, x7, x1        # x7 = x7 >>> (x1[4:0])
     and     x8, x8, x2        # x8 = x8 & x2
     or      x9, x9, x1        # x9 = x9 | x1
     xor     x10, x10, x2      # x10 = x10 ^ x2
     slt     x11, x11, x1      # x11 = (x11 < x1) ? 1 : 0
     sltu    x12, x12, x2      # x12 = (x12 < x2) ? 1 : 0
     addi    x13, x13, 11      # x13 = x13 + 11
     add     x14, x14, x1      # x14 = x14 + x1
     sub     x15, x15, x2      # x15 = x15 - x2
     sll     x16, x16, x1      # x16 = x16 << (x1[4:0])
     srl     x17, x17, x2      # x17 = x17 >> (x2[4:0])
     sra     x18, x18, x1      # x18 = x18 >>> (x1[4:0])
     and     x19, x19, x2      # x19 = x19 & x2
     or      x20, x20, x1      # x20 = x20 | x1
     xor     x21, x21, x2      # x21 = x21 ^ x2
     slt     x22, x22, x1      # x22 = (x22 < x1) ? 1 : 0
     sltu    x23, x23, x2      # x23 = (x23 < x2) ? 1 : 0
     addi    x24, x24, 12      # x24 = x24 + 12
     add     x25, x25, x1      # x25 = x25 + x1
     sub     x26, x26, x2      # x26 = x26 - x2
     sll     x27, x27, x1      # x27 = x27 << (x1[4:0])
     srl     x28, x28, x2      # x28 = x28 >> (x2[4:0])
     sra     x29, x29, x1      # x29 = x29 >>> (x1[4:0])
     and     x30, x30, x2      # x30 = x30 & x2
     or      x31, x31, x1      # x31 = x31 | x1
    
        # Group 1
    lui    x10, 0xAAAAF    # x10 becomes 0xAAAAA000 (upper 20 bits)
    addi   x10, x10, 0x500 # x10 becomes 0xAAAAA500

    addi   x1, x0, 37        # x1 = 37 (random value)
    sw     x1, 12(x10)       # store x1 at address 0xAAAAA500 + 12 = 0xAAAAA50C
    lw     x2, 12(x10)       # load value from 0xAAAAA50C into x2
    addi   x2, x2, 5         # x2 = x2 + 5
    sw     x2, 28(x10)       # store x2 at address 0xAAAAA500 + 28 = 0xAAAAA51C

    # Group 2
    addi   x3, x0, 0xA3      # x3 = 0xA3 (163 decimal)
    sw     x3, 8(x10)         # store x3 at address 8
    lw     x4, 8(x10)         # load value from address 8 into x4
    addi   x4, x4, -10       # x4 = x4 - 10
    sw     x4, 20(x10)        # store updated x4 at address 20

    # Group 3
    addi   x5, x0, 123       # x5 = 123
    sw     x5, 16(x10)        # store x5 at address 16
    lw     x6, 16(x10)        # load value from address 16 into x6
    addi   x6, x6, 15        # x6 = x6 + 15
    sw     x6, 24(x10)        # store updated x6 at address 24

    # Group 4
    addi   x7, x0, 0x7B      # x7 = 0x7B (123 decimal)
    sw     x7, 4(x10)         # store x7 at address 4
    lw     x8, 4(x10)         # load value from address 4 into x8
    addi   x8, x8, 32        # x8 = x8 + 32
    sw     x8, 40(x10)        # store updated x8 at address 40

    # Group 6
    addi   x11, x0, 999      # x11 = 999
    sw     x11, 100(x10)      # store x11 at address 100
    lw     x12, 100(x10)      # load value from address 100 into x12
    addi   x12, x12, -7      # x12 = x12 - 7
    sw     x12, 108(x10)      # store updated x12 at address 108

    # Group 7
    addi   x13, x0, 47       # x13 = 47
    sw     x13, 32(x10)       # store x13 at address 32
    lw     x14, 32(x10)       # load value from address 32 into x14
    addi   x14, x14, 11      # x14 = x14 + 11
    sw     x14, 48(x10)       # store updated x14 at address 48

    # Group 8
    addi   x15, x0, 0x1F     # x15 = 0x1F (31 decimal)
    sw     x15, 60(x10)       # store x15 at address 60
    lw     x16, 60(x10)       # load value from address 60 into x16
    addi   x16, x16, 22      # x16 = x16 + 22
    sw     x16, 68(x10)       # store updated x16 at address 68

    # Group 9
    addi   x17, x0, 0xFF     # x17 = 0xFF (255 decimal)
    sw     x17, 72(x10)       # store x17 at address 72
    lw     x18, 72(x10)       # load value from address 72 into x18
    addi   x18, x18, 3       # x18 = x18 + 3
    sw     x18, 76(x10)       # store updated x18 at address 76

    # Group 10
    addi   x19, x0, 15       # x19 = 15
    sw     x19, 80(x10)       # store x19 at address 80
    lw     x20, 80(x10)       # load value from address 80 into x20
    addi   x20, x20, 10      # x20 = x20 + 10
    sw     x20, 88(x10)       # store updated x20 at address 90

    li      x5, 15          # x5 = loop counter (15 iterations)
    li      x6, 0           # x6 = accumulator (sum)

        # Group 1

    addi   x1, x0, 37        # x1 = 37 (random value)
    sw     x1, 12(x10)       # store x1 at address 0xAAAAA500 + 12 = 0xAAAAA50C
    lw     x2, 12(x10)       # load value from 0xAAAAA50C into x2
    addi   x2, x2, 5         # x2 = x2 + 5
    sw     x2, 28(x10)       # store x2 at address 0xAAAAA500 + 28 = 0xAAAAA51C

    # Group 2
    addi   x3, x0, 0xA3      # x3 = 0xA3 (163 decimal)
    sw     x3, 8(x10)         # store x3 at address 8
    lw     x4, 8(x10)         # load value from address 8 into x4
    addi   x4, x4, -10       # x4 = x4 - 10
    sw     x4, 20(x10)        # store updated x4 at address 20

    # Group 3
    addi   x5, x0, 123       # x5 = 123
    sw     x5, 16(x10)        # store x5 at address 16
    lw     x6, 16(x10)        # load value from address 16 into x6
    addi   x6, x6, 15        # x6 = x6 + 15
    sw     x6, 24(x10)        # store updated x6 at address 24

    # Group 4
    addi   x7, x0, 0x7B      # x7 = 0x7B (123 decimal)
    sw     x7, 4(x10)         # store x7 at address 4
    lw     x8, 4(x10)         # load value from address 4 into x8
    addi   x8, x8, 32        # x8 = x8 + 32
    sw     x8, 40(x10)        # store updated x8 at address 40

    # Group 6
    addi   x11, x0, 999      # x11 = 999
    sw     x11, 100(x10)      # store x11 at address 100
    lw     x12, 100(x10)      # load value from address 100 into x12
    addi   x12, x12, -7      # x12 = x12 - 7
    sw     x12, 108(x10)      # store updated x12 at address 108

    # Group 7
    addi   x13, x0, 47       # x13 = 47
    sw     x13, 32(x10)       # store x13 at address 32
    lw     x14, 32(x10)       # load value from address 32 into x14
    addi   x14, x14, 11      # x14 = x14 + 11
    sw     x14, 48(x10)       # store updated x14 at address 48

    # Group 8
    addi   x15, x0, 0x1F     # x15 = 0x1F (31 decimal)
    sw     x15, 60(x10)       # store x15 at address 60
    lw     x16, 60(x10)       # load value from address 60 into x16
    addi   x16, x16, 22      # x16 = x16 + 22
    sw     x16, 68(x10)       # store updated x16 at address 68

    # Group 9
    addi   x17, x0, 0xFF     # x17 = 0xFF (255 decimal)
    sw     x17, 72(x10)       # store x17 at address 72
    lw     x18, 72(x10)       # load value from address 72 into x18
    addi   x18, x18, 3       # x18 = x18 + 3
    sw     x18, 76(x10)       # store updated x18 at address 76

    # Group 10
    addi   x19, x0, 15       # x19 = 15
    sw     x19, 80(x10)       # store x19 at address 80
    lw     x20, 80(x10)       # load value from address 80 into x20
    addi   x20, x20, 10      # x20 = x20 + 10
    sw     x20, 88(x10)       # store updated x20 at address 90

    li      x5, 15          # x5 = loop counter (15 iterations)
    li      x6, 0           # x6 = accumulator (sum)

        # Group 1

    addi   x1, x0, 37        # x1 = 37 (random value)
    sw     x1, 12(x10)       # store x1 at address 0xAAAAA500 + 12 = 0xAAAAA50C
    lw     x2, 12(x10)       # load value from 0xAAAAA50C into x2
    addi   x2, x2, 5         # x2 = x2 + 5
    sw     x2, 28(x10)       # store x2 at address 0xAAAAA500 + 28 = 0xAAAAA51C

    # Group 2
    addi   x3, x0, 0xA3      # x3 = 0xA3 (163 decimal)
    sw     x3, 8(x10)         # store x3 at address 8
    lw     x4, 8(x10)         # load value from address 8 into x4
    addi   x4, x4, -10       # x4 = x4 - 10
    sw     x4, 20(x10)        # store updated x4 at address 20

    # Group 3
    addi   x5, x0, 123       # x5 = 123
    sw     x5, 16(x10)        # store x5 at address 16
    lw     x6, 16(x10)        # load value from address 16 into x6
    addi   x6, x6, 15        # x6 = x6 + 15
    sw     x6, 24(x10)        # store updated x6 at address 24

    # Group 4
    addi   x7, x0, 0x7B      # x7 = 0x7B (123 decimal)
    sw     x7, 4(x10)         # store x7 at address 4
    lw     x8, 4(x10)         # load value from address 4 into x8
    addi   x8, x8, 32        # x8 = x8 + 32
    sw     x8, 40(x10)        # store updated x8 at address 40

    # Group 6
    addi   x11, x0, 999      # x11 = 999
    sw     x11, 100(x10)      # store x11 at address 100
    lw     x12, 100(x10)      # load value from address 100 into x12
    addi   x12, x12, -7      # x12 = x12 - 7
    sw     x12, 108(x10)      # store updated x12 at address 108

    # Group 7
    addi   x13, x0, 47       # x13 = 47
    sw     x13, 32(x10)       # store x13 at address 32
    lw     x14, 32(x10)       # load value from address 32 into x14
    addi   x14, x14, 11      # x14 = x14 + 11
    sw     x14, 48(x10)       # store updated x14 at address 48

    # Group 8
    addi   x15, x0, 0x1F     # x15 = 0x1F (31 decimal)
    sw     x15, 60(x10)       # store x15 at address 60
    lw     x16, 60(x10)       # load value from address 60 into x16
    addi   x16, x16, 22      # x16 = x16 + 22
    sw     x16, 68(x10)       # store updated x16 at address 68

    # Group 9
    addi   x17, x0, 0xFF     # x17 = 0xFF (255 decimal)
    sw     x17, 72(x10)       # store x17 at address 72
    lw     x18, 72(x10)       # load value from address 72 into x18
    addi   x18, x18, 3       # x18 = x18 + 3
    sw     x18, 76(x10)       # store updated x18 at address 76

    # Group 10
    addi   x19, x0, 15       # x19 = 15
    sw     x19, 80(x10)       # store x19 at address 80
    lw     x20, 80(x10)       # load value from address 80 into x20
    addi   x20, x20, 10      # x20 = x20 + 10
    sw     x20, 88(x10)       # store updated x20 at address 90

    li      x5, 15          # x5 = loop counter (15 iterations)
    li      x6, 0           # x6 = accumulator (sum)

        # Group 1

    addi   x1, x0, 37        # x1 = 37 (random value)
    sw     x1, 12(x10)       # store x1 at address 0xAAAAA500 + 12 = 0xAAAAA50C
    lw     x2, 12(x10)       # load value from 0xAAAAA50C into x2
    addi   x2, x2, 5         # x2 = x2 + 5
    sw     x2, 28(x10)       # store x2 at address 0xAAAAA500 + 28 = 0xAAAAA51C

    # Group 2
    addi   x3, x0, 0xA3      # x3 = 0xA3 (163 decimal)
    sw     x3, 8(x10)         # store x3 at address 8
    lw     x4, 8(x10)         # load value from address 8 into x4
    addi   x4, x4, -10       # x4 = x4 - 10
    sw     x4, 20(x10)        # store updated x4 at address 20

    # Group 3
    addi   x5, x0, 123       # x5 = 123
    sw     x5, 16(x10)        # store x5 at address 16
    lw     x6, 16(x10)        # load value from address 16 into x6
    addi   x6, x6, 15        # x6 = x6 + 15
    sw     x6, 24(x10)        # store updated x6 at address 24

    # Group 4
    addi   x7, x0, 0x7B      # x7 = 0x7B (123 decimal)
    sw     x7, 4(x10)         # store x7 at address 4
    lw     x8, 4(x10)         # load value from address 4 into x8
    addi   x8, x8, 32        # x8 = x8 + 32
    sw     x8, 40(x10)        # store updated x8 at address 40

    # Group 6
    addi   x11, x0, 999      # x11 = 999
    sw     x11, 100(x10)      # store x11 at address 100
    lw     x12, 100(x10)      # load value from address 100 into x12
    addi   x12, x12, -7      # x12 = x12 - 7
    sw     x12, 108(x10)      # store updated x12 at address 108

    # Group 7
    addi   x13, x0, 47       # x13 = 47
    sw     x13, 32(x10)       # store x13 at address 32
    lw     x14, 32(x10)       # load value from address 32 into x14
    addi   x14, x14, 11      # x14 = x14 + 11
    sw     x14, 48(x10)       # store updated x14 at address 48

    # Group 8
    addi   x15, x0, 0x1F     # x15 = 0x1F (31 decimal)
    sw     x15, 60(x10)       # store x15 at address 60
    lw     x16, 60(x10)       # load value from address 60 into x16
    addi   x16, x16, 22      # x16 = x16 + 22
    sw     x16, 68(x10)       # store updated x16 at address 68

    # Group 9
    addi   x17, x0, 0xFF     # x17 = 0xFF (255 decimal)
    sw     x17, 72(x10)       # store x17 at address 72
    lw     x18, 72(x10)       # load value from address 72 into x18
    addi   x18, x18, 3       # x18 = x18 + 3
    sw     x18, 76(x10)       # store updated x18 at address 76

    # Group 10
    addi   x19, x0, 15       # x19 = 15
    sw     x19, 80(x10)       # store x19 at address 80
    lw     x20, 80(x10)       # load value from address 80 into x20
    addi   x20, x20, 10      # x20 = x20 + 10
    sw     x20, 88(x10)       # store updated x20 at address 90

    li      x5, 15          # x5 = loop counter (15 iterations)
    li      x6, 0           # x6 = accumulator (sum)

        # Group 1

    addi   x1, x0, 37        # x1 = 37 (random value)
    sw     x1, 12(x10)       # store x1 at address 0xAAAAA500 + 12 = 0xAAAAA50C
    lw     x2, 12(x10)       # load value from 0xAAAAA50C into x2
    addi   x2, x2, 5         # x2 = x2 + 5
    sw     x2, 28(x10)       # store x2 at address 0xAAAAA500 + 28 = 0xAAAAA51C

    # Group 2
    addi   x3, x0, 0xA3      # x3 = 0xA3 (163 decimal)
    sw     x3, 8(x10)         # store x3 at address 8
    lw     x4, 8(x10)         # load value from address 8 into x4
    addi   x4, x4, -10       # x4 = x4 - 10
    sw     x4, 20(x10)        # store updated x4 at address 20

    # Group 3
    addi   x5, x0, 123       # x5 = 123
    sw     x5, 16(x10)        # store x5 at address 16
    lw     x6, 16(x10)        # load value from address 16 into x6
    addi   x6, x6, 15        # x6 = x6 + 15
    sw     x6, 24(x10)        # store updated x6 at address 24

    # Group 4
    addi   x7, x0, 0x7B      # x7 = 0x7B (123 decimal)
    sw     x7, 4(x10)         # store x7 at address 4
    lw     x8, 4(x10)         # load value from address 4 into x8
    addi   x8, x8, 32        # x8 = x8 + 32
    sw     x8, 40(x10)        # store updated x8 at address 40

    # Group 6
    addi   x11, x0, 999      # x11 = 999
    sw     x11, 100(x10)      # store x11 at address 100
    lw     x12, 100(x10)      # load value from address 100 into x12
    addi   x12, x12, -7      # x12 = x12 - 7
    sw     x12, 108(x10)      # store updated x12 at address 108

    # Group 7
    addi   x13, x0, 47       # x13 = 47
    sw     x13, 32(x10)       # store x13 at address 32
    lw     x14, 32(x10)       # load value from address 32 into x14
    addi   x14, x14, 11      # x14 = x14 + 11
    sw     x14, 48(x10)       # store updated x14 at address 48

    # Group 8
    addi   x15, x0, 0x1F     # x15 = 0x1F (31 decimal)
    sw     x15, 60(x10)       # store x15 at address 60
    lw     x16, 60(x10)       # load value from address 60 into x16
    addi   x16, x16, 22      # x16 = x16 + 22
    sw     x16, 68(x10)       # store updated x16 at address 68

    # Group 9
    addi   x17, x0, 0xFF     # x17 = 0xFF (255 decimal)
    sw     x17, 72(x10)       # store x17 at address 72
    lw     x18, 72(x10)       # load value from address 72 into x18
    addi   x18, x18, 3       # x18 = x18 + 3
    sw     x18, 76(x10)       # store updated x18 at address 76

    # Group 10
    addi   x19, x0, 15       # x19 = 15
    sw     x19, 80(x10)       # store x19 at address 80
    lw     x20, 80(x10)       # load value from address 80 into x20
    addi   x20, x20, 10      # x20 = x20 + 10
    sw     x20, 88(x10)       # store updated x20 at address 90

    li      x5, 15          # x5 = loop counter (15 iterations)
    li      x6, 0           # x6 = accumulator (sum)

    
halt:
    slti x0, x0, -256