module Branch (
    input [31:0] a,        
    input [31:0] b,        
    input [2:0]  funct3,   
    output reg   branch_taken
);

    always @(*) begin
        case(funct3)
            3'b000 : branch_taken = (a == b);                                // BEQ  (Bằng nhau)
            3'b001 : branch_taken = (a != b);                                // BNE  (Khác nhau)
            3'b100 : branch_taken = ($signed(a) < $signed(b));               // BLT  (Nhỏ hơn - Có dấu)
            3'b101 : branch_taken = ($signed(a) >= $signed(b));              // BGE  (Lớn hơn hoặc bằng - Có dấu)
            3'b110 : branch_taken = (a < b);                                 // BLTU (Nhỏ hơn - Không dấu)
            3'b111 : branch_taken = (a >= b);                                // BGEU (Lớn hơn hoặc bằng - Không dấu)
            default: branch_taken = 1'b0;
        endcase
    end

endmodule