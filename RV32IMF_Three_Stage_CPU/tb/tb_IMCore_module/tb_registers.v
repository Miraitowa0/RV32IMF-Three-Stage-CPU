`timescale 1ns/1ps

module tb_registers();

	reg clk;
	reg [4:0]Rs1;
	reg [4:0]Rs2;
	reg [4:0]Rd;
	reg W_en;
	reg [31:0]Wr_Data;
	wire [31:0]Rs1_Data;
	wire [31:0]Rs2_Data;
	
	registers uut(
		.clk(clk),
		.Rs1(Rs1),
		.Rs2(Rs2),
		.Rd(Rd),
		.W_en(W_en),
		.Wr_Data(Wr_Data),
		.Rs1_Data(Rs1_Data),
		.Rs2_Data(Rs2_Data)
	);
	
	 initial begin
		 clk = 1'b0;
		 forever #5 clk = ~clk;
	 end
	 
	 initial begin
      W_en = 0;
		Rs1 = 5'd1;
		Rs2 = 5'd0;
		#20;
		$display("Rs1=0x01,Rs1_Data=%h ; Rs2=0x00,Rs2_Data=%h ",Rs1_Data ,Rs2_Data); // 预期：aabbccdd  00000000
		
		Rs1 = 5'd2;
		Rs2 = 5'd3;
		#20;
		$display("Rs1=0x02,Rs1_Data=%h ; Rs2=0x03,Rs2_Data=%h ",Rs1_Data ,Rs2_Data); // 预期：00112233 11335577
		
		Rs1 = 5'd4;
		Rs2 = 5'd5;
		#20;
		$display("Rs1=0x04,Rs1_Data=%h ; Rs2=0x05,Rs2_Data=%h ",Rs1_Data ,Rs2_Data); // 预期：ffff0000 f0f0f0f0
		
		W_en = 1;
		Rs1 = 5'd0;
		Rs2 = 5'd0;
		#5;
		
		Rd = 5'd1;
		Wr_Data = 32'h10101110;
		#5;
		Rs1 = 5'd1;
		#5;
		
		Rd = 5'd2;
		Wr_Data = 32'h11111111;
		#5;
		Rs1 = 5'd2;
		#5;
		
		Rd = 5'd3;
		Wr_Data = 32'hffffffff;
		#5;
		Rs1 = 5'd3;
		#5;
		
		Rd = 5'd4;
		Wr_Data = 32'h0000ffff;
		#5;
		Rs1 = 5'd4;
		#5;
		
		Rs1 = 5'd1;
		Rs2 = 5'd2;
		#20;
		$display("Rs1=0x01,Rs1_Data=%h ; Rs2=0x02,Rs2_Data=%h ",Rs1_Data ,Rs2_Data); // 预期：10101110 11111111
	
		Rs1 = 5'd3;
		Rs2 = 5'd4;
		#20;
		$display("Rs1=0x03,Rs1_Data=%h ; Rs2=0x04,Rs2_Data=%h ",Rs1_Data ,Rs2_Data); // 预期：ffffffff 0000ffff
		
		#20
		$finish;
    end
	 

endmodule
