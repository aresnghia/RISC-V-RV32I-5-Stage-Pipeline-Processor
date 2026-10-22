module Pipeline_Reg #(parameter WIDTH = 32) (
    input clk,
    input reset_n,
    input clear,       
    input en,          
    input [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);

always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        q <= {WIDTH{1'b0}}; 
    end else if (clear) begin
        q <= {WIDTH{1'b0}}; 
    end else if (en) begin
        q <= d;           
    end
end
endmodule