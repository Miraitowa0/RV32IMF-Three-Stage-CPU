`timescale 1ns / 1ps

module tb_fpu_sw_swu;

    reg  [31:0] rs1_data;
    reg         ctrl;
    reg  [2:0]  rm;
    wire [31:0] fd_data;
    wire [4:0]  fflags;

    integer pass_cnt = 0;
    integer fail_cnt = 0;
    integer total_cnt = 0;

    fpu_sw_swu u_fpu_sw_swu (
        .rs1_data (rs1_data),
        .ctrl     (ctrl),
        .rm       (rm),
        .fd_data  (fd_data),
        .fflags   (fflags)
    );

    task test_case(
        input         test_ctrl,
        input  [31:0] test_rs1,
        input  [31:0] exp_fd,
        input  [255:0] test_name
    );
        begin
            total_cnt = total_cnt + 1;
            ctrl     = test_ctrl;
            rs1_data = test_rs1;
            rm       = 3'b000; // 使用 RNE
            #10;
            if (fd_data === exp_fd) begin
                pass_cnt = pass_cnt + 1;
                $display("[PASS] %s", test_name);
            end else begin
                fail_cnt = fail_cnt + 1;
                $display("[FAIL] %s | rs1=0x%08X | Exp=0x%08X, Got=0x%08X",
                          test_name, test_rs1, exp_fd, fd_data);
            end
        end
    endtask

    initial begin
        $display("==================================================");
        $display(" Start test: fpu_sw_swu module");
        $display("==================================================");

        // --- 1. 有符号转换基础测试 ---
        test_case(1'b0, 32'd0,          32'h00000000, "Signed: 0    -> 0.0");
        test_case(1'b0, 32'd1,          32'h3F800000, "Signed: 1    -> 1.0");
        test_case(1'b0, -32'd1,         32'hBF800000, "Signed: -1   -> -1.0");
        
        // 有符号极值 (由于精度限制，低位会丢失并被舍入)
        test_case(1'b0, 32'd2147483647, 32'h4F000000, "Signed: Max Int -> 2.14748365E9");
        test_case(1'b0, -32'd2147483648,32'hCF000000, "Signed: Min Int -> -2.14748365E9");

        // --- 2. 无符号转换基础测试 ---
        test_case(1'b1, 32'd1,          32'h3F800000, "Unsigned: 1  -> 1.0");
        test_case(1'b1, 32'hFFFFFFFF,   32'h4F800000, "Unsigned: Max UInt (4294967295) -> 4.2949673E9");

        // --- 3. 刁钻的 RNE 舍入逻辑测试 ---
        // 浮点数只有 24 位有效精度。如果遇到 28 位的整数 0x10000010 (2^28 + 16)，恰好卡在两个浮点数中间
        // RNE 要求“向偶数舍入”，所以 0x10000010 会舍弃低位，退回 2^28 (0x4D800000)
        test_case(1'b0, 32'h10000010,   32'h4D800000, "Rounding: Tie to Even (Rounds Down)");
        // 如果再大一点点，变成 0x10000018 (2^28 + 24)，就会进位，变成 2^28 + 32 (0x4D800001)
        test_case(1'b0, 32'h10000018,   32'h4D800001, "Rounding: Tie to Even (Rounds Up)");

        $display("==================================================");
        $display(" Test Summary: Total=%0d, Passed=%0d, Failed=%0d", total_cnt, pass_cnt, fail_cnt);
        if (fail_cnt == 0) $display(" PERFECT MATCH!");
        $display("==================================================");
        $finish;
    end
endmodule
