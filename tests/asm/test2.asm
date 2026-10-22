.data
nums: .word 1,2,3,4

.text
main:
    la t0, nums

    li t1, 10
    li t2, 20

    beq t1, t2, equal
    bne t1, t2, noteq

equal:
    addi s0, zero, 1

noteq:
    blt t1, t2, less
    bge t2, t1, greater

less:
    addi s1, zero, 2

greater:
    li s2, 100
    li s3, 50

    bltu s3, s2, unsigned_less
    bgeu s2, s3, unsigned_greater

unsigned_less:
    add s4, s2, s3

unsigned_greater:
    sub s5, s2, s3