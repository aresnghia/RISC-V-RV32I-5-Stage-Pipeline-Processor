module IMEM (
    input  [31:0] pc,         
    output [31:0] inst 
);
    reg [31:0] imem [0:4095]; 
    wire [31:0] offset_pc = pc - 32'h00400000; 
    assign inst = imem[offset_pc[31:2]]; 

endmodule