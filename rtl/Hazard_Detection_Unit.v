module Hazard_Detection_Unit (
    input [4:0] id_rs1, id_rs2,
    input [4:0] ex_rd,
    input ex_memread,
    output reg pc_write,
    output reg if_id_write,
    output reg stall_sel
);

    always @(*) begin
        pc_write = 1'b1;
        if_id_write = 1'b1;
        stall_sel = 1'b0;

        if (ex_memread && ((ex_rd == id_rs1) || (ex_rd == id_rs2)) && (ex_rd != 5'b0)) begin
            pc_write = 1'b0;
            if_id_write = 1'b0;
            stall_sel = 1'b1;    
        end
    end
endmodule