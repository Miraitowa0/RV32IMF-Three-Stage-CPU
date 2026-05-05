`timescale 1ns / 1ps

module tb_fpu_fmac;

    reg  [31:0] fs1_data;
    reg  [31:0] fs2_data;
    reg  [31:0] fs3_data;
    reg  [1:0]  ctrl;
    reg  [2:0]  rm;
    wire [31:0] fd_data;
    wire [4:0]  fflags;

    integer pass_cnt = 0, fail_cnt = 0, total_cnt = 0;

    fpu_fmac u_fpu_fmac (
        .fs1_data(fs1_data), .fs2_data(fs2_data), .fs3_data(fs3_data),
        .ctrl(ctrl), .rm(rm), .fd_data(fd_data), .fflags(fflags)
    );

    task test_case(
        input [1:0]  t_ctrl,
        input [31:0] t_fs1, input [31:0] t_fs2, input [31:0] t_fs3,
        input [31:0] exp_fd, input [255:0] t_name
    );
        begin
            total_cnt = total_cnt + 1;
            ctrl = t_ctrl; fs1_data = t_fs1; fs2_data = t_fs2; fs3_data = t_fs3; rm = 3'b000;
            #10;
            if (fd_data === exp_fd) begin
                pass_cnt = pass_cnt + 1;
                $display("[PASS] %s", t_name);
            end else begin
                fail_cnt = fail_cnt + 1;
                $display("[FAIL] %s | Exp=%h, Got=%h", t_name, exp_fd, fd_data);
            end
        end
    endtask

    initial begin
        $display("==================================================");
        $display(" Start test: fpu_fmac (Fused Multiply-Accumulate)");
        $display("==================================================");

        // 基本测试值：fs1=1.0, fs2=2.0, fs3=3.0
        // rs1 * rs2 = 2.0
        
        // 1. FMADD (00): + (1.0 * 2.0) + 3.0 = 5.0
        test_case(2'b00, 32'h3F800000, 32'h40000000, 32'h40400000, 32'h40A00000, "FMADD : +(1.0 * 2.0) + 3.0 = +5.0");

        // 2. FMSUB (01): + (1.0 * 2.0) - 3.0 = -1.0
        test_case(2'b01, 32'h3F800000, 32'h40000000, 32'h40400000, 32'hBF800000, "FMSUB : +(1.0 * 2.0) - 3.0 = -1.0");

        // 3. FNMSUB(10): - (1.0 * 2.0) + 3.0 = 1.0
        test_case(2'b10, 32'h3F800000, 32'h40000000, 32'h40400000, 32'h3F800000, "FNMSUB: -(1.0 * 2.0) + 3.0 = +1.0");

        // 4. FNMADD(11): - (1.0 * 2.0) - 3.0 = -5.0
        test_case(2'b11, 32'h3F800000, 32'h40000000, 32'h40400000, 32'hC0A00000, "FNMADD: -(1.0 * 2.0) - 3.0 = -5.0");

        $display("==================================================");
        $display(" Test Summary: Passed=%0d, Failed=%0d", pass_cnt, fail_cnt);
        if (fail_cnt == 0) $display("PERFECT FMAC MATCH!");
        $display("==================================================");
        $finish;
    end
endmodule
