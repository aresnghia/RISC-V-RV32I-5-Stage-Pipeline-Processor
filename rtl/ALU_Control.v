module ALU_Control (
    input [1:0] ALUOp,
    input [2:0] funct3,
    input bit30,       
    output reg [3:0] ALUCIn
);

always @(*) begin
    case(ALUOp)

        2'b00: ALUCIn = 4'b0010;
        2'b01: ALUCIn = 4'b0110;
        2'b10: begin
            case(funct3)
                3'b000: begin
                    if (!bit30) ALUCIn = 4'b0010; // ADD
                    else        ALUCIn = 4'b0110; // SUB
                end
                3'b111: ALUCIn = 4'b0000;         // AND
                3'b110: ALUCIn = 4'b0001;         // OR
                3'b100: ALUCIn = 4'b1101;         // XOR
                3'b001: ALUCIn = 4'b0011;         // SLL
                3'b101: begin
                    if (!bit30) ALUCIn = 4'b0100; // SRL
                    else        ALUCIn = 4'b0101; // SRA
                end             
                3'b010: ALUCIn = 4'b0111;         // SLT
                3'b011: ALUCIn = 4'b1000;         // SLTU
                default: ALUCIn = 4'b0000;
            endcase
        end
        2'b11: begin
            case(funct3)
                3'b000: ALUCIn = 4'b0010;         
                3'b111: ALUCIn = 4'b0000;         // ANDI
                3'b110: ALUCIn = 4'b0001;         // ORI
                3'b100: ALUCIn = 4'b1101;         // XORI              
                3'b001: ALUCIn = 4'b0011;         // SLLI
                3'b101: begin
                    if (!bit30) ALUCIn = 4'b0100; // SRLI
                    else        ALUCIn = 4'b0101; // SRAI
                end               
                3'b010: ALUCIn = 4'b0111;         // SLTI
                3'b011: ALUCIn = 4'b1000;         // SLTIU
                default: ALUCIn = 4'b0000;
            endcase
        end

        default: ALUCIn = 4'b0000;
    endcase
end

endmodule