`timescale 1ns / 1ps

module tb_alu;

	// 输入信号定义
	reg [31:0] ALU_Data1;
	reg [31:0] ALU_Data2;
	reg [4:0]  ALU_Ctrl;

	// 输出信号定义
	wire ALU_Zero;
	wire ALU_Overflow;
	wire [31:0] ALU_result;

	// 例化被测ALU模块
	alu uut (
		 .ALU_Data1(ALU_Data1),
		 .ALU_Data2(ALU_Data2),
		 .ALU_Ctrl(ALU_Ctrl),
		 .ALU_Zero(ALU_Zero),
		 .ALU_Overflow(ALU_Overflow),
		 .ALU_result(ALU_result)
	);

	// 时钟信号（组合逻辑ALU可不依赖时钟，仅用于仿真节奏控制）
	reg clk;
	initial begin
		 clk = 1'b0;
		 forever #5 clk = ~clk;
	end

	// 测试用例执行任务
	task test_alu;
		 input [31:0] data1;
		 input [31:0] data2;
		 input [4:0]  ctrl;
		 input [31:0] exp_result;  // 预期结果
		 input        exp_zero;     // 预期Zero标志
		 input        exp_overflow;// 预期Overflow标志
		 begin
			  ALU_Data1 = data1;
			  ALU_Data2 = data2;
			  ALU_Ctrl  = ctrl;
			  @(posedge clk);  // 等待时钟沿，确保信号稳定
			  
			  // 打印测试结果
			  $display("=====================================");
			  $display("Test insturction: ALU_Ctrl = %b", ctrl);
			  $display("input1: 0x%08X, input2: 0x%08X", data1, data2);
			  $display("Realistic result: 0x%08X, Expect result: 0x%08X", ALU_result, exp_result);
			  $display("Realistic Zero: %b, Expect Zero: %b", ALU_Zero, exp_zero);
			  $display("Realistic Overflow: %b, Expect Overflow: %b", ALU_Overflow, exp_overflow);
			  
			  // 结果校验
			  if (ALU_result != exp_result || ALU_Zero != exp_zero || ALU_Overflow != exp_overflow) begin
					$display("Test failed!");
			  end else begin
					$display("Test passed!");
			  end
			  $display("=====================================\n");
		 end
	endtask

	// 主测试流程
	initial begin
		 // 初始化信号
		 ALU_Data1 = 32'd0;
		 ALU_Data2 = 32'd0;
		 ALU_Ctrl  = 5'd0;
		 #10;  // 初始延迟
		  $display("!!!!!!!!!!!!ADD and SUB arithmatic!!!!!!!!!!!!!!!!!!");
		 // ---------------------- 1. 加减运算测试 ----------------------
		 // 1.1 ADD 正常（5 + 3 = 8）
		 test_alu(32'd5, 32'd3, 5'b00000, 32'd8, 1'b0, 1'b0);
		 // 1.2 ADD 溢出（0x7FFFFFFF + 1 = 0x80000000，溢出）
		 test_alu(32'h7FFFFFFF, 32'd1, 5'b00000, 32'h80000000, 1'b0, 1'b1);
		 // 1.3 SUB 正常（10 - 4 = 6）
		 test_alu(32'd10, 32'd4, 5'b00011, 32'd6, 1'b0, 1'b0);
		 // 1.4 SUB 溢出（0x80000000 - 1 = 0x7FFFFFFF，溢出）
		 test_alu(32'h80000000, 32'd1, 5'b00011, 32'h7FFFFFFF, 1'b0, 1'b1);
		 // 1.5 SUB 结果为0（8 - 8 = 0，Zero=1）
		 test_alu(32'd8, 32'd8, 5'b00011, 32'd0, 1'b1, 1'b0);

		  $display("!!!!!!!!!!!!Logic arithmatic!!!!!!!!!!!!!!!!!!");
		 // ---------------------- 2. 逻辑运算测试 ----------------------
		 // 2.1 AND（0xFFFF0000 & 0x00FFFF00 = 0x00FF0000）
		 test_alu(32'hFFFF0000, 32'h00FFFF00, 5'b00100, 32'h00FF0000, 1'b0, 1'b0);
		 // 2.2 OR（0xFFFF0000 | 0x00FFFF00 = 0xFFFFFF00）
		 test_alu(32'hFFFF0000, 32'h00FFFF00, 5'b00101, 32'hFFFFFF00, 1'b0, 1'b0);
		 // 2.3 XOR（0xFFFF0000 ^ 0x00FFFF00 = 0xFF00FF00）
		 test_alu(32'hFFFF0000, 32'h00FFFF00, 5'b00110, 32'hFF00FF00, 1'b0, 1'b0);
		 // 2.4 NOR（~(0xFFFF0000 | 0x00FFFF00) = 0x000000FF）
		 test_alu(32'hFFFF0000, 32'h00FFFF00, 5'b00111, 32'h000000FF, 1'b0, 1'b0);

		  $display("!!!!!!!!!!!!Set wei arithmatic!!!!!!!!!!!!!!!!!!");
		 // ---------------------- 3. 置位运算测试 ----------------------
		 // 3.1 SLTU（无符号：5 < 8 → 1）
		 test_alu(32'd5, 32'd8, 5'b01000, 32'd1, 1'b0, 1'b0);
		 // 3.2 SLTU（无符号：8 < 5 → 0）
		 test_alu(32'd8, 32'd5, 5'b01000, 32'd0, 1'b0, 1'b0);
		 // 3.3 SLT（有符号：-1 < 2 → 1，-1=0xFFFFFFFF，2=0x00000002）
		 test_alu(32'hFFFFFFFF, 32'd2, 5'b01001, 32'd1, 1'b0, 1'b0);
		 // 3.4 SLT（有符号：2 < -1 → 0）
		 test_alu(32'd2, 32'hFFFFFFFF, 5'b01001, 32'd0, 1'b0, 1'b0);

		  $display("!!!!!!!!!!!!Move wei arithmatic!!!!!!!!!!!!!!!!!!");
		 // ---------------------- 4. 移位运算测试 ----------------------
		 // 4.1 SLL（0x00000001 << 5 = 0x00000020）
		 test_alu(32'd1, 32'd5, 5'b01100, 32'h00000020, 1'b0, 1'b0);
		 // 4.2 SRL（无符号右移：0x80000000 >> 1 = 0x40000000）
		 test_alu(32'h80000000, 32'd1, 5'b01101, 32'h40000000, 1'b0, 1'b0);
		 // 4.3 SRA（有符号右移：0x80000000 >> 1 = 0xC0000000）
		 test_alu(32'h80000000, 32'd1, 5'b01110, 32'hC0000000, 1'b0, 1'b0);

		  $display("!!!!!!!!!!!!Multiply and Div arithmatic!!!!!!!!!!!!!!!!!!");
		 // ---------------------- 5. M拓展乘除运算测试 ----------------------
		 // 5.1 MUL（3 * 5 = 15）
		 test_alu(32'd3, 32'd5, 5'b10000, 32'd15, 1'b0, 1'b0);
		 
		 // 5.2 MULH（有符号：-2 * 3 = -6 → 64位：0xFFFFFFFF_FFFFFFFA → 高32位0xFFFFFFFA）
		 test_alu(32'hFFFFFFFE, 32'd3, 5'b10001, 32'hFFFFFFFF, 1'b0, 1'b0);
		 
		 $display("Something is wrong here ,please don't use signed * unsigned ");
		 // 5.3 MULHSU（有符号*无符号：-2 * 3 = -6 → 高32位0xFFFFFFFF）
		 test_alu(32'hFFFFFFFE, 32'd3, 5'b10010, 32'hFFFFFFFF, 1'b0, 1'b0);
		 
		 // 5.4 MULHU（无符号：0xFFFFFFFE * 3 = 0x2FFFFFFF6 → 高32位0x00000002）
		 test_alu(32'hFFFFFFFE, 32'd3, 5'b10011, 32'h00000002, 1'b0, 1'b0);
		 
		 // 5.5 DIV（有符号：10 / 3 = 3）
		 test_alu(32'd10, 32'd3, 5'b10100, 32'd3, 1'b0, 1'b0);
		 
		 // 5.6 DIV（除数为0 → 返回0xFFFFFFFF）
		 test_alu(32'd10, 32'd0, 5'b10100, 32'hFFFFFFFF, 1'b0, 1'b0);
		 
		 // 5.7 DIVU（无符号：10 / 3 = 3）
		 test_alu(32'd10, 32'd3, 5'b10101, 32'd3, 1'b0, 1'b0);
		 
		 // 5.8 DIVU（除数为0 → 返回0xFFFFFFFF）
		 test_alu(32'd10, 32'd0, 5'b10101, 32'hFFFFFFFF, 1'b0, 1'b0);
		 
		 // 5.9 REM（有符号：10 % 3 = 1）
		 test_alu(32'd10, 32'd3, 5'b10110, 32'd1, 1'b0, 1'b0);
		 
		 // 5.10 REM（除数为0 → 返回被除数10）
		 test_alu(32'd10, 32'd0, 5'b10110, 32'd10, 1'b0, 1'b0);
		 
		 // 5.11 REMU（无符号：10 % 3 = 1）
		 test_alu(32'd10, 32'd3, 5'b10111, 32'd1, 1'b0, 1'b0);
		 
		 // 5.12 REMU（除数为0 → 返回被除数10）
		 test_alu(32'd10, 32'd0, 5'b10111, 32'd10, 1'b0, 1'b0);
		 
		 // 5.13 DIV溢出（0x80000000 / -1 = 0x80000000）
		 test_alu(32'h80000000, 32'hFFFFFFFF, 5'b10100, 32'h80000000, 1'b0, 1'b0);
		 
		 // 5.14 REM溢出（0x80000000 % -1 = 0）
		 test_alu(32'h80000000, 32'hFFFFFFFF, 5'b10110, 32'd0, 1'b0, 1'b0);

		 // 测试结束
		 #10;
		 $display("All Test have finished!");
		 $finish;
	end

endmodule

