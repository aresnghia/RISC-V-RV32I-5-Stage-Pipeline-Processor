module Control_Unit (
    input  [6:0] opcode,
    
    output reg ALUSrc,
    output reg [1:0] ALUOp,
    output reg RegWrite,
    output reg MemRead,
    output reg MemWrite,
    output reg MemtoReg,
    output reg Branch,
    output reg Jump,
    output reg Jalr
);

    always @(*) begin

        ALUSrc   = 1'b0;
        ALUOp    = 2'b00;
        RegWrite = 1'b0;
        MemRead  = 1'b0;
        MemWrite = 1'b0;
        MemtoReg = 1'b0;
        Branch   = 1'b0;
        Jump     = 1'b0;
        Jalr     = 1'b0;

        case(opcode)
            // Nhóm R-Type (add, sub, and, or, slt,...)
            7'b0110011: begin 
                ALUSrc   = 1'b0;     // ALU xài rs2
                ALUOp    = 2'b10;    // Báo cho ALU_Control biết đây là tính toán
                RegWrite = 1'b1;     // Cho phép ghi kết quả vào RF
            end

            // Nhóm I-Type Arithmetic (addi, ori, slli,...)
            7'b0010011: begin 
                ALUSrc   = 1'b1;     // ALU xài số Imm
                ALUOp    = 2'b11;    // Vẫn báo là tính toán (Để ALU_Control soi funct3)
                RegWrite = 1'b1;
            end

            // Nhóm Load (lw, lh, lb, lbu, lhu)
            7'b0000011: begin 
                ALUSrc   = 1'b1;     // Lấy Imm cộng vào địa chỉ nền
                ALUOp    = 2'b00;    // Ép ALU làm phép CỘNG
                RegWrite = 1'b1;     // Load xong phải cất vào RF
                MemRead  = 1'b1;     // Cho phép đọc RAM (kích hoạt Forwarding / Stall)
                MemtoReg = 1'b1;     // Kéo Mux lấy Data từ RAM thay vì ALU
            end

            // Nhóm Store (sw, sh, sb)
            7'b0100011: begin 
                ALUSrc   = 1'b1;     // Lấy Imm cộng vào địa chỉ nền
                ALUOp    = 2'b00;    // Ép ALU làm phép CỘNG
                MemWrite = 1'b1;     // Bật chốt an toàn để ghi RAM
            end

            // Nhóm Branch (beq, bne, blt, bge,...)
            7'b1100011: begin 
                ALUSrc   = 1'b0;     // Xài rs1 và rs2 (Mặc dù khối Branch_Comp của bác đã lo vụ này rồi)
                ALUOp    = 2'b01;    // Ép ALU làm phép TRỪ (Di tích lịch sử, kệ nó)
                Branch   = 1'b1;     // Xác nhận đây là lệnh nhảy có điều kiện
            end

            // JAL (Jump and Link)
            7'b1101111: begin 
                RegWrite = 1'b1;     // Cho phép ghi (Lưu Return Address pc+4)
                Jump     = 1'b1;     // Kích hoạt cờ bẻ lái PC vô điều kiện
            end

            // JALR (Jump and Link Register)
            7'b1100111: begin 
                ALUSrc   = 1'b1;     // ALU lấy rs1 + Imm (Để tính tọa độ nhảy JALR)
                ALUOp    = 2'b00;    // Ép ALU làm phép CỘNG
                RegWrite = 1'b1;     // Cho phép ghi (Lưu Return Address pc+4)
                Jump     = 1'b1;     // Bật cờ nhảy
                Jalr     = 1'b1;     // Bật cờ bẻ ngã 3 của Mux PC sang nhánh ALU_Result
            end

            // LUI (Load Upper Immediate)
            7'b0110111: begin 
                ALUSrc   = 1'b1;     // ALU lấy Imm
                ALUOp    = 2'b00;    // Ép ALU làm phép CỘNG (0 + Imm) vì bác đã code sel_A ép in0 về 0
                RegWrite = 1'b1;     // Ghi vào RF
            end

            // AUIPC (Add Upper Immediate to PC)
            7'b0010111: begin 
                ALUSrc   = 1'b1;     // ALU lấy Imm
                ALUOp    = 2'b00;    // Ép ALU làm phép CỘNG (PC + Imm) vì bác đã code sel_A ép in0 về PC
                RegWrite = 1'b1;     // Ghi vào RF
            end

            default: begin
                // Nếu gặp lệnh tào lao (Opcode rác), nó sẽ giữ nguyên MẶC ĐỊNH (cấm ghi, cấm nhảy)
            end
        endcase
    end
endmodule