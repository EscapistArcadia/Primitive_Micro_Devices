ooo_test.s:
.align 4
.section .text
.globl _start
    # This program will provide a simple test for
    # demonstrating OOO-ness

    # This test is NOT exhaustive
_start:

# beq x0, x0, fact
ori x31, x0, 15     # 0xAAAAA000
ori x1, x1, 1       # 0xAAAAA004
j initialize        # 0xAAAAA008

fact:
mul x1, x1, x31     # 0xAAAAA00C
add x1, x1, x31     # 0xAAAAA010
add x1, x1, x31     # 0xAAAAA014
add x1, x1, x31     # 0xAAAAA018
add x1, x1, x31     # 0xAAAAA01C
add x1, x1, x31     # 0xAAAAA020
add x1, x1, x31     # 0xAAAAA024
add x1, x1, x31     # 0xAAAAA028
add x1, x1, x31     # 0xAAAAA02C
add x1, x1, x31     # 0xAAAAA030
addi x31, x31, -1   # 0xAAAAA034
rem x31, x31, x1    # 0xAAAAA038
rem x31, x31, x1    # 0xAAAAA03C
rem x31, x31, x1    # 0xAAAAA040
rem x31, x31, x1    # 0xAAAAA044
rem x31, x31, x1    # 0xAAAAA048
rem x31, x31, x1    # 0xAAAAA04C
bne x31, x0, fact   # 0xAAAAA050
jalr x0, x25, 1     # 0xAAAAA054

initialize:
li x1, 10           # 0xAAAAA058
li x2, 20           # 0xAAAAA05C
li x5, 50           # 0xAAAAA060
li x6, 60           # 0xAAAAA064
li x8, 21           # 0xAAAAA068
li x9, 28           # 0xAAAAA06C
li x11, 8           # 0xAAAAA070
li x12, 4           # 0xAAAAA074
li x14, 3           # 0xAAAAA078
li x15, 1           # 0xAAAAA07C
li x16, -1

blt x8, x0, _start  # 0xAAAAA080

beq_test:
beq x2, x0, halt # predicted = false, actual = false, nothing happens                       # 0xAAAAA084
beq x1, x0, _start # predicted = true, actual = false, changed pc, flush, and restore       # 0xAAAAA088
beq x0, x0, bge_test # predicted = false, actual = true, changed pc, flush, and restore     # 0xAAAAA08C

bne_test:
# j bltu_test         # 0xAAAAA090
bne x0, x0, bne_test # predicted = true, actual = false, changed pc, flush, and restore    # 0xAAAAA094
# bne x2, x0, blt_test # predicted = false, actual = true, changed pc, flush, and restore   # 0xAAAAA098
bne x0, x5, bltu_test # predicted = false, actual = true, changed pc, flush, and restore # 0xAAAAA09C

blt_test:
# j bgeu_test         # 0xAAAAA094
blt x8, x0, blt_test # predicted = false, actual = false, nothing happens                  # 0xAAAAA0A0
blt x1, x0, bne_test # predicted = true, actual = false, changed pc, flush, and restore  # 0xAAAAA0A4
blt x0, x2, bgeu_test # predicted = false, actual = true, changed pc, flush, and restore # 0xAAAAA0A8

bge_test:
bge x8, x9, _start # predicted = true, actual = false, flush occurs and pc is restored      # 0xAAAAA098
bge x6, x5, blt_test # predicted = ttue, actual = true, nothing happens, no flush occurs    # 0xAAAAA09C

bltu_test:
# j retry             # 0xAAAAA0A0
bltu x8, x0, _start
bltu x0, x16, retry
bltu x16, x0, retry

bgeu_test:
# j bne_test          # 0xAAAAA0A4
# bgeu x8, x0, bgeu_test
bgeu x0, x16, bne_test
bgeu x16, x0, bne_test


retry:
    la x24, fact    # 0xAAAAA0A8
    jalr x25, 0(x24)    # 0xAAAAA0AC
halt:
    # Initial values
    li t0, 10
    li t1, -5
    li t2, 3
    li t3, 0x7FFFFFFF
    li t4, -1
    li t5, 12345678
    li t6, 0
    # li t, 0

    # ========== Branch tests ==========
    li a0, 1
    li a1, 1
    beq a0, a1, label_beq_pass
    li a2, 999     # should not execute
label_beq_pass:
    li a2, 100

    li a0, 2
    li a1, 3
    bne a0, a1, label_bne_pass
    li a3, 888     # should not execute
label_bne_pass:
    li a3, 200

    li a0, -1
    li a1, 0
    blt a0, a1, label_blt_pass
    li a4, 777     # should not execute
label_blt_pass:
    li a4, 300

    li a0, 100
    li a1, 99
    bge a0, a1, label_bge_pass
    li a5, 666     # should not execute
label_bge_pass:
    li a5, 400

    # ========== Multiplications ==========
    li t0, -3
    li t1, 7
    mul a6, t0, t1       # a6 = -21
    mulh a7, t0, t1      # signed high part
    mulhu t0, t0, t1     # unsigned high part
    mulhsu t1, t0, t1    # mixed sign high part

    # ========== Divisions ==========
    li t2, 20
    li t3, 6
    div t2, t2, t3       # 3
    rem t3, t2, t3       # 2

    li t4, 123456
    li t5, -1
    div t6, t4, t5       # -123456
    rem t6, t4, t5       # 0

    # ========== JAL and JALR ==========
    jal ra, function1
    li a0, 0xDEAD   # skipped
after_function1:
    jal function2
    li a1, 0xBEEF   # skipped
after_function2:

    # ========== Loop with JALR ==========
    li t0, 1
    li t1, 4
    la t2, loop_body
loop_start:
    jalr ra, t2, 0
    addi t0, t0, 1
    blt t0, t1, loop_start
    j end

loop_body:
    mul t3, t0, t0       # square
    div t4, t3, t0       # sanity check
    ret

# Function call via JAL
function1:
    li a0, 111
    la ra, after_function1
    jalr zero, ra, 0

# Function call via JAL with fall-through
function2:
    li a1, 333
    la ra, after_function2
    ret

# Final infinite loop
end:
    # Misaligned JALR testcase:
    la x18, end
    jalr x25, x18, 0x1

    # jal zero, _start    # comment this line to avoid infinite loop
    slti x0, x0, -256   # 0xAAAAA0B0