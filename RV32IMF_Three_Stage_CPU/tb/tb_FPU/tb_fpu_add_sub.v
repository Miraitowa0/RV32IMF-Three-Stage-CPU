`timescale 1ns / 1ps

module tb_fpu_add_sub;

    reg  [31:0] fs1_data;
    reg  [31:0] fs2_data;
    reg         ctrl;       // 0: fadd.s, 1: fsub.s
    reg  [2:0]  rm;
    wire [31:0] fd_data;
    wire [4:0]  fflags;

    integer pass_cnt = 0, fail_cnt = 0, total_cnt = 0;

    fpu_add_sub u_fpu_add_sub (
        .fs1_data(fs1_data), .fs2_data(fs2_data), .ctrl(ctrl), 
        .rm(rm), .fd_data(fd_data), .fflags(fflags)
    );

    task test_case(
        input         t_ctrl,
        input  [31:0] t_fs1, 
        input  [31:0] t_fs2, 
        input  [31:0] exp_fd, 
        input  [400:0] t_name
    );
        begin
            total_cnt = total_cnt + 1;
            ctrl = t_ctrl; fs1_data = t_fs1; fs2_data = t_fs2; rm = 3'b000; // RNE
            #10;
            if (fd_data === exp_fd) begin
                pass_cnt = pass_cnt + 1;
                $display("[PASS] %s", t_name);
            end else begin
                fail_cnt = fail_cnt + 1;
                $display("[FAIL] %s | fs1=%h, fs2=%h, ctrl=%b | Exp=%h, Got=%h", 
                          t_name, t_fs1, t_fs2, t_ctrl, exp_fd, fd_data);
            end
        end
    endtask

    initial begin
        $display("==================================================");
        $display(" Start test: fpu_add_sub (FP Adder/Subtractor)");
        $display("==================================================");

        // --- 1. 基础加法 (fadd.s) ---
        // 1.0 + 2.0 = 3.0
        test_case(1'b0, 32'h3F800000, 32'h40000000, 32'h40400000, "ADD: 1.0 + 2.0 = 3.0");
        // 1.5 + 1.5 = 3.0 (测试进位右移 add_overflow)
        test_case(1'b0, 32'h3FC00000, 32'h3FC00000, 32'h40400000, "ADD: 1.5 + 1.5 = 3.0 (Overflow shift)");
        // 1.0 + (-1.5) = -0.5
        test_case(1'b0, 32'h3F800000, 32'hBFC00000, 32'hBF000000, "ADD: 1.0 + (-1.5) = -0.5");

        // --- 2. 基础减法 (fsub.s) ---
        // 3.0 - 2.0 = 1.0
        test_case(1'b1, 32'h40400000, 32'h40000000, 32'h3F800000, "SUB: 3.0 - 2.0 = 1.0");
        // 1.0 - 2.0 = -1.0 (测试小数减大数自动翻转 L/S 逻辑)
        test_case(1'b1, 32'h3F800000, 32'h40000000, 32'hBF800000, "SUB: 1.0 - 2.0 = -1.0");

        // --- 3. LOD 严重相消测试 (Catastrophic Cancellation) ---
        // 1.5 - 1.0 = 0.5 (尾数高位全0，需左移归一化)
        test_case(1'b1, 32'h3FC00000, 32'h3F800000, 32'h3F000000, "LOD: 1.5 - 1.0 = 0.5 (Left shift)");
        // 1.0 - 1.0 = 0.0 (彻底相消，触发 is_zero_res)
        test_case(1'b1, 32'h3F800000, 32'h3F800000, 32'h00000000, "LOD: 1.0 - 1.0 = +0.0");

        // --- 4. GRS 舍入测试 (Rounding) ---
        // 故意造一个极小位数丢失的加法测试 RNE
        // 1.0 (3F800000) + 2^-24 (33000000) -> 由于精度不足，RNE会舍去，依然为 1.0
        test_case(1'b0, 32'h3F800000, 32'h33000000, 32'h3F800000, "RND: 1.0 + 2^-24 = 1.0 (Ties to Even round down)");

        // --- 5. 异常边界 (Exceptions) ---
        // +Inf + (-Inf) = NaN
        test_case(1'b0, 32'h7F800000, 32'hFF800000, 32'h7FC00000, "EXC: +Inf + (-Inf) = NaN");
        // 1.0 + NaN = NaN
        test_case(1'b0, 32'h3F800000, 32'h7FC00000, 32'h7FC00000, "EXC: 1.0 + NaN = NaN");
        // +Inf - 1.0 = +Inf
        test_case(1'b1, 32'h7F800000, 32'h3F800000, 32'h7F800000, "EXC: +Inf - 1.0 = +Inf");

        $display("==================================================");
        $display(" Test Summary: Passed=%0d, Failed=%0d", pass_cnt, fail_cnt);
        if (fail_cnt == 0) $display(" PERFECT FADD/FSUB MATCH!");
        $display("==================================================");
        $finish;
    end
endmodule
