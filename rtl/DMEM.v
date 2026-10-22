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

    wire [31:0] offset_addr = Address - 32'h00400000;

    always @(posedge clock) begin
        if (MemWrite) begin
            if(Write_Pos[0]) dmem[offset_addr[13:2]][7:0]   <= Write_Data[7:0];
            if(Write_Pos[1]) dmem[offset_addr[13:2]][15:8]  <= Write_Data[15:8];
            if(Write_Pos[2]) dmem[offset_addr[13:2]][23:16] <= Write_Data[23:16];
            if(Write_Pos[3]) dmem[offset_addr[13:2]][31:24] <= Write_Data[31:24];
        end
    end
    
    assign Read_Data = (MemRead) ? dmem[offset_addr[13:2]] : 32'h0;

endmodule