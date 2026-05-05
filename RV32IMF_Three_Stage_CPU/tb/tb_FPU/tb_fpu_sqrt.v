`timescale 1ns / 1ps

module tb_fpu_sqrt;

    reg  [31:0] fs1_data;
    reg  [2:0]  rm;
    wire [31:0] fd_data;
    wire [4:0]  fflags;

    integer pass_cnt = 0, fail_cnt = 0, total_cnt = 0;

    fpu_sqrt u_fpu_sqrt (
        .fs1_data(fs1_data), .rm(rm), 
        .fd_data(fd_data), .fflags(fflags)
    );

    task test_case(
        input [31:0] t_fs1, 
        input [31:0] exp_fd, 
        input [255:0] t_name
    );
        begin
            total_cnt = total_cnt + 1;
            fs1_data = t_fs1; rm = 3'b000; // RNE 模式
            #10;
            if (fd_data === exp_fd) begin
                pass_cnt = pass_cnt + 1;
                $display("[PASS] %s", t_name);
            end else begin
                fail_cnt = fail_cnt + 1;
                $display("[FAIL] %s | Input=%h | Exp=%h, Got=%h", 
                          t_name, t_fs1, exp_fd, fd_data);
            end
        end
    endtask

    initial begin
        $display("==================================================");
        $display(" Start test: fpu_sqrt (FP Square Root)");
        $display("==================================================");

        // --- 1. 完美平方数测试 ---
        test_case(32'h40800000, 32'h40000000, "SQRT: sqrt(4.0)  = 2.0");
        test_case(32'h41100000, 32'h40400000, "SQRT: sqrt(9.0)  = 3.0");
        test_case(32'h3E800000, 32'h3F000000, "SQRT: sqrt(0.25) = 0.5");
        
        // --- 2. 刁钻无理数与舍入测试 (RNE & Sticky) ---
        // sqrt(2.0) = 1.41421356... -> IEEE 754 标准值为 0x3FB504F3
        test_case(32'h40000000, 32'h3FB504F3, "RND: sqrt(2.0)  ~= 1.4142135");

        // --- 3. 边界与异常情况测试 ---
        test_case(32'h00000000, 32'h00000000, "EXC: sqrt(+0.0) = +0.0");
        test_case(32'h80000000, 32'h80000000, "EXC: sqrt(-0.0) = -0.0");
        test_case(32'h7F800000, 32'h7F800000, "EXC: sqrt(+Inf) = +Inf");
        
        // 负数开方触发 Invalid Operation 变成 NaN
        test_case(32'hC0000000, 32'h7FC00000, "EXC: sqrt(-2.0) = NaN (Invalid)");
        test_case(32'hFF800000, 32'h7FC00000, "EXC: sqrt(-Inf) = NaN (Invalid)");
        
        // 包含 NaN 的运算
        test_case(32'h7FC00000, 32'h7FC00000, "EXC: sqrt(NaN)  = NaN");

        $display("==================================================");
        $display(" Test Summary: Passed=%0d, Failed=%0d", pass_cnt, fail_cnt);
        if (fail_cnt == 0) $display(" PERFECT FSQRT MATCH!");
        $display("==================================================");
        $finish;
    end
endmodule
