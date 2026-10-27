`timescale 1ns / 1ps

module tb_CPU();

    reg clk;
    reg reset_n;
    
    wire [31:0] ipc_out;
    wire [31:0] ialu_result;

    wire [31:0] imem_addr, imem_inst;
    wire        dmem_memread, dmem_memwrite;
    wire [3:0]  dmem_write_pos;
    wire [31:0] dmem_addr, dmem_write_data, dmem_read_data;

    // Lõi CPU
    RISC_V32I uut (
        .clk(clk), .reset_n(reset_n),
        .ipc_out(ipc_out), .ialu_result(ialu_result),
        
        // Cắm dây ra ngoài
        .imem_addr(imem_addr), .imem_inst(imem_inst),
        .dmem_memread(dmem_memread), .dmem_memwrite(dmem_memwrite),
        .dmem_write_pos(dmem_write_pos), .dmem_addr(dmem_addr),
        .dmem_write_data(dmem_write_data), .dmem_read_data(dmem_read_data)
    );

    // BỘ NHỚ LỆNH
    IMEM my_IMEM (
        .pc(imem_addr), 
        .inst(imem_inst)
    );

    // BỘ NHỚ DATA
    DMEM my_DMEM (
        .clock(clk),
        .MemRead(dmem_memread), .MemWrite(dmem_memwrite),
        .Write_Pos(dmem_write_pos), 
        .Address(dmem_addr), .Write_Data(dmem_write_data),
        .Read_Data(dmem_read_data)
    );
    
    always #5 clk = ~clk;
    integer file;
    integer i;

    initial begin
        $readmemb("tests/imem.bin", my_IMEM.imem);
        $readmemb("tests/dmem.bin", my_DMEM.dmem);
        clk = 0;
        reset_n = 0;
        #7;         
        reset_n = 1;
        // Khởi tạo sp = 0x7ffffff0, gp = 0x10008000
        uut.my_RF.reg_memory[2] = 32'h7ffffff0;
        uut.my_RF.reg_memory[3] = 32'h10008000; 

        #500000;
        
        // Dump registers
        file = $fopen("reg.txt", "w");
        if (file) begin
            for (i = 0; i < 32; i = i + 1) begin
                $fdisplay(file, "x%0d 0x%08h", i, uut.my_RF.reg_memory[i]);
            end
            $fclose(file);
        end
        // Dump memory
        file = $fopen("mem.txt", "w");
        if (file) begin
            // Dump vùng data (0x80001000+)
            for (i = 32'h400; i < 4096; i = i + 1) begin
                if (my_DMEM.dmem[i] != 32'h0) begin
                    $fdisplay(file, "mem[0x%08h] 0x%08h", 32'h80000000 + i*4, my_DMEM.dmem[i]);
                end
            end

            $fclose(file);
        end
        $finish; 
    end

endmodule