module IMEM (
    input  [31:0] pc,         
    output [31:0] inst 
);
    reg [31:0] imem [0:4095]; 
    // Cắt bit trực tiếp pc[13:2] (12-bit cho 4096 từ = 16KB)
    // Tự động map 0x80000000 -> index 0 mà không tốn bộ trừ logic
    assign inst = imem[pc[13:2]]; 

endmodule