# RISC-V RV32I 5-Stage Pipeline Processor

A course project implementing a 32-bit RISC-V RV32I processor with a 5-stage pipeline architecture. The project includes a Verilog RTL implementation, an assembler, an Instruction Set Simulator (ISS), and an automated verification framework.

---

## Project Information

| Item | Description |
|------|-------------|
| ISA | RISC-V RV32I |
| Pipeline | 5-stage (IF, ID, EX, MEM, WB) |
| HDL | Verilog HDL |
| Software | Python |
| RTL Simulator | ModelSim / QuestaSim |
| Verification | ISS + riscv-tests |

---

## Features

- ✅ Complete RV32I base instruction set (36 instructions)
- ✅ 5-stage pipeline processor
- ✅ Data forwarding (EX-EX, MEM-EX)
- ✅ Load-use hazard detection and stall
- ✅ Branch and jump handling with pipeline flush
- ✅ RV32I Assembler
- ✅ Instruction Set Simulator (ISS)
- ✅ Automatic RTL–ISS co-simulation
- ✅ Verification using 43 test cases (5 custom tests + 38 riscv-tests)

---

## System Overview

```text
          Assembly Program
                 │
                 ▼
         Assembler (Python)
                 │
      imem.bin / dmem.bin
          ┌──────────────┐
          │              │
          ▼              ▼
     RTL (Verilog)      ISS
          │              │
          └──────┬───────┘
                 ▼
      Automatic Result Comparison
```

---

## Directory Structure

```text
DoAn1/
├── rtl/                    # Verilog RTL
│   ├── RISC_V32I.v
│   ├── ALU.v
│   ├── RF.v
│   ├── IMEM.v
│   ├── DMEM.v
│   ├── ...
│   └── tb_CPU.v
│
├── scripts/
│   ├── assembler.py
│   ├── riscv_iss.py
│   ├── main.py
│   └── config.py
│
├── tests/
│   ├── asm/
│   ├── riscv_hex/
│   ├── imem.bin
│   └── dmem.bin
│
├── results/
│   ├── registers/
│   ├── memory/
│   └── summary.txt
│
├── run_batch.do
└── README.md
```

---

## Requirements

| Tool | Version |
|------|---------|
| Python | 3.8 or later |
| ModelSim / QuestaSim | Any recent version |
| Ubuntu | 22.04+ (optional, for building riscv-tests) |
| riscv64-unknown-elf-gcc | 14.2+ |

---

## Running the Project

### 1. Execute all tests

Run the automated verification script from the `scripts` folder:

```bash
python scripts/main.py
```

What the script does:

1. Assembles the input program(s).
2. Generates `tests/imem.bin` and `tests/dmem.bin`.
3. Executes the ISS.
4. Runs RTL simulation in ModelSim (requires `vsim` available in PATH).
5. Compares register and memory contents between ISS and RTL.
6. Writes a summary to `results/summary.txt`.

If you don't have ModelSim or prefer to run only the ISS, open `scripts/main.py` and skip the ModelSim step.

### 2. View results

Open the summary file to see test outcomes:

```bash
type results\summary.txt   # Windows
cat results/summary.txt     # macOS / Linux
```

Example output:

```text
test1.asm       REG=PASSED  MEM=PASSED
test2.asm       REG=PASSED  MEM=PASSED
...
rv32ui-p-add    REG=PASSED  MEM=PASSED
```

---

## Pipeline Architecture

```text
IF → ID → EX → MEM → WB
```

Supported hazard handling:

- Forwarding
- Load-use stall
- Pipeline flush
- Branch and jump control

---

## Important Files

| File | Description |
|------|-------------|
| rtl/RISC_V32I.v | Top-level processor |
| rtl/tb_CPU.v | Testbench |
| scripts/assembler.py | RV32I assembler |
| scripts/riscv_iss.py | Instruction Set Simulator |
| scripts/main.py | Automated verification |
| run_batch.do | ModelSim simulation script |

---

## Verification Results

| Test Suite | Status |
|------------|--------|
| Custom tests | 5 / 5 Passed |
| riscv-tests | 38 / 38 Passed |
| Total | **43 / 43 Passed (100%)** |

---

## Authors

- Dương Trọng Nghĩa

**Instructor**

- KS. Trần Đại Dương

---

## License

This project was developed for educational purposes as part of **Đồ Án 1** at the University of Information Technology (UIT), Vietnam National University Ho Chi Minh City.
