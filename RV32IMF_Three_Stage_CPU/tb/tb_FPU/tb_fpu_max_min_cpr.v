`timescale 1ns / 1ps

module tb_fpu_max_min_cpr;

    // -------------------------- 信号定义 --------------------------
    reg         clk;            // 时钟信号（驱动测试流程）
    reg  [31:0] fs1_data;       // 输入操作数1
    reg  [31:0] fs2_data;       // 输入操作数2
    reg  [2:0]  ctrl;           // 指令控制信号
    wire [31:0] fd_data;        // 模块输出结果

    // 测试统计变量
    integer     pass_cnt;       
    integer     fail_cnt;       
    integer     total_cnt;      

    // -------------------------- 模块实例化 --------------------------
    fpu_max_min_cpr u_fpu_max_min_cpr (
        .fs1_data  (fs1_data),
        .fs2_data  (fs2_data),
        .ctrl      (ctrl),
        .fd_data   (fd_data)
    );

    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end

    // -------------------------- 测试任务封装 --------------------------
    task test_case(
        input [2:0]   test_ctrl,
        input [31:0]  test_fs1,
        input [31:0]  test_fs2,
        input [31:0]  exp_fd,
        input [400:0] test_name  // 增加了字符串位宽，防止名字被截断
    );
        begin
            total_cnt = total_cnt + 1;
            // 输入赋值
            ctrl = test_ctrl;
            fs1_data = test_fs1;
            fs2_data = test_fs2;
            
            // 组合逻辑等待（1个时钟周期）
            @(posedge clk);
            
            // 验证结果
            if (fd_data === exp_fd) begin
                pass_cnt = pass_cnt + 1;
                $display("[PASS] %s", test_name);
            end else begin
                fail_cnt = fail_cnt + 1;
                $display("[FAIL] %s | fs1=0x%08X, fs2=0x%08X | Exp=0x%08X, Got=0x%08X",
                          test_name, test_fs1, test_fs2, exp_fd, fd_data);
            end
        end
    endtask

    // -------------------------- 测试用例执行 --------------------------
    initial begin
        // 初始化变量
        pass_cnt = 0;
        fail_cnt = 0;
        total_cnt = 0;
        fs1_data = 32'h00000000;
        fs2_data = 32'h00000000;
        ctrl = 3'b000;
        #15; // 错开时钟边沿

        $display("==================================================");
        $display(" Start test: fpu_max_min_cpr module");
        $display("==================================================");

        // -------------------------- 1. fmax.s 测试 --------------------------
        //单边NaN应返回另一个有效数字，双边NaN返回标准NaN 0x7FC00000
        test_case(3'b000, 32'h7FFFFFFF, 32'h3F800000, 32'h3F800000, "fmax.s: NaN  and 1.0  -> returns 1.0");
        test_case(3'b000, 32'h3F800000, 32'h7FC00000, 32'h3F800000, "fmax.s: 1.0  and NaN  -> returns 1.0");
        test_case(3'b000, 32'h7FFFFFFF, 32'h7FFFFFFF, 32'h7FC00000, "fmax.s: NaN  and NaN  -> returns Canonical NaN");
        //FMAX 中，-0.0 严格小于 +0.0
        test_case(3'b000, 32'h80000000, 32'h00000000, 32'h00000000, "fmax.s: -0.0 and +0.0 -> returns +0.0");
        // 普通测试：正负数对比
        test_case(3'b000, 32'h40000000, 32'h40400000, 32'h40400000, "fmax.s: 2.0  and 3.0  -> returns 3.0");
        test_case(3'b000, 32'hC0000000, 32'hBF800000, 32'hBF800000, "fmax.s: -2.0 and -1.0 -> returns -1.0");

        // -------------------------- 2. fmin.s 测试 --------------------------
        //单边NaN应返回另一个有效数字
        test_case(3'b001, 32'h3F800000, 32'h7FFFFFFF, 32'h3F800000, "fmin.s: 1.0  and NaN  -> returns 1.0");
        //FMIN 中，-0.0 严格小于 +0.0
        test_case(3'b001, 32'h00000000, 32'h80000000, 32'h80000000, "fmin.s: +0.0 and -0.0 -> returns -0.0");
        // 普通测试：正负数对比
        test_case(3'b001, 32'h40000000, 32'h40400000, 32'h40000000, "fmin.s: 2.0  and 3.0  -> returns 2.0");
        test_case(3'b001, 32'hC0000000, 32'hBF800000, 32'hC0000000, "fmin.s: -2.0 and -1.0 -> returns -2.0");
        test_case(3'b001, 32'hFF800000, 32'h3F800000, 32'hFF800000, "fmin.s: -Inf and 1.0  -> returns -Inf");

        // -------------------------- 3. feq.s 测试 --------------------------
        //FEQ 中，+0.0 是严格等于 -0.0 的
        test_case(3'b010, 32'h80000000, 32'h00000000, 32'h00000001, "feq.s:  -0.0 == +0.0  -> True(1)");
        // 任何包含 NaN 的比较都是 False
        test_case(3'b010, 32'h7FFFFFFF, 32'h3F800000, 32'h00000000, "feq.s:  NaN  == 1.0   -> False(0)");
        test_case(3'b010, 32'h7FC00000, 32'h7FC00000, 32'h00000000, "feq.s:  NaN  == NaN   -> False(0)");
        test_case(3'b010, 32'h3F800000, 32'h3F800000, 32'h00000001, "feq.s:  1.0  == 1.0   -> True(1)");

        // -------------------------- 4. flt.s 测试 --------------------------
        //FLT 中，-0.0 不小于 +0.0 (因为它们相等)
        test_case(3'b011, 32'h80000000, 32'h00000000, 32'h00000000, "flt.s:  -0.0 < +0.0   -> False(0)");
        test_case(3'b011, 32'h7FFFFFFF, 32'h3F800000, 32'h00000000, "flt.s:  NaN  < 1.0    -> False(0)");
        test_case(3'b011, 32'hC0000000, 32'hBF800000, 32'h00000001, "flt.s:  -2.0 < -1.0   -> True(1)");
        test_case(3'b011, 32'h3F800000, 32'h7F800000, 32'h00000001, "flt.s:  1.0  < +Inf   -> True(1)");
        test_case(3'b011, 32'h40400000, 32'h40000000, 32'h00000000, "flt.s:  3.0  < 2.0    -> False(0)");

        // -------------------------- 5. fle.s 测试 --------------------------
        //FLE 中，-0.0 小于等于 +0.0 (因为它们相等)
        test_case(3'b100, 32'h80000000, 32'h00000000, 32'h00000001, "fle.s:  -0.0 <= +0.0  -> True(1)");
        test_case(3'b100, 32'h7FFFFFFF, 32'h7FFFFFFF, 32'h00000000, "fle.s:  NaN  <= NaN   -> False(0)");
        test_case(3'b100, 32'h40000000, 32'h40000000, 32'h00000001, "fle.s:  2.0  <= 2.0   -> True(1)");
        test_case(3'b100, 32'h3F800000, 32'h40000000, 32'h00000001, "fle.s:  1.0  <= 2.0   -> True(1)");
        test_case(3'b100, 32'h40000000, 32'hBF800000, 32'h00000000, "fle.s:  2.0  <= -1.0  -> False(0)");

        // -------------------------- 测试结果汇总 --------------------------
        $display("==================================================");
        $display(" Test Summary: Total=%0d, Passed=%0d, Failed=%0d", total_cnt, pass_cnt, fail_cnt);
        if (fail_cnt == 0) begin
            $display(" AMAZING! All test cases perfectly matched RISC-V specs!");
        end else begin
            $display(" Some test cases failed! Please check your design.");
        end
        $display("==================================================");
 
        // 结束仿真
        #100;
        $finish;
    end

endmodule
