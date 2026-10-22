dataMemory = {}
PC = 0x00400000
reg = {i: 0 for i in range(32)}

def format_imm(imm):
    value = int(imm, 2)
    if imm[0] == '1': 
        value -= (1 << len(imm))
    return value

def R_Type(funct3, funct7, rd, rs1, rs2):
    rs1_val = reg[rs1]
    rs2_val = reg[rs2]
    shamt = rs2_val & 0x1F

    if funct3 == "000":
        if funct7 == "0000000":
            reg[rd] = rs1_val + rs2_val # ADD
        elif funct7 == "0100000":
            reg[rd] = rs1_val - rs2_val # SUB
    elif funct3 == "001":
        reg[rd] = rs1_val << shamt  # SLL
    elif funct3 == "100":
        reg[rd] = rs1_val ^ rs2_val # XOR
    elif funct3 == "101":
        if funct7 == "0000000":
            reg[rd] = (rs1_val & 0xFFFFFFFF) >> shamt # SRL
        elif funct7 == "0100000": 
            signed_rs1 = rs1_val if rs1_val < 0x80000000 else rs1_val - 0x100000000
            reg[rd] = signed_rs1 >> shamt # SRA
    elif funct3 == "110":
        reg[rd] = rs1_val | rs2_val # OR
    elif funct3 == "111":
        reg[rd] = rs1_val & rs2_val # AND
    elif funct3 == "010":
        reg[rd] = 1 if (rs1_val if rs1_val < 0x80000000 else rs1_val - 0x100000000) < (rs2_val if rs2_val < 0x80000000 else rs2_val - 0x100000000) else 0 # SLT
    elif funct3 == "011":
        reg[rd] = 1 if rs1_val < rs2_val else 0 # SLTU
    
    reg[rd] &= 0xFFFFFFFF
    reg[0] = 0

def I_Type(funct3, rd, rs1, imm):
    rs1_val = reg[rs1]
    imm_val = format_imm(imm)
    shamt = imm_val & 0x1F

    if funct3 == "000":
        reg[rd] = rs1_val + imm_val # ADDI
    elif funct3 == "100":
        reg[rd] = rs1_val ^ imm_val # XORI
    elif funct3 == "110":
        reg[rd] = rs1_val | imm_val # ORI
    elif funct3 == "111": 
        reg[rd] = rs1_val & imm_val # ANDI
    elif funct3 == "001":
        reg[rd] = rs1_val << shamt  # SLLI
    elif funct3 == "101":
        if imm[1] == '0':
            reg[rd] = (rs1_val & 0xFFFFFFFF) >> shamt # SRLI
        else:             
            signed_rs1 = rs1_val if rs1_val < 0x80000000 else rs1_val - 0x100000000
            reg[rd] = signed_rs1 >> shamt # SRAI
    elif funct3 == "010":
        signed_rs1 = rs1_val if rs1_val < 0x80000000 else rs1_val - 0x100000000
        signed_imm = imm_val if imm_val < 0x800 else imm_val - 0x1000 # Ép kiểu âm cho imm 12-bit
        reg[rd] = 1 if signed_rs1 < signed_imm else 0 # SLTI
    elif funct3 == "011":
        reg[rd] = 1 if (rs1_val & 0xFFFFFFFF) < (imm_val & 0xFFFFFFFF) else 0 # SLTIU
    reg[rd] &= 0xFFFFFFFF
    reg[0] = 0

def mem_write_byte(addr, value):
    word_addr = (addr >> 2) << 2
    byte_offset = addr & 0x3
    word = dataMemory.get(word_addr, 0)
    mask = ~(0xFF << (byte_offset * 8)) & 0xFFFFFFFF
    dataMemory[word_addr] = (word & mask) | ((value & 0xFF) << (byte_offset * 8))

def mem_read_byte(addr):
    word_addr = (addr >> 2) << 2
    byte_offset = addr & 0x3
    return (dataMemory.get(word_addr, 0) >> (byte_offset * 8)) & 0xFF

