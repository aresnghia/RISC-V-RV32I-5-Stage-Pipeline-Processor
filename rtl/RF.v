module RF(
    input clk,
    input reset_n,
    input regwrite,
    input  [4:0] read_reg_num1,
    input  [4:0] read_reg_num2,
    input  [4:0] write_reg,
    input  [31:0] write_data,
    output [31:0] read_data1,
    output [31:0] read_data2
);

    reg [31:0] reg_memory [31:0];
    integer i;

    always @(negedge clk or negedge reset_n) begin
        if (!reset_n) begin
            for (i = 0; i < 32; i = i + 1)
                reg_memory[i] <= 32'h0;
            reg_memory[2] <= 32'h7ffffff0;
            reg_memory[3] <= 32'h10008000;
        end
        else begin
            if (regwrite && (write_reg != 5'd0))
                reg_memory[write_reg] <= write_data;
        end
    end

    assign read_data1 = (read_reg_num1 == 5'd0) ? 32'h0 : reg_memory[read_reg_num1];
    assign read_data2 = (read_reg_num2 == 5'd0) ? 32'h0 : reg_memory[read_reg_num2];

endmodule