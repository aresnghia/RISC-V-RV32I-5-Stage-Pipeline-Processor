.data
arr: .word 5,10,15,20,25,30,35,40
b1: .byte 0x11
h1: .half 0x2222

.text
main:

    # x2 làm base address thay vì x1
    la x2, arr

    # x3 x4
    li x3, 100
    li x4, 200

    # load
    lw x5, 0(x2)
    lw x6, 4(x2)

    # forwarding EX->EX
    add x7, x5, x6
    sub x8, x7, x5
    and x9, x8, x7
    or  x10, x9, x8
    xor x11, x10, x9

    # shift
    sll x12, x5, x6
    srl x13, x12, x5
    sra x14, x12, x5

    # compare
    slt  x15, x5, x6
    sltu x16, x5, x6

    # I-type
    addi x17, x7, 5
    andi x18, x8, 3
    ori  x19, x9, 8
    xori x20, x10, 1

    slli x21, x5, 2
    srli x22, x21, 1
    srai x23, x21, 1

    slti  x24, x5, 20
    sltiu x25, x5, 20

    # byte/half
    la x26, b1
    lb x27, 0(x26)

    la x28, h1
    lh x29, 0(x28)

    # store
    sb x27, 1(x26)
    sh x29, 2(x28)
    sw x23, 8(x2)

    # branch hazard
    beq x5, x6, LABEL1
    add x30, x3, x4

LABEL1:
    bne x5, x6, LABEL2
    sub x31, x4, x3

LABEL2:

    # upper immediate
    lui x10, 0x12345

    # auipc
    auipc x11, 0

    # load-use hazard
    lw x12, 0(x2)
    add x13, x12, x12

    # more forwarding
    sub x14, x13, x12
    and x15, x14, x13
    or  x16, x15, x14

    # jump
    jal ra, FUNC

AFTER_FUNC:
    addi x17, zero, 999

END:
    beq zero, zero, END

FUNC:
    add x18, x16, x15
    jalr zero, 0(ra)