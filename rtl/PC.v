module PC (
    input clk,
    input reset_n,            // Đổi tên thành reset_n
    input PC_Write,           
    input [31:0] PC_in,       
    output reg [31:0] PC_out  
);
    // Bắt cạnh xuống (negedge) của reset_n
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin   // Nếu reset_n kéo xuống 0 thì khởi tạo PC về 0x80000000
            PC_out <= 32'h80000000;
        end 
        else if (PC_Write) begin
            PC_out <= PC_in;
        end
    end
endmodule