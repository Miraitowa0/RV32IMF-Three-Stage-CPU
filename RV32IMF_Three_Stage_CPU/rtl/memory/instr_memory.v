module instr_memory(
	addr,
	instr
);
	input [7:0]addr;
	output [31:0]instr;
	
	reg[31:0] rom[255:0];
	
    //rom进行初始化
    initial begin
        $readmemh("E:/RISCV_Prj/RV32IMF_CPU/rom_binary_file.txt", rom,0,255); //b 二进制
        //$readmemh("rom_hex_file.txt", rom);  h 十六进制
		 
		  // 调试语句：在Modelsim控制台打印rom前3个地址的数据，验证是否读取成功
        $display("rom[0] = %h", rom[0]);
        $display("rom[1] = %h", rom[1]);
        $display("rom[2] = %h", rom[2]);
    end
	
    assign instr = rom[addr];

endmodule
