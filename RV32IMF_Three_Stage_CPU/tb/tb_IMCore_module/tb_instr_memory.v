`timescale 1ns/1ps  

module tb_instr_memory;

	reg [7:0]addr;
	wire [31:0]instr;
	
	instr_memory uut(
		.addr(addr),
		.instr(instr)
	);
	
	initial begin
        $dumpfile("tb_instr_memory.vcd");  // 生成vcd波形文件，可在Modelsim等工具中打开
        $dumpvars(0, tb_instr_memory);     // 捕捉整个测试模块的所有变量波形
    end
	
	initial begin
        addr = 8'd0;
        #20;
        $display("addr=0, instr=%b", instr);
        addr = 8'd1;
        #20;
        $display("addr=1, instr=%b", instr);
        addr = 8'd2;
        #20;
        $display("addr=2, instr=%b", instr);
        addr = 8'd0;
        #20;
        $display("addr=0, instr=%b", instr);
        #20;
        $finish;
    end

endmodule
