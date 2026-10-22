# assembler.py
import re
import codecs
from config import *

class RiscVAssembler:
    def __init__(self):
        self.labels = {}            
        self.data_labels = {}       
        self.instructions = []
        self.machine_codes = []
        self.text_segment_base = TEXT_SEGMENT_BASE
        self.data_segment_base = DATA_SEGMENT_BASE
        self.data_memory_content = {} #lưu dữ liệu arr

    def _reg_to_bin(self, reg_str):
        reg_num = REGISTERS.get(reg_str.strip(), 0)
        return format(reg_num, '05b')

    def _imm_to_bin(self, imm_val, bits):
        if imm_val < 0: imm_val = (1 << bits) + imm_val
        return format(imm_val, f'0{bits}b')

    def _parse_memory_arg(self, arg):
        match = re.match(r"(-?(?:0x)?[\da-fA-F]+)\((.+)\)", arg)
        if match: return int(match.group(1), 0), match.group(2)
        raise ValueError(f"Sai định dạng bộ nhớ: {arg}")

    def _expand_pseudo(self, inst, args):
        pseudo_map = {
            'nop':  ('addi', ['zero', 'zero', '0']),
            'mv':   ('add', [args[0], 'zero', args[1]] if len(args) == 2 else args),
            'j':    ('jal', ['zero', args[0]] if len(args) == 1 else args),
            'ret':  ('jalr', ['zero', '0(ra)']),
            'ble':  ('bge', [args[1], args[0], args[2]] if len(args) == 3 else args),
            'bgt':  ('blt', [args[1], args[0], args[2]] if len(args) == 3 else args),
            'bleu': ('bgeu', [args[1], args[0], args[2]] if len(args) == 3 else args),
            'bgtu': ('bltu', [args[1], args[0], args[2]] if len(args) == 3 else args),
            'beqz': ('beq', [args[0], 'zero', args[1]] if len(args) == 2 else args),
            'bnez': ('bne', [args[0], 'zero', args[1]] if len(args) == 2 else args),
            'bltz': ('blt', [args[0], 'zero', args[1]] if len(args) == 2 else args),
            'bgez': ('bge', [args[0], 'zero', args[1]] if len(args) == 2 else args),
            'blez': ('bge', ['zero', args[0], args[1]] if len(args) == 2 else args),
            'bgtz': ('blt', ['zero', args[0], args[1]] if len(args) == 2 else args),
        }
        return pseudo_map.get(inst, (inst, args))

    def _encode_r(self, inst, args):
        funct3, funct7 = R_TYPE[inst]
        rd, rs1, rs2 = self._reg_to_bin(args[0]), self._reg_to_bin(args[1]), self._reg_to_bin(args[2])
        return f"{funct7}{rs2}{rs1}{funct3}{rd}0110011"

    def _encode_i(self, inst, args):
        funct3 = I_TYPE[inst]
        rd, rs1 = self._reg_to_bin(args[0]), self._reg_to_bin(args[1])
        imm_bin = self._imm_to_bin(int(args[2], 0), 12)
        if inst in ['slli', 'srli']:
            imm_bin = "0000000" + imm_bin[7:12]
        elif inst == 'srai':
            imm_bin = "0100000" + imm_bin[7:12]
        return f"{imm_bin}{rs1}{funct3}{rd}0010011"

    def _encode_load(self, inst, args):
        funct3 = LOAD_TYPE[inst]
        rd = self._reg_to_bin(args[0])
        imm, rs1_str = self._parse_memory_arg(args[1])
        rs1 = self._reg_to_bin(rs1_str)
        imm_bin = self._imm_to_bin(imm, 12)
        return f"{imm_bin}{rs1}{funct3}{rd}0000011"

    def _encode_s(self, inst, args):
        funct3 = S_TYPE[inst]
        rs2 = self._reg_to_bin(args[0])
        imm, rs1_str = self._parse_memory_arg(args[1])
        rs1 = self._reg_to_bin(rs1_str)
        imm_bin = self._imm_to_bin(imm, 12)
        return f"{imm_bin[0:7]}{rs2}{rs1}{funct3}{imm_bin[7:12]}0100011"

    def _encode_b(self, inst, args, address):
        funct3 = B_TYPE[inst]
        rs1, rs2 = self._reg_to_bin(args[0]), self._reg_to_bin(args[1])
        target = self.labels.get(args[2])
        if target is None: raise ValueError(f"Không tìm thấy nhãn '{args[2]}'")
        offset = target - address
        imm_bin = self._imm_to_bin(offset, 13)
        return f"{imm_bin[0]}{imm_bin[2:8]}{rs2}{rs1}{funct3}{imm_bin[8:12]}{imm_bin[1]}1100011"

    def _encode_u(self, inst, args):
        opcode = U_TYPE[inst]
        rd = self._reg_to_bin(args[0])
        imm_bin = self._imm_to_bin(int(args[1], 0), 20)
        return f"{imm_bin}{rd}{opcode}"

    def _encode_j(self, inst, args, address):
        rd = self._reg_to_bin(args[0])
        target = self.labels.get(args[1])
        if target is None: raise ValueError(f"Không tìm thấy nhãn '{args[1]}'")
        offset = target - address
        imm_bin = self._imm_to_bin(offset, 21)
        return f"{imm_bin[0]}{imm_bin[10:20]}{imm_bin[9]}{imm_bin[1:9]}{rd}1101111"

    def _encode_jalr(self, args):
        rd = self._reg_to_bin(args[0])
        imm, rs1_str = self._parse_memory_arg(args[1])
        rs1 = self._reg_to_bin(rs1_str)
        imm_bin = self._imm_to_bin(imm, 12)
        return f"{imm_bin}{rs1}000{rd}1100111"

    def _encode_la_li(self, inst, args, address):
        rd = args[0]
        if inst == 'la':
            label = args[1]
            if label in self.data_labels: addr = self.data_labels[label]
            elif label in self.labels: addr = self.labels[label]
            else: raise ValueError(f"Không tìm thấy nhãn '{label}'")
            
            offset = addr - address
            upper_20 = ((offset + 0x800) >> 12) & 0xFFFFF
            lower_12 = offset & 0xFFF
            if lower_12 & 0x800: lower_12 -= 0x1000

            return [
                self._encode_u('auipc', [rd, str(upper_20)]),
                self._encode_i('addi', [rd, rd, str(lower_12)])
            ]

        else: # inst == 'li'
            addr = int(args[1], 0)
            if -2048 <= addr <= 2047:
                return [self._encode_i('addi', [rd, 'zero', str(addr)])]
            
            lower_12 = addr & 0xFFF
            upper_20 = (addr >> 12) & 0xFFFFF
            if lower_12 & 0x800:  
                upper_20 = (upper_20 + 1) & 0xFFFFF
                lower_12 -= 0x1000

            return [
                self._encode_u('lui', [rd, str(upper_20)]),
                self._encode_i('addi', [rd, rd, str(lower_12)])
            ]

    def _pass_one(self, lines):
        current_addr = self.text_segment_base
        data_addr = self.data_segment_base
        section = '.text'

        for line in lines:
            line = line.split('#')[0].strip()
            if not line: continue

            if line.startswith('.'):
                directive = line.split()[0]
                if directive == '.data': section = '.data'; continue
                elif directive == '.text': section = '.text'; continue
                elif directive == '.globl': continue

            if ':' in line:
                label, rest = line.split(':', 1)
                if section == '.text': self.labels[label.strip()] = current_addr
                else: self.data_labels[label.strip()] = data_addr
                line = rest.strip()
                if not line: continue
            #hàm này nè
            if section == '.data':
                if line.startswith('.word'):
                    words_str = line[len('.word'):].strip()
                    for w in words_str.split(','):
                        w = w.strip()
                        if w:
                            self.data_memory_content[data_addr] = int(w, 0) & 0xFFFFFFFF # lưu nè
                            data_addr += 4
                continue

            if section == '.text':
                if line.startswith('.'): continue
                parts = [p.strip() for p in re.split(r'[,\s]+', line) if p]
                if not parts: continue
                inst = parts[0].lower()
                
                self.instructions.append((current_addr, line))
                
                if inst == 'la': current_addr += 8
                elif inst == 'li':
                    try:
                        imm_val = int(parts[2], 0) if len(parts) > 2 else int(parts[1], 0)
                        current_addr += 4 if -2048 <= imm_val <= 2047 else 8
                    except:
                        current_addr += 4
                else:
                    current_addr += 4

    def _pass_two(self):
        for address, line in self.instructions:
            parts = [p.strip() for p in re.split(r'[,\s]+', line) if p]
            inst_raw, args_raw = parts[0].lower(), parts[1:]
            
            inst, args = self._expand_pseudo(inst_raw, args_raw)
            binaries = [] 

            try:
                if inst in R_TYPE: binaries.append(self._encode_r(inst, args))
                elif inst in I_TYPE: binaries.append(self._encode_i(inst, args))
                elif inst in LOAD_TYPE: binaries.append(self._encode_load(inst, args))
                elif inst in S_TYPE: binaries.append(self._encode_s(inst, args))
                elif inst in B_TYPE: binaries.append(self._encode_b(inst, args, address))
                elif inst in U_TYPE: binaries.append(self._encode_u(inst, args))
                elif inst == 'jal': binaries.append(self._encode_j(inst, args, address))
                elif inst == 'jalr': binaries.append(self._encode_jalr(args))
                elif inst in ['la', 'li']: binaries.extend(self._encode_la_li(inst, args, address))
                else: binaries.append(f"ERROR: '{inst}' chưa hỗ trợ ({line})")
            except Exception as e:
                binaries.append(f"ERROR: Lỗi cú pháp '{line}' - {e}")

            self.machine_codes.extend(binaries)

    def assemble(self, lines):
        self._pass_one(lines)
        self._pass_two()
        return self.machine_codes
    def export_data_memory(self, filename):
        with open(filename, "w") as f:
            for addr, val in self.data_memory_content.items():
                f.write(f"0x{addr:08x} 0x{val:08x}\n")
    def export_dmem_for_verilog(self, filename):
        DMEM_BASE = 0x00400000
        DMEM_SIZE = 4096
        with open(filename, "w") as f:
            for i in range(DMEM_SIZE):
                addr = DMEM_BASE + i * 4
                val = self.data_memory_content.get(addr, 0)
                
                # Ghi ra file chuỗi nhị phân 32-bit (cho $readmemb)
                f.write(f"{val:032b}\n")