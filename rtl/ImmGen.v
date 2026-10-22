module ImmGen (
    input  [31:0] inst,         
    output reg [31:0] Imm_Out     
);
    wire [6:0] opcode = inst[6:0];
    
    wire [31:0] imm_I = {{20{inst[31]}}, inst[31:20]};
    wire [31:0] imm_S = {{20{inst[31]}}, inst[31:25], inst[11:7]};
    wire [31:0] imm_B = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
    wire [31:0] imm_U = {inst[31:12], 12'b0};
    wire [31:0] imm_J = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};

    always @(*) begin
        case (opcode)
            7'b0000011: Imm_Out = imm_I; // (I-Type)
            7'b0010011: Imm_Out = imm_I; // (I-Type)
            7'b0100011: Imm_Out = imm_S; // (S-Type)
            7'b1100011: Imm_Out = imm_B; // (B-Type)
            7'b0110111: Imm_Out = imm_U; // (U-Type)
            7'b0010111: Imm_Out = imm_U; //  auipc 
            7'b1101111: Imm_Out = imm_J; // (J-Type)
            7'b1100111: Imm_Out = imm_I; // JALR (I-Type)
            default:    Imm_Out = 32'b0; //
        endcase
    end
endmodule