def S_Type(funct3, rs1, rs2, imm):
    addr = reg[rs1] + format_imm(imm)
    value = reg[rs2]
    if funct3 == "000":   # SB
        mem_write_byte(addr, value)
    elif funct3 == "001": # SH
        mem_write_byte(addr, value)
        mem_write_byte(addr + 1, value >> 8)
    elif funct3 == "010": # SW
        mem_write_byte(addr, value)
        mem_write_byte(addr + 1, value >> 8)
        mem_write_byte(addr + 2, value >> 16)
        mem_write_byte(addr + 3, value >> 24)

def IL_Type(funct3, rd, rs1, imm):
    addr = reg[rs1] + format_imm(imm)
    if funct3 == "000":   # LB
        val = mem_read_byte(addr)
        reg[rd] = val - 0x100 if val >= 0x80 else val
    elif funct3 == "001": # LH
        b0 = mem_read_byte(addr)
        b1 = mem_read_byte(addr + 1)
        val = b0 | (b1 << 8)
        reg[rd] = val - 0x10000 if val >= 0x8000 else val
    elif funct3 == "010": # LW
        b0 = mem_read_byte(addr)
        b1 = mem_read_byte(addr + 1)
        b2 = mem_read_byte(addr + 2)
        b3 = mem_read_byte(addr + 3)
        reg[rd] = b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)
    elif funct3 == "100": # LBU
        reg[rd] = mem_read_byte(addr)
    elif funct3 == "101": # LHU
        b0 = mem_read_byte(addr)
        b1 = mem_read_byte(addr + 1)
        reg[rd] = b0 | (b1 << 8)
    reg[rd] &= 0xFFFFFFFF
    reg[0] = 0

def B_Type(funct3, rs1, rs2, imm):
    global PC
    rs1_val = reg[rs1]
    rs2_val = reg[rs2]

    s_rs1 = rs1_val if rs1_val < 0x80000000 else rs1_val - 0x100000000
    s_rs2 = rs2_val if rs2_val < 0x80000000 else rs2_val - 0x100000000

    jump = False
    if funct3 == "000":
        jump = (rs1_val == rs2_val) # BEQ
    elif funct3 == "001":
        jump = (rs1_val != rs2_val) # BNE
    elif funct3 == "100":
        jump = (s_rs1 < s_rs2)      # BLT
    elif funct3 == "101":
        jump = (s_rs1 >= s_rs2)     # BGE
    elif funct3 == "110":
        jump = (rs1_val < rs2_val)  # BLTU
    elif funct3 == "111":
        jump = (rs1_val >= rs2_val) # BGEU

    if jump:
        PC += format_imm(imm) - 4

def U_Type(opcode, rd, imm):
    global PC
    if opcode == "0110111":
        reg[rd] = format_imm(imm) << 12          
    elif opcode == "0010111":
        reg[rd] = PC + (format_imm(imm) << 12)   
    reg[rd] &= 0xFFFFFFFF
    reg[0] = 0
    
def J_Type(rd, imm):
    global PC
    reg[rd] = PC + 4                  # JAL 
    PC += format_imm(imm) - 4         # Jump
    reg[0] = 0

def JALR_Type(rd, rs1, imm):
    global PC
    target_addr = (reg[rs1] + format_imm(imm)) & 0xFFFFFFFE
    reg[rd] = PC + 4
    reg[0] = 0
    PC = target_addr - 4

