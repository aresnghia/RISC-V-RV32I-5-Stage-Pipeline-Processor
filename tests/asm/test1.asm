.data
arr: .word 10, 20, 30, 40
byte1: .byte 0x11
half1: .half 0x2222
.text
main:
    la t0, arr
    li t1, 5
    li t2, 7
    add t3, t1, t2
    sub t4, t2, t1
    and t5, t1, t2
    or  t6, t1, t2
    xor s0, t1, t2
    sll s1, t1, t2
    srl s2, s1, t1
    sra s3, s1, t1
    sw t3, 0(t0)
    lw s4, 0(t0)
    la s5, byte1
    lb s6, 0(s5)
    la s7, half1
    lh s8, 0(s7)
    sb t1, 0(s5)
    sh t2, 0(s7)