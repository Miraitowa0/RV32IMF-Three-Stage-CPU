`timescale 1ns / 1ps

module tb_fpu_ws_wus;

    // ==========================================
    // 1. 信号声明 (对应 DUT 端口)
    // ==========================================
    reg  [31:0] fs1_data;
    reg         ctrl;
    reg  [2:0]  rm;
    wire [31:0] fd_data;
    wire [4:0]  fflags;

    // ==========================================
    // 2. 例化待测模块 (DUT - Device Under Test)
    // ==========================================
    fpu_ws_wus u_fcvt (
        .fs1_data (fs1_data),
        .ctrl     (ctrl),
        .rm       (rm),
        .fd_data  (fd_data),
        .fflags   (fflags)
    );

    // ==========================================
    // 3. 自动化比对任务 (Task) 
    // 这能让代码非常整洁，方便添加无数个测试用例
    // ==========================================
    integer error_count = 0;
    integer pass_count  = 0;

    task check_conversion;
        input [127:0] test_name;  // 测试项名字 (用于打印)
        input [31:0]  in_float;   // 输入的 32位 IEEE 754 浮点数 (十六进制)
        input         in_ctrl;    // 控制信号：0=有符号，1=无符号
        input [31:0]  expected;   // 预期的 32位 整数结果
        begin
            fs1_data = in_float;
            ctrl     = in_ctrl;
            rm       = 3'b000;    // 本测试均在默认的 RNE (最近偶数) 模式下进行
            
            #10; // 等待 10ns 让组合逻辑计算完成

            // 判断输出是否符合预期
            if (fd_data !== expected) begin
                $display("[FAIL] %s | Float Input: %h | Ctrl: %b | Expected: %h | Got: %h", 
                          test_name, in_float, in_ctrl, expected, fd_data);
                error_count = error_count + 1;
            end else begin
                $display("[PASS] %s | Output: %h", test_name, fd_data);
                pass_count = pass_count + 1;
            end
            #10; // 每测完一个停顿一下，让波形图更好看
        end
    endtask

    // ==========================================
    // 4. 执行测试序列
    // ==========================================
    initial begin
        $display("==================================================");
        $display("FPU FCVT.W.S / FCVT.WU.S Testbench Start");
        $display("==================================================");

        // -----------------------------------------------------------
        // 测试组 A：基本数值与 RNE 舍入测试 (ctrl = 0, 有符号转换)
        // -----------------------------------------------------------
        // 1.0 -> 1
        check_conversion("Signed: +1.0      ", 32'h3F800000, 1'b0, 32'd1);
        // -1.0 -> -1
        check_conversion("Signed: -1.0      ", 32'hBF800000, 1'b0, -32'd1);
        
        // 【关键舍入测试 RNE：向最近偶数舍入】
        // 1.5 -> 2 (0.5 且整数位是奇数 1，进位成 2)
        check_conversion("Signed: +1.5 (RNE)", 32'h3FC00000, 1'b0, 32'd2);
        // 2.5 -> 2 (0.5 且整数位是偶数 2，不进位，保持 2)
        check_conversion("Signed: +2.5 (RNE)", 32'h40200000, 1'b0, 32'd2);
        // -1.5 -> -2
        check_conversion("Signed: -1.5 (RNE)", 32'hBFC00000, 1'b0, -32'd2);
        // -2.5 -> -2
        check_conversion("Signed: -2.5 (RNE)", 32'hC0200000, 1'b0, -32'd2);

        // -----------------------------------------------------------
        // 测试组 B：有符号数的边界与异常 (ctrl = 0, fcvt.w.s)
        // -----------------------------------------------------------
        // 输入 +Inf -> 饱和到 2^31 - 1 (0x7FFFFFFF)
        check_conversion("Signed: +Inf      ", 32'h7F800000, 1'b0, 32'h7FFFFFFF);
        // 输入 -Inf -> 饱和到 -2^31 (0x80000000)
        check_conversion("Signed: -Inf      ", 32'hFF800000, 1'b0, 32'h80000000);
        // 输入 NaN (0x7FC00000) -> 饱和到 2^31 - 1
        check_conversion("Signed: NaN       ", 32'h7FC00000, 1'b0, 32'h7FFFFFFF);
        // 超大正数溢出 (比如 1.0 * 2^35 -> 0x51000000) -> 饱和到 0x7FFFFFFF
        check_conversion("Signed: +Overflow ", 32'h51000000, 1'b0, 32'h7FFFFFFF);

        // -----------------------------------------------------------
        // 测试组 C：无符号数的转换与边界 (ctrl = 1, fcvt.wu.s)
        // -----------------------------------------------------------
        // 1.0 -> 1
        check_conversion("Unsigned: +1.0    ", 32'h3F800000, 1'b1, 32'd1);
        // 输入负数 (-1.0) -> 无符号不支持负数，饱和到 0
        check_conversion("Unsigned: -1.0    ", 32'hBF800000, 1'b1, 32'h00000000);
        // 输入 +Inf -> 饱和到 2^32 - 1 (0xFFFFFFFF)
        check_conversion("Unsigned: +Inf    ", 32'h7F800000, 1'b1, 32'hFFFFFFFF);
        // 输入 -Inf -> 饱和到 0
        check_conversion("Unsigned: -Inf    ", 32'hFF800000, 1'b1, 32'h00000000);
        // 输入 NaN -> 饱和到 0xFFFFFFFF
        check_conversion("Unsigned: NaN     ", 32'h7FC00000, 1'b1, 32'hFFFFFFFF);

        // -----------------------------------------------------------
        // 5. 测试结果总结
        // -----------------------------------------------------------
        $display("==================================================");
        $display("Test Completed!");
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", error_count);
        if (error_count == 0) begin
            $display("PERFECT! The module's logic is in accordance with the RISC-V specification！");
        end
        $display("==================================================");

        $finish; // 结束仿真
    end

endmodule
