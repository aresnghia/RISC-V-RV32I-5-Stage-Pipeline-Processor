module Control_Memory (
    input [31:0] mem_alu_result,
    input [31:0] mem_readdata2,
    input [31:0] mem_readdata_dmem,
    input [2:0]  mem_funct3,
    input        mem_memwrite,
    input        mem_memread,

    output reg [3:0]  write_pos,
    output reg [31:0] store_data,
    output reg [31:0] load_data
);

    // [TÓM TẮT LOGIC]: Khối Store (write_pos và store_data) được giữ nguyên vì đã hoàn hảo.
    always @(*) begin
        write_pos = 4'b0000;
        store_data = mem_readdata2;
        if (mem_memwrite) begin
            case(mem_funct3)
                3'b000: begin
                    store_data = {4{mem_readdata2[7:0]}};
                    case(mem_alu_result[1:0])
                        2'b00: write_pos = 4'b0001;
                        2'b01: write_pos = 4'b0010;
                        2'b10: write_pos = 4'b0100;
                        2'b11: write_pos = 4'b1000;
                    endcase
                end
                3'b001: begin
                    store_data = {2{mem_readdata2[15:0]}};
                    case(mem_alu_result[1])
                        1'b0: write_pos = 4'b0011;
                        1'b1: write_pos = 4'b1100;
                    endcase
                end
                3'b010: begin
                    store_data = mem_readdata2;
                    write_pos = 4'b1111;
                end
                default: write_pos = 4'b0000;
            endcase
        end
    end

    reg [7:0]  load_byte;
    reg [15:0] load_half;

    always @(*) begin
        case(mem_alu_result[1:0])
            2'b00: load_byte = mem_readdata_dmem[7:0];
            2'b01: load_byte = mem_readdata_dmem[15:8];
            2'b10: load_byte = mem_readdata_dmem[23:16];
            2'b11: load_byte = mem_readdata_dmem[31:24];
        endcase

        case(mem_alu_result[1])
            1'b0: load_half = mem_readdata_dmem[15:0];
            1'b1: load_half = mem_readdata_dmem[31:16];
        endcase
        
        load_data = mem_readdata_dmem;

        if(mem_memread) begin
            case(mem_funct3)
                3'b000: load_data = {{24{load_byte[7]}}, load_byte};
                3'b001: load_data = {{16{load_half[15]}}, load_half}; 
                3'b010: load_data = mem_readdata_dmem;
                3'b100: load_data = {24'b0, load_byte}; 
                3'b101: load_data = {16'b0, load_half};
            endcase
        end
    end
endmodule