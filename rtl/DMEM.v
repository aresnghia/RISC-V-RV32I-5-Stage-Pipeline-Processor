module DMEM (
    input clock,
    input MemRead,
    input MemWrite,
    input  [3:0]  Write_Pos,
    input  [31:0] Address,
    input  [31:0] Write_Data,
    output [31:0] Read_Data
);

    reg [31:0] dmem [0:4095]; 
    integer i;
    initial begin
        for (i = 0; i < 4096; i = i + 1) begin
            dmem[i] = 32'h0;    
        end
    end

    // Cắt bit trực tiếp Address[13:2] (12-bit cho 4096 từ = 16KB)
    // Tự động map 0x80000000 -> index 0 mà không tốn bộ trừ logic
    wire [11:0] dmem_idx = Address[13:2];

    always @(posedge clock) begin
        if (MemWrite) begin
            if(Write_Pos[0]) dmem[dmem_idx][7:0]   <= Write_Data[7:0];
            if(Write_Pos[1]) dmem[dmem_idx][15:8]  <= Write_Data[15:8];
            if(Write_Pos[2]) dmem[dmem_idx][23:16] <= Write_Data[23:16];
            if(Write_Pos[3]) dmem[dmem_idx][31:24] <= Write_Data[31:24];
        end
    end
    
    assign Read_Data = (MemRead) ? dmem[dmem_idx] : 32'h0;

endmodule