module RISC_V32I (
    input clk,
    input reset_n,
    output [31:0] ipc_out,     
    output [31:0] ialu_result,

    output [31:0] imem_addr,       // Gửi địa chỉ PC ra ngoài
    input  [31:0] imem_inst,

    output        dmem_memread,    // Báo ra ngoài: Đang đọc
    output        dmem_memwrite,   // Báo ra ngoài: Đang ghi
    output [3:0]  dmem_write_pos, // Báo ra ngoài: Mặt nạ ghi Byte
    output [31:0] dmem_addr,       // Gửi địa chỉ RAM ra ngoài
    output [31:0] dmem_write_data, // Gửi dữ liệu cần ghi ra ngoài
    input  [31:0] dmem_read_data
);
	 /*
    wire [31:0] pc_current, pc_next, pc_4, pc_target;
    wire [31:0] inst;
    wire [31:0] imm;
    wire [31:0] readdata1, readdata2, writedata;
    wire [31:0] alu_result;     
    wire [31:0] alu_input_a, alu_input_b;
    wire [31:0] readdata_dmem;
    wire alusrc, regwrite, memread, memwrite, memtoreg, branch; 
    wire [1:0] aluop;
    wire [3:0] alu_ctrl;
    wire zero_flag;
    wire pc_sel;
    wire jump;
    wire [31:0] write_data_from_memtoreg;
    */

    //HDU
	wire pc_write, if_id_write, stall_sel;
	 
    //iF
    wire [31:0] if_pc, if_pc_4, if_pc_next, if_inst;
	 
    //ID
    wire [31:0] id_pc, id_pc_4, id_inst, id_imm, id_readdata1, id_readdata2;
    wire id_alusrc, id_regwrite, id_memread, id_memwrite, id_memtoreg, id_branch, id_jump, id_is_jalr;
    wire [1:0] id_aluop;
    wire [1:0] id_sel_A = (id_inst[6:0] == 7'b0010111) ? 2'b01 : (id_inst[6:0] == 7'b0110111) ? 2'b10 : 2'b00;

    //EX
    wire [31:0] ex_pc, ex_pc_4, ex_readdata1, ex_readdata2, ex_imm, ex_pc_target, ex_alu_result;
    wire [4:0]  ex_rs1, ex_rs2, ex_rd;
    wire [1:0]  ex_aluop;
    wire [3:0]  ex_alu_ctrl;
    wire [2:0]  ex_funct3;
    wire        ex_bit30; 
    wire        ex_alusrc, ex_regwrite, ex_memread, ex_memwrite, ex_memtoreg, ex_branch, ex_jump, ex_is_jalr, ex_zero_flag, ex_branch_taken;
	wire [1:0]  ex_sel_A;
    wire [31:0] ex_alu_input_a, ex_alu_input_b;

    //MEM
    wire [31:0] mem_pc_target, mem_pc_4, mem_alu_result, mem_readdata2, mem_readdata_dmem;
    wire [4:0]  mem_rd;
    wire [2:0]  mem_funct3;
    wire        mem_zero_flag, mem_regwrite, mem_memtoreg, mem_memread, mem_memwrite, mem_branch, mem_jump, mem_is_jalr, mem_branch_taken;
    wire [3:0]  mem_write_pos;
    wire [31:0] mem_store_data;
    wire [31:0] mem_load_data;
    wire [1:0]  pc_sel; 

    //WB
    wire [31:0] wb_readdata_dmem, wb_alu_result, wb_pc_4, wb_writedata, wb_write_data_combined;
    wire [4:0]  wb_rd;
    wire        wb_regwrite, wb_memtoreg, wb_jump;

    // Output Mapping
    assign ipc_out = if_pc;     
    assign ialu_result = ex_alu_result;

    //IF
    PC my_PC (
        .clk(clk),
        .reset_n(reset_n),
        .PC_Write(pc_write),
        .PC_in(if_pc_next),
        .PC_out(if_pc)
    );

    Adder my_PC_Adder (
        .a(if_pc),
        .b(32'd4),
        .sum(if_pc_4)
    );

    assign imem_addr = if_pc;
    assign if_inst   = imem_inst;

    Mux3 Mux_for_PC (         
        .in0(if_pc_4),                             // 00: Chạy bình thường
        .in1(mem_pc_target),                       // 01: Nhảy JAL hoặc Branch
        .in2(mem_alu_result & 32'hFFFFFFFE),       // 10: Nhảy JALR (Ép bit cuối về 0 chuẩn RISC-V)
        .sel(pc_sel),                         // Cắm cờ 2-bit vào đây
        .out(if_pc_next)
    );
    // THANH GHI IF/ID (WIDTH = 96)
    Pipeline_Reg #(96) IF_ID_Reg (
        .clk(clk), .reset_n(reset_n), .clear(flush), .en(if_id_write),    
        .d({if_pc, if_pc_4, if_inst}),
        .q({id_pc, id_pc_4, id_inst})
    );

	 //ID
    Hazard_Detection_Unit HDU (
        .id_rs1(id_inst[19:15]),
        .id_rs2(id_inst[24:20]),
        .ex_rd(ex_rd),
        .ex_memread(ex_memread),
        .pc_write(pc_write),
        .if_id_write(if_id_write),
        .stall_sel(stall_sel)
    );

    Control_Unit my_Control_Unit (
        .opcode(id_inst[6:0]),  
        .ALUSrc(id_alusrc),
        .ALUOp(id_aluop),       
        .RegWrite(id_regwrite),
        .MemRead(id_memread),
        .MemWrite(id_memwrite),
        .MemtoReg(id_memtoreg),
        .Branch(id_branch),
        .Jump(id_jump),
        .Jalr(id_is_jalr)
    );

    RF my_RF (
        .clk(clk), .reset_n(reset_n),
        .regwrite(wb_regwrite),    
        .read_reg_num1(id_inst[19:15]), 
        .read_reg_num2(id_inst[24:20]), 
        .write_reg(wb_rd),         
        .write_data(wb_writedata), 
        .read_data1(id_readdata1),
        .read_data2(id_readdata2)
    );

    ImmGen my_ImmGen (
        .inst(id_inst),
        .Imm_Out(id_imm)
    );

    wire nop = stall_sel;
    wire regwrite_d = nop ? 1'b0 : id_regwrite;
    wire memtoreg_d = nop ? 1'b0 : id_memtoreg;
    wire memread_d  = nop ? 1'b0 : id_memread;
    wire memwrite_d = nop ? 1'b0 : id_memwrite;
    wire branch_d   = nop ? 1'b0 : id_branch;
    wire jump_d     = nop ? 1'b0 : id_jump;
    wire alusrc_d   = nop ? 1'b0 : id_alusrc;
    wire is_jalr_d  = nop ? 1'b0 : id_is_jalr;
    wire [1:0] aluop_d = nop ? 2'b00 : id_aluop;
    wire [1:0] sel_A_d    = nop ? 2'b00 : id_sel_A;

    Pipeline_Reg #(191) ID_EX_Reg (
        .clk(clk), .reset_n(reset_n), .clear(flush), .en(1'b1),
        .d({
            id_pc, id_pc_4, id_readdata1, id_readdata2, id_imm,
            id_inst[19:15], id_inst[24:20], id_inst[11:7], id_inst[14:12], id_inst[30],
            regwrite_d, memtoreg_d, memread_d, memwrite_d, branch_d, jump_d, alusrc_d, is_jalr_d, aluop_d, sel_A_d
        }),

        .q({
            ex_pc, ex_pc_4, ex_readdata1, ex_readdata2, ex_imm,
            ex_rs1, ex_rs2, ex_rd, ex_funct3, ex_bit30,
            ex_regwrite, ex_memtoreg, ex_memread, ex_memwrite, ex_branch, ex_jump, ex_alusrc, ex_is_jalr, ex_aluop, ex_sel_A
        })
    );
	 
	 //EX
    wire [1:0] forwardA, forwardB;

    Forwarding Forw_Unit (
        .ex_rs1(ex_rs1), .ex_rs2(ex_rs2),
        .mem_rd(mem_rd), .wb_rd(wb_rd),
        .mem_regwrite(mem_regwrite), .wb_regwrite(wb_regwrite),
        .forwardA(forwardA), .forwardB(forwardB)
    );

    wire [31:0] fw_in_a, fw_in_b;

    Mux3 Mux3_forA (
        .in0(ex_readdata1),
        .in1(wb_writedata),
        .in2(mem_alu_result),
        .sel(forwardA),
        .out(fw_in_a)
    );

    Mux3 Mux3_forB (
        .in0(ex_readdata2),
        .in1(wb_writedata),
        .in2(mem_alu_result),
        .sel(forwardB),
        .out(fw_in_b)
    ); 

    Mux3 Mux_for_A_Operand (
        .in0(fw_in_a),
        .in1(ex_pc),
		  .in2(32'b0),
        .sel(ex_sel_A),
        .out(ex_alu_input_a)
    );
        
    Mux Mux_for_B_Operand (
        .in0(fw_in_b),
        .in1(ex_imm),          
        .sel(ex_alusrc),
        .out(ex_alu_input_b)
    );

    ALU_Control my_ALU_Ctrl (
        .ALUOp(ex_aluop),
        .funct3(ex_funct3),
        .bit30(ex_bit30),
        .ALUCIn(ex_alu_ctrl)
    );

    ALU_32bit my_ALU (       
        .A(ex_alu_input_a),       
        .B(ex_alu_input_b),
        .ALU_Control(ex_alu_ctrl),
        .ALU_Result(ex_alu_result),
        .Zero(ex_zero_flag)
    );

    Branch Branch_Comp (
        .a(fw_in_a),          
        .b(fw_in_b),            
        .funct3(ex_funct3),     
        .branch_taken(ex_branch_taken) 
    );

    Adder Adder_for_Branch (
        .a(ex_pc),
        .b(ex_imm),
        .sum(ex_pc_target)
    );
	 
    Pipeline_Reg #(145) EX_MEM_Reg (
        .clk(clk), .reset_n(reset_n), .clear(flush), .en(1'b1),
        .d({
            ex_pc_target, ex_pc_4, ex_alu_result, fw_in_b, ex_zero_flag, ex_rd,
            ex_regwrite, ex_memtoreg, ex_memread, ex_memwrite, ex_branch, ex_jump, ex_is_jalr, ex_branch_taken, ex_funct3
        }),
        .q({
            mem_pc_target, mem_pc_4, mem_alu_result, mem_readdata2, mem_zero_flag, mem_rd,
            mem_regwrite, mem_memtoreg, mem_memread, mem_memwrite, mem_branch, mem_jump, mem_is_jalr, mem_branch_taken, mem_funct3
        })
    );

    //MEM

    assign pc_sel = (mem_jump == 1'b1 && mem_is_jalr == 1'b1) ? 2'b10 : ((mem_branch & mem_branch_taken) | mem_jump) ? 2'b01 : 2'b00;
    assign flush = (pc_sel != 2'b00);

    Control_Memory my_MemCtrl (
        .mem_alu_result(mem_alu_result),
        .mem_readdata2(mem_readdata2),
        .mem_readdata_dmem(mem_readdata_dmem), 
        .mem_funct3(mem_funct3),
        .mem_memwrite(mem_memwrite),
        .mem_memread(mem_memread),
        
        .write_pos(mem_write_pos),          
        .store_data(mem_store_data),         
        .load_data(mem_load_data)            
    );

    assign dmem_memread    = mem_memread;
    assign dmem_memwrite   = mem_memwrite;
    assign dmem_write_pos = mem_write_pos;
    assign dmem_addr       = mem_alu_result;
    assign dmem_write_data = mem_store_data;
    assign mem_readdata_dmem = dmem_read_data;

    Pipeline_Reg #(104) MEM_WB_Reg (
        .clk(clk), .reset_n(reset_n), .clear(1'b0), .en(1'b1),
        .d({
            mem_load_data, mem_alu_result, mem_pc_4, mem_rd,
            mem_regwrite, mem_memtoreg, mem_jump
        }),
        .q({
            wb_readdata_dmem, wb_alu_result, wb_pc_4, wb_rd,
            wb_regwrite, wb_memtoreg, wb_jump
        })
    );

    //WB
    Mux Mux_MemtoReg (
        .in0(wb_alu_result), 
        .in1(wb_readdata_dmem), 
        .sel(wb_memtoreg), 
        .out(wb_write_data_combined)  
    );

    Mux MUX_for_JAL_WriteData (
        .in0(wb_write_data_combined),
        .in1(wb_pc_4),                    
        .sel(wb_jump),                    
        .out(wb_writedata)              
    );

endmodule