import os
import shutil
import struct
import sys

from assembler import RiscVAssembler
from riscv_iss import simulate

# ======================================================
# CẤU HÌNH THƯ MỤC
# ======================================================
SCRIPT_DIR    = os.path.dirname(os.path.abspath(__file__))
WORK_DIR      = os.path.dirname(SCRIPT_DIR)
RESULT_DIR    = os.path.join(WORK_DIR, "results")
REG_ISS_DIR   = os.path.join(RESULT_DIR, "registers", "iss")
REG_RTL_DIR   = os.path.join(RESULT_DIR, "registers", "rtl")
MEM_ISS_DIR   = os.path.join(RESULT_DIR, "memory", "iss")
MEM_RTL_DIR   = os.path.join(RESULT_DIR, "memory", "rtl")
RISCV_HEX_DIR = os.path.join(WORK_DIR, "tests", "riscv_hex")
ASM_DIR       = os.path.join(WORK_DIR, "tests", "asm")







for d in [REG_ISS_DIR, REG_RTL_DIR, MEM_ISS_DIR, MEM_RTL_DIR]:
    os.makedirs(d, exist_ok=True)

ASM_TESTS = [
    ("test1.asm", "out1.txt"),
    ("test2.asm", "out2.txt"),
    ("test3.asm", "out3.txt"),
    ("test4.asm", "out4.txt"),
    ("test5.asm", "out5.txt"),
]

RISCV_TESTS = [
    "add", "addi", "and", "andi", "auipc",
    "beq", "bge", "bgeu", "blt", "bltu", "bne",
    "jal", "jalr", "lb", "lbu", "lh", "lhu",
    "lui", "lw", "or", "ori",
    "sb", "sh", "simple", "sll", "slli",
    "slt", "slti", "sltiu", "sltu",
    "sra", "srai", "srl", "srli",
    "sub", "sw", "xor", "xori"
]

# ======================================================
# HÀM TIỆN ÍCH
# ======================================================
def run_modelsim(script_dir, reg_out, mem_out):
    os.makedirs(os.path.dirname(reg_out), exist_ok=True)
    os.makedirs(os.path.dirname(mem_out), exist_ok=True)

    reg_tmp = os.path.join(script_dir, "reg.txt")
    mem_tmp = os.path.join(script_dir, "mem.txt")
    for f in [reg_tmp, mem_tmp, reg_out, mem_out]:
        if os.path.exists(f):
            os.remove(f)

    sim_dir = script_dir.replace('\\', '/')
    os.system(f'vsim -c -do "cd {{{sim_dir}}}; do run_batch.do" > nul 2>&1')

    ok = False
    if os.path.exists(reg_tmp):
        shutil.copyfile(reg_tmp, reg_out)
        ok = True
    else:
        open(reg_out, 'w').close()

    if os.path.exists(mem_tmp):
        shutil.copyfile(mem_tmp, mem_out)
    else:
        open(mem_out, 'w').close()

    return ok

def compare(file1, file2):
    c1 = open(file1).read().strip() if os.path.exists(file1) else ""
    c2 = open(file2).read().strip() if os.path.exists(file2) else ""
    return c1 == c2

def log_summary(summary_file, result):
    print(result)
    with open(summary_file, "a", encoding="utf-8") as sf:
        sf.write(result + "\n")

