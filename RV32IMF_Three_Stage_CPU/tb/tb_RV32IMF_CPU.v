`timescale 1ns/1ps
module tb_RV32IMF_CPU();
	reg clk;
	reg rst;
	wire [7:0]rom_addr;
	
	RV32IMF_CPU  uut(
		.clk(clk),
		.rst(rst),
		.rom_addr(rom_addr)
	);
	
	initial begin
		clk = 1'b0;
		forever #5 clk = ~clk;
	end
	
	initial begin
		$display("Start simulation...");
		$monitor("time=%0t, rom_addr=%h", $time, rom_addr);
		rst = 1'b0;
		#25;
		@(posedge clk); 
		rst = 1'b1;
		
		#1000;
		
		$finish;
	end
endmodule