def instDecoder(inst):
    opcode = inst[25:32]
    rd     = int(inst[20:25], 2)
    rs1    = int(inst[12:17], 2)
    rs2    = int(inst[7:12], 2)
    funct3 = inst[17:20]
    funct7 = inst[0:7]

    if opcode == "0110011":
        R_Type(funct3, funct7, rd, rs1, rs2)
    elif opcode == "0010011":
        I_Type(funct3, rd, rs1, inst[0:12])
    elif opcode == "0000011":
        IL_Type(funct3, rd, rs1, inst[0:12])
    elif opcode == "0100011": 
        imm = inst[0:7] + inst[20:25]
        S_Type(funct3, rs1, rs2, imm)
    elif opcode == "1100011":
        imm = inst[0] + inst[24] + inst[1:7] + inst[20:24] +'0'
        B_Type(funct3, rs1, rs2, imm)
    elif opcode in ["0110111", "0010111"]:
        imm = inst[0:20]
        U_Type(opcode, rd, imm)
    elif opcode == "1101111":
        imm = inst[0] + inst[12:20] + inst[11] + inst[1:11] +'0'
        J_Type(rd, imm)
    elif opcode == "1100111":
        JALR_Type(rd, rs1, inst[0:12])
    else:
        print(f"Error: Unknown opcode {opcode} encountered at PC 0x{PC:08x}")

def loadInstructions(filename):
    instructions = []
    try:
        with open(filename, "r") as file:
            for line in file:
                clean_line = line.strip()
                if len(clean_line) == 32:
                    instructions.append(clean_line)
                elif len(clean_line) > 0:
                    print(f"Warning: Instruction '{clean_line}' is not 32-bit, skipped.")
        
        print(f"Successfully loaded {len(instructions)} instructions.")
        return instructions
    except FileNotFoundError:
        print(f"Error: File '{filename}' not found!")
        return []

def loadDataMemory(filename):
    try:
        with open(filename, "r") as file:
            count = 0
            for line in file:
                parts = line.strip().split()
                if len(parts) == 2:
                    addr = int(parts[0], 16)
                    val = int(parts[1], 16)
                    dataMemory[addr] = val
                    count += 1
        print(f"Successfully loaded {count} words into Data Memory.")
    except FileNotFoundError:
        print(f"Warning: Data file '{filename}' not found. Using empty memory.")

def writeRegisters(filename):
    with open(filename, "w") as file:
        for i in range(32):
            val = 0 if i == 0 else reg[i] & 0xFFFFFFFF
            file.write(f"x{i} 0x{val:08x}\n")

def writeMemory(filename):
    with open(filename, "w") as file:
        for addr in sorted(dataMemory.keys()):
            val = dataMemory[addr] & 0xFFFFFFFF
            # Bỏ qua vùng tohost 0x10010000
            if val != 0 and not (0x10010000 <= addr < 0x10020000):
                file.write(f"mem[0x{addr:08x}] 0x{val:08x}\n")

def appendMemory(filename):
    with open(filename, "a") as file: 
        file.write("\n--- DATA MEMORY ---\n")
        for row_addr in range(0x10010000, 0x10010200, 32):
            line = f"0x{row_addr:08x}:"
            for offset in range(0, 32, 4):
                addr = row_addr + offset
                value = dataMemory.get(addr, 0) & 0xFFFFFFFF
                line += f" 0x{value:08x}"
                
            file.write(line + "\n")

def simulate(instructions, initial_data_memory, outputFile, memFile=None):
    global PC, reg, dataMemory
    
    PC = 0x00400000
    reg = {i: 0 for i in range(32)}
    reg[2] = 0x7ffffff0  
    reg[3] = 0x10008000  
    dataMemory.clear()
    
    dataMemory.update(initial_data_memory) 
    
    if not instructions:
        print("Lỗi: Không có lệnh nào để thực thi.")
        return
        
    cycle_count = 0
    MAX_CYCLES = 100000
    
    while True:
        idx = int((PC - 0x00400000) / 4)
        
        if idx < 0 or idx >= len(instructions):
            PC += 4 
            break
    
        inst = instructions[idx]
        old_PC = PC 
        
        instDecoder(inst)
        
        PC += 4
        cycle_count += 1
        
        if PC == old_PC:
            print(f"Dừng an toàn (vòng lặp vô tận) tại PC = 0x{old_PC:08x}")
            break
            
        if cycle_count >= MAX_CYCLES:
            print("Dừng khẩn cấp: Vượt quá số vòng lặp tối đa!")
            break
    writeRegisters(outputFile)
    if memFile:
        writeMemory(memFile)
