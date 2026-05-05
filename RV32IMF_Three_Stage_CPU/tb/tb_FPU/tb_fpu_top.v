`timescale 1ns / 1ps

module tb_fpu_top;

    // 1. DUT 接口信号
    reg         clk;
    reg         rst_n;

    reg         i_valid;
    wire        o_ready;
    wire        o_valid;

    reg  [4:0]  i_op_type;
    reg  [2:0]  i_rm;
    reg  [31:0] i_src1;
    reg  [31:0] i_src2;
    reg  [31:0] i_src3;

    wire [31:0] o_result;
    wire [4:0]  o_fflags;

    // 2. 例化 DUT
    fpu_top u_fpu_top (
        .clk       (clk),
        .rst_n     (rst_n),
        .i_valid   (i_valid),
        .o_ready   (o_ready),
        .o_valid   (o_valid),
        .i_op_type (i_op_type),
        .i_rm      (i_rm),
        .i_src1    (i_src1),
        .i_src2    (i_src2),
        .i_src3    (i_src3),
        .o_result  (o_result),
        .o_fflags  (o_fflags)
    );

    // 3. 操作码定义（与 fpu_top 对齐）
    localparam OP_FADD      = 5'd0;
    localparam OP_FSUB      = 5'd1;
    localparam OP_FMUL      = 5'd2;
    localparam OP_FDIV      = 5'd3;
    localparam OP_FSQRT     = 5'd4;
    localparam OP_FMADD     = 5'd5;
    localparam OP_FMSUB     = 5'd6;
    localparam OP_FNMSUB    = 5'd7;
    localparam OP_FNMADD    = 5'd8;
    localparam OP_FSGNJ     = 5'd9;
    localparam OP_FSGNJN    = 5'd10;
    localparam OP_FSGNJX    = 5'd11;
    localparam OP_FMAX      = 5'd12;
    localparam OP_FMIN      = 5'd13;
    localparam OP_FEQ       = 5'd14;
    localparam OP_FLT       = 5'd15;
    localparam OP_FLE       = 5'd16;
    localparam OP_FCLASS    = 5'd17;
    localparam OP_FCVT_W_S  = 5'd18;
    localparam OP_FCVT_WU_S = 5'd19;
    localparam OP_FCVT_S_W  = 5'd20;
    localparam OP_FCVT_S_WU = 5'd21;

    localparam RM_RNE = 3'b000;

    // 4. 统计变量
    integer total_cnt;
    integer pass_cnt;
    integer fail_cnt;
    integer tb_cycle;

    // 5. 时钟产生
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;   // 10ns 时钟周期
    end

    always @(posedge clk) begin
        tb_cycle <= tb_cycle + 1;
    end

    // 6. 通用测试任务
    task run_fpu_op;
        input [127:0] op_name;
        input [4:0]   op_type;
        input [31:0]  src1;
        input [31:0]  src2;
        input [31:0]  src3;
        input [31:0]  exp_result;
        input [4:0]   exp_fflags;

        integer start_cycle;
        integer latency;
        integer timeout;
        begin
            total_cnt = total_cnt + 1;

            // 1) 等待 FPU 空闲
            timeout = 0;
            while (o_ready !== 1'b1) begin
                @(posedge clk);
                timeout = timeout + 1;
                if (timeout > 100) begin
                    $display("[FATAL] %s : wait o_ready timeout!", op_name);
                    $finish;
                end
            end

            // 2) 在下降沿准备输入，保证下一个上升沿可被采样
            @(negedge clk);
            i_valid   = 1'b1;
            i_op_type = op_type;
            i_rm      = RM_RNE;
            i_src1    = src1;
            i_src2    = src2;
            i_src3    = src3;

            start_cycle = tb_cycle;

            // 3) 保持 1 个请求周期后撤销 valid
            @(negedge clk);
            i_valid = 1'b0;

            // 4) 等待结果有效
            timeout = 0;
            while (o_valid !== 1'b1) begin
                @(posedge clk);
					 #1;   // 等待 DUT 在该时钟沿后的寄存器和组合逻辑稳定
                timeout = timeout + 1;
                if (timeout > 100) begin
                    $display("[FATAL] %s : wait o_valid timeout!", op_name);
                    $finish;
                end
            end

            latency = tb_cycle - start_cycle;

            // 5) 比较结果
            if ((o_result === exp_result) && (o_fflags === exp_fflags)) begin
                pass_cnt = pass_cnt + 1;
                $display("[PASS] %-24s latency=%0d  result=%h fflags=%b",
                         op_name, latency, o_result, o_fflags);
            end else begin
                fail_cnt = fail_cnt + 1;
                $display("[FAIL] %-24s latency=%0d", op_name, latency);
                $display("       expected result=%h fflags=%b", exp_result, exp_fflags);
                $display("       got      result=%h fflags=%b", o_result, o_fflags);
                $display("       src1=%h src2=%h src3=%h", src1, src2, src3);
            end

            @(posedge clk);
        end
    endtask

    // 7. 初始化与测试序列
    initial begin
        total_cnt = 0;
        pass_cnt  = 0;
        fail_cnt  = 0;
        tb_cycle  = 0;

        rst_n     = 1'b0;
        i_valid   = 1'b0;
        i_op_type = 5'd0;
        i_rm      = 3'd0;
        i_src1    = 32'd0;
        i_src2    = 32'd0;
        i_src3    = 32'd0;

        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        $display("===============================================================");
        $display("          Start FPU Top-Level Integration Test");
        $display("===============================================================");

        // ---------------- 基础算术 ----------------
        run_fpu_op("FADD 1.0+2.0",     OP_FADD, 32'h3F800000, 32'h40000000, 32'd0, 32'h40400000, 5'b00000);
        run_fpu_op("FSUB 5.0-2.0",     OP_FSUB, 32'h40A00000, 32'h40000000, 32'd0, 32'h40400000, 5'b00000);
        run_fpu_op("FMUL 2.0*3.0",     OP_FMUL, 32'h40000000, 32'h40400000, 32'd0, 32'h40C00000, 5'b00000);

        // ---------------- FMA ----------------
        run_fpu_op("FMADD 1*2+3",      OP_FMADD, 32'h3F800000, 32'h40000000, 32'h40400000, 32'h40A00000, 5'b00000);

        // ---------------- 比较最值 ----------------
        run_fpu_op("FMAX max(1,2)",    OP_FMAX, 32'h3F800000, 32'h40000000, 32'd0, 32'h40000000, 5'b00000);
        run_fpu_op("FMIN min(1,2)",    OP_FMIN, 32'h3F800000, 32'h40000000, 32'd0, 32'h3F800000, 5'b00000);
        run_fpu_op("FEQ 2==2",         OP_FEQ,  32'h40000000, 32'h40000000, 32'd0, 32'h00000001, 5'b00000);
        run_fpu_op("FLT 1<2",          OP_FLT,  32'h3F800000, 32'h40000000, 32'd0, 32'h00000001, 5'b00000);
        run_fpu_op("FLE 2<=2",         OP_FLE,  32'h40000000, 32'h40000000, 32'd0, 32'h00000001, 5'b00000);

        // ---------------- 符号注入 ----------------
        run_fpu_op("FSGNJ +1.5,-2.0",  OP_FSGNJ,  32'h3FC00000, 32'hC0000000, 32'd0, 32'hBFC00000, 5'b00000);
        run_fpu_op("FSGNJN +1.5,-2.0", OP_FSGNJN, 32'h3FC00000, 32'hC0000000, 32'd0, 32'h3FC00000, 5'b00000);
        run_fpu_op("FSGNJX -1.5,-2.0", OP_FSGNJX, 32'hBFC00000, 32'hC0000000, 32'd0, 32'h3FC00000, 5'b00000);

        // ---------------- 分类与转换 ----------------
        run_fpu_op("FCLASS qNaN",      OP_FCLASS,    32'h7FC00000, 32'd0, 32'd0, 32'h00000200, 5'b00000);
        run_fpu_op("FCVT.W.S 1.5->2",  OP_FCVT_W_S,  32'h3FC00000, 32'd0, 32'd0, 32'h00000002, 5'b00000);
        run_fpu_op("FCVT.S.W 2->2.0",  OP_FCVT_S_W,  32'h00000002, 32'd0, 32'd0, 32'h40000000, 5'b00000);

        // ---------------- 多周期 ----------------
        $display("---------------------------------------------------------------");
        $display("  Multicycle operation check");
        $display("---------------------------------------------------------------");
        run_fpu_op("FDIV 3.0/2.0",     OP_FDIV,  32'h40400000, 32'h40000000, 32'd0, 32'h3FC00000, 5'b00000);
        run_fpu_op("FSQRT sqrt(4.0)",  OP_FSQRT, 32'h40800000, 32'd0,        32'd0, 32'h40000000, 5'b00000);

        // ---------------- 非法操作码保护 ----------------
        run_fpu_op("UNKNOWN opcode",   5'd31,    32'h3F800000, 32'd0,        32'd0, 32'h7FC00000, 5'b10000);

        $display("===============================================================");
        $display(" Summary: Total=%0d, Pass=%0d, Fail=%0d", total_cnt, pass_cnt, fail_cnt);
        if (fail_cnt == 0)
            $display(" ALL TESTS PASSED.");
        else
            $display(" SOME TESTS FAILED.");
        $display("===============================================================");

        #20;
        $finish;
    end

endmodule
