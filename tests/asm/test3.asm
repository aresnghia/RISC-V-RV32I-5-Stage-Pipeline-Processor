.data
buffer: .space 512      # 128 words

.text
main:

    la   t0, buffer     # địa chỉ ghi
    li   t1, 0          # i = 0

loop:
    slli t2, t1, 2      # t2 = i * 4
    add  t2, t2, t1     # t2 = i * 5

    sw   t2, 0(t0)

    addi t0, t0, 4
    addi t1, t1, 1

    li   t3, 128
    blt  t1, t3, loop

done:
    j done