# ======================================================
# MAIN
# ======================================================
def main():
    summary_file = os.path.join(RESULT_DIR, "summary.txt")
    with open(summary_file, "w", encoding="utf-8") as sf:
        sf.write("===== TEST SUMMARY =====\n\n")

    # ======================================================
    # PHẦN 1: TEST TỪ FILE .ASM
    # ======================================================
    print("=" * 50)
    print("📂 PHẦN 1: TEST TỪ FILE .ASM")
    print("=" * 50)

    for in_name, out_name in ASM_TESTS:
        input_file = os.path.join(ASM_DIR, in_name)
        if not os.path.exists(input_file):
            print(f"Bỏ qua: {in_name}")
            continue

        try:
            with open(input_file, 'r', encoding='utf-8') as f:
                lines = f.readlines()

            assembler = RiscVAssembler()
            machine_codes = assembler.assemble(lines)

            bin_file = os.path.join(WORK_DIR, "tests", in_name.replace('.asm', '.bin'))
            with open(bin_file, 'w') as bf:
                for code in machine_codes:
                    if isinstance(code, int):
                        bf.write(f"{code:032b}\n")
                    elif isinstance(code, str):
                        if all(c in '01' for c in code) and len(code) == 32:
                            bf.write(code + '\n')
                        else:
                            bf.write(f"{int(code.replace('0x',''), 16):032b}\n")
                    else:
                        bf.write("0" * 32 + "\n")

            shutil.copyfile(bin_file, os.path.join(WORK_DIR, "tests", "imem.bin"))
            assembler.export_dmem_for_verilog(os.path.join(WORK_DIR, "tests", "dmem.bin"))

            # ISS
            mem_name = out_name.replace("out", "mem")
            iss_reg = os.path.join(REG_ISS_DIR, out_name)
            iss_mem = os.path.join(MEM_ISS_DIR, mem_name)
            data_content = getattr(assembler, 'data_memory_content', {})
            simulate(machine_codes, data_content, iss_reg, iss_mem)

            # ModelSim
            rtl_reg = os.path.join(REG_RTL_DIR, out_name.replace("out", "reg"))
            rtl_mem = os.path.join(MEM_RTL_DIR, mem_name.replace("out", "mem"))
            if run_modelsim(WORK_DIR, rtl_reg, rtl_mem):
                reg_ok = compare(iss_reg, rtl_reg)
                mem_ok = compare(iss_mem, rtl_mem)
                result = f"{in_name} : REG={'PASSED' if reg_ok else 'FAILED'}  MEM={'PASSED' if mem_ok else 'FAILED'}"
            else:
                result = f"{in_name} : NO_RTL_OUTPUT"
            log_summary(summary_file, result)

        except Exception as e:
            print(f"❌ {in_name}: {e}")

    # ======================================================
    # PHẦN 2: TEST TỪ RISCV-TESTS
    # ======================================================
    print("\n" + "=" * 50)
    print("📂 PHẦN 2: TEST TỪ RISCV-TESTS")
    print("=" * 50)

    for t in RISCV_TESTS:
        hex_file = os.path.join(RISCV_HEX_DIR, f"rv32ui-p-{t}.hex")
        if not os.path.exists(hex_file):
            print(f"⚠️  Bỏ qua {t}")
            continue

        print(f"🔄 {t}")
        try:
            # Convert hex → binary string → imem.bin
            with open(hex_file) as f:
                lines = [l.strip() for l in f if l.strip()]
            with open(os.path.join(WORK_DIR, "tests", "imem.bin"), 'w') as f:
                for line in lines:
                    f.write(f"{int(line, 16):032b}\n")
            # Reset dmem.bin về 0 cho riscv-tests (4096 dòng toàn 0)
            with open(os.path.join(WORK_DIR, "tests", "dmem.bin"), 'w') as df:
                for _ in range(4096):
                    df.write("00000000000000000000000000000000\n")

            # ISS
            machine_codes = [f"{int(l, 16):032b}" for l in lines]
            iss_reg = os.path.join(REG_ISS_DIR, f"out_riscv_{t}.txt")
            iss_mem = os.path.join(MEM_ISS_DIR, f"mem_riscv_{t}.txt")
            simulate(machine_codes, {}, iss_reg, iss_mem)

            # ModelSim
            rtl_reg = os.path.join(REG_RTL_DIR, f"reg_riscv_{t}.txt")
            rtl_mem = os.path.join(MEM_RTL_DIR, f"mem_riscv_{t}.txt")
            if run_modelsim(WORK_DIR, rtl_reg, rtl_mem):
                reg_ok = compare(iss_reg, rtl_reg)
                mem_ok = compare(iss_mem, rtl_mem)
                result = f"rv32ui-p-{t} : REG={'PASSED' if reg_ok else 'FAILED'}  MEM={'PASSED' if mem_ok else 'FAILED'}"
            else:
                result = f"rv32ui-p-{t} : NO_RTL_OUTPUT"
            log_summary(summary_file, result)

        except Exception as e:
            print(f"❌ {t}: {e}")

    print("\n" + "=" * 50)
    print("📊 SUMMARY:")
    with open(summary_file) as f:
        print(f.read())

if __name__ == "__main__":
    main()
