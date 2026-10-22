module ALU_32bit (
    input  [31:0] A,            
    input  [31:0] B,            
    input  [3:0]  ALU_Control,  
    
    output reg [31:0] ALU_Result, 
    output Zero          
);

    localparam OP_AND  = 4'b0000,
               OP_OR   = 4'b0001,
               OP_ADD  = 4'b0010,
               OP_SUB  = 4'b0110,
               OP_XOR  = 4'b1101,
               OP_SLL  = 4'b0011,
               OP_SRL  = 4'b0100,
               OP_SRA  = 4'b0101,
               OP_SLT  = 4'b0111,
               OP_SLTU = 4'b1000;

    always @(*) begin
        case (ALU_Control)
            OP_AND:  ALU_Result = A & B;
            OP_OR:   ALU_Result = A | B;
            OP_XOR:  ALU_Result = A ^ B;
            
            OP_ADD:  ALU_Result = A + B;
            OP_SUB:  ALU_Result = A - B;
            
            OP_SLL:  ALU_Result = A << B[4:0]; 
            OP_SRL:  ALU_Result = A >> B[4:0];
            OP_SRA:  ALU_Result = $signed(A) >>> B[4:0]; 
            
            OP_SLT:  ALU_Result = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0;
            OP_SLTU: ALU_Result = (A < B) ? 32'd1 : 32'd0;
            
            default: ALU_Result = 32'b0; 
        endcase
    end

    assign Zero = (ALU_Result == 32'b0);

endmodule