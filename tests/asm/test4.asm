.data
buf: .word 0

.text
main:
    li t0, 15

    addi t1, t0, 5
    andi t2, t0, 7
    ori  t3, t0, 8
    xori t4, t0, 3

    slli t5, t0, 2
    srli t6, t5, 1
    srai s0, t5, 1

    slti s1, t0, 20
    sltiu s2, t0, 20

    la s3, buf
    sw s0, 0(s3)

    lw s4, 0(s3)