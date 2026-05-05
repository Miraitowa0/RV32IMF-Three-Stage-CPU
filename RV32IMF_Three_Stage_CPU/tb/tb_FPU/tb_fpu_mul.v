`timescale 1ns / 1ps

module tb_fpu_mul;

    reg  [31:0] fs1_data;
    reg  [31:0] fs2_data;
    reg  [2:0]  rm;
    wire [31:0] fd_data;
    wire [4:0]  fflags;

    integer pass_cnt = 0, fail_cnt = 0, total_cnt = 0;

    fpu_mul u_fpu_mul (
        .fs1_data(fs1_data), 
		  .fs2_data(fs2_data), 
        .rm(rm), 
		  .fd_data(fd_data),
		  .fflags(fflags)
    );
	 

    task test_case(
        input [31:0] t_fs1, 
		  input [31:0] t_fs2, 
        input [31:0] exp_fd,
		  input [255:0] t_name
    );
        begin
            total_cnt = total_cnt + 1;
            fs1_data = t_fs1; 
				fs2_data = t_fs2; 
				rm = 3'b000; // RNE 模式
            #10;
            if (fd_data === exp_fd) begin
                pass_cnt = pass_cnt + 1;
                $display("[PASS] %s", t_name);
            end else begin
                fail_cnt = fail_cnt + 1;
                $display("[FAIL] %s | fs1=%h, fs2=%h | Exp=%h, Got=%h", 
                          t_name, t_fs1, t_fs2, exp_fd, fd_data);
            end
        end
    endtask

    initial begin
        $display("==================================================");
        $display(" Start test: fpu_mul (Floating-Point Multiplier)");
        $display("==================================================");

        // --- 1. 基础乘法测试 ---
        test_case(32'h3F800000, 32'h40000000, 32'h40000000, "1.0  * 2.0  = 2.0");
        test_case(32'h40000000, 32'h40400000, 32'h40C00000, "2.0  * 3.0  = 6.0");
        test_case(32'hBFC00000, 32'h40200000, 32'hC0700000, "-1.5 * 2.5  = -3.75");
        
        // --- 2. 符号测试 ---
        test_case(32'hBF800000, 32'hBF800000, 32'h3F800000, "-1.0 * -1.0 = +1.0");
        test_case(32'h80000000, 32'h80000000, 32'h00000000, "-0.0 * -0.0 = +0.0");

        // --- 3. 边界与异常情况测试 ---
        // 任何数乘以 ±0
        test_case(32'h00000000, 32'h40000000, 32'h00000000, "0.0  * 2.0  = 0.0");
        // 任何非零数乘以 ±Inf
        test_case(32'h7F800000, 32'hC0000000, 32'hFF800000, "+Inf * -2.0 = -Inf");
        // [极度关键] 0.0 * Inf 触发 Invalid Operation 变成 NaN
        test_case(32'h00000000, 32'h7F800000, 32'h7FC00000, "0.0  * +Inf = NaN (Invalid Op)");
        // 包含 NaN 的运算
        test_case(32'h7FC00000, 32'h40000000, 32'h7FC00000, "NaN  * 2.0  = NaN");

        // --- 4. 溢出测试 ---
        // 极大数相乘导致上溢出变成 Inf
        test_case(32'h7E000000, 32'h7E000000, 32'h7F800000, "Overflow    -> +Inf");
        // 极小数相乘导致下溢出变成 0
        test_case(32'h01000000, 32'h01000000, 32'h00000000, "Underflow   -> 0.0");

        $display("==================================================");
        $display(" Test Summary: Passed=%0d, Failed=%0d", pass_cnt, fail_cnt);
        if (fail_cnt == 0) $display(" PERFECT FMUL MATCH!");
        $display("==================================================");
        $finish;
    end
endmodule
