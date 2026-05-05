`timescale 1ns / 1ps

module tb_fpu_div;

    reg  [31:0] fs1_data;
    reg  [31:0] fs2_data;
    reg  [2:0]  rm;
    wire [31:0] fd_data;
    wire [4:0]  fflags;

    integer pass_cnt = 0, fail_cnt = 0, total_cnt = 0;

    fpu_div u_fpu_div (
        .fs1_data(fs1_data), .fs2_data(fs2_data), 
        .rm(rm), .fd_data(fd_data), .fflags(fflags)
    );

    task test_case(
        input [31:0] t_fs1, input [31:0] t_fs2, 
        input [31:0] exp_fd, input [255:0] t_name
    );
        begin
            total_cnt = total_cnt + 1;
            fs1_data = t_fs1; fs2_data = t_fs2; rm = 3'b000; // RNE 模式
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
        $display(" Start test: fpu_div (Floating-Point Divider)");
        $display("==================================================");

        // --- 1. 基础除法 (无需舍入) ---
        test_case(32'h40800000, 32'h40000000, 32'h40000000, "DIV: 4.0 / 2.0 = 2.0");
        test_case(32'h40400000, 32'h40000000, 32'h3FC00000, "DIV: 3.0 / 2.0 = 1.5");
        
        // --- 2. 刁钻舍入测试 (循环小数与余数) ---
        // 1.0 / 3.0 = 0.33333333... (测试是否正确产生 Sticky 并舍入)
        test_case(32'h3F800000, 32'h40400000, 32'h3EAAAAAB, "RND: 1.0 / 3.0 = 0.33333334");

        // --- 3. 符号测试 ---
        test_case(32'hC0800000, 32'h40000000, 32'hC0000000, "SGN: -4.0 / +2.0 = -2.0");
        test_case(32'hC0800000, 32'hC0000000, 32'h40000000, "SGN: -4.0 / -2.0 = +2.0");

        // --- 4. 异常与极限情况 (Exceptions) ---
        // 0 / 0 = NaN (Invalid Operation)
        test_case(32'h00000000, 32'h00000000, 32'h7FC00000, "EXC: 0.0 / 0.0 = NaN");
        // Inf / Inf = NaN
        test_case(32'h7F800000, 32'h7F800000, 32'h7FC00000, "EXC: +Inf / +Inf = NaN");
        // 常数 / 0 = Inf (Divide by Zero)
        test_case(32'h3F800000, 32'h00000000, 32'h7F800000, "EXC: 1.0 / 0.0 = +Inf");
        // 常数 / Inf = 0
        test_case(32'h3F800000, 32'h7F800000, 32'h00000000, "EXC: 1.0 / +Inf = 0.0");
        // 0 / 常数 = 0
        test_case(32'h00000000, 32'h3F800000, 32'h00000000, "EXC: 0.0 / 1.0 = 0.0");

        $display("==================================================");
        $display(" Test Summary: Passed=%0d, Failed=%0d", pass_cnt, fail_cnt);
        if (fail_cnt == 0) $display(" PERFECT FDIV MATCH!");
        $display("==================================================");
        $finish;
    end
endmodule
