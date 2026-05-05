`timescale 1ns / 1ps

module fpu_top (
    input  wire        clk,
    input  wire        rst_n,

    // 握手控制信号
    input  wire        i_valid,     // 来自整数核EX阶段的浮点请求有效
    output wire        o_ready,     // FPU空闲，可接收新请求
    output reg         o_valid,     // FPU结果有效（高1个周期）

    // 数据与控制输入
    input  wire [4:0]  i_op_type,   // 运算类型编码
    input  wire [2:0]  i_rm,        // 舍入模式
    input  wire [31:0] i_src1,      // 源操作数1
    input  wire [31:0] i_src2,      // 源操作数2
    input  wire [31:0] i_src3,      // 源操作数3（仅FMA类使用）

    // 数据与异常输出
    output reg  [31:0] o_result,    // 运算结果
    output reg  [4:0]  o_fflags     // 异常标志 {NV, DZ, OF, UF, NX}
);

    // 1. 运算类型编码定义
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

    // 2. 状态机定义
    localparam ST_IDLE = 2'd0;
    localparam ST_BUSY = 2'd1;
    localparam ST_DONE = 2'd2;

    reg [1:0] state, next_state;

    // 3. 输入锁存寄存器
    reg [4:0]  op_reg;
    reg [2:0]  rm_reg;
    reg [31:0] src1_reg, src2_reg, src3_reg;

    // 4. 延时计数器
    // 说明：
    // 顶层统一封装不同复杂度运算单元的响应时间
    // 这里是wrapper级延时建模，不代表所有子模块内部都是真实多周期
    reg [4:0] delay_cnt;

    // 空闲即可接收新请求
    assign o_ready = (state == ST_IDLE);

    // 标准握手：只有在 ready=1 时才接收请求
    wire accept_req = i_valid & o_ready;

    // 5. 状态机时序逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= ST_IDLE;
            op_reg   <= 5'd0;
            rm_reg   <= 3'd0;
            src1_reg <= 32'd0;
            src2_reg <= 32'd0;
            src3_reg <= 32'd0;
            delay_cnt <= 5'd0;
        end else begin
            state <= next_state;

            // 接收新请求时锁存输入
            if (accept_req) begin
                op_reg   <= i_op_type;
                rm_reg   <= i_rm;
                src1_reg <= i_src1;
                src2_reg <= i_src2;
                src3_reg <= i_src3;

                // 统一延时建模：
                // 复杂操作（除法/开方）设为较长延时，其余基础运算设为1周期响应
                if ((i_op_type == OP_FDIV) || (i_op_type == OP_FSQRT))
                    delay_cnt <= 5'd10;
                else
                    delay_cnt <= 5'd1;
            end
            else if (state == ST_BUSY) begin
                if (delay_cnt > 5'd0)
                    delay_cnt <= delay_cnt - 5'd1;
            end
        end
    end

    // 6. 状态机组合逻辑
    //    注意这里用 delay_cnt == 1 进入 DONE，避免多拖一拍
    always @(*) begin
        next_state = state;
        case (state)
            ST_IDLE: begin
                if (accept_req)
                    next_state = ST_BUSY;
            end

            ST_BUSY: begin
                if (delay_cnt == 5'd1)
                    next_state = ST_DONE;
            end

            ST_DONE: begin
                next_state = ST_IDLE;
            end

            default: begin
                next_state = ST_IDLE;
            end
        endcase
    end

    // 7. 底层计算子模块实例化
    wire [31:0] res_add_sub, res_mul, res_div, res_sqrt, res_fmac;
    wire [31:0] res_sgnj, res_cpr, res_class, res_f2i, res_i2f;

    wire [4:0]  flg_add_sub, flg_mul, flg_div, flg_sqrt, flg_fmac;
    wire [4:0]  flg_f2i, flg_i2f;

    // 7.1 加/减法
    fpu_add_sub u_add_sub (
        .fs1_data(src1_reg),
        .fs2_data(src2_reg),
        .ctrl    (op_reg == OP_FSUB),   // 0:add, 1:sub
        .rm      (rm_reg),
        .fd_data (res_add_sub),
        .fflags  (flg_add_sub)
    );

    // 7.2 乘法
    fpu_mul u_mul (
        .fs1_data(src1_reg),
        .fs2_data(src2_reg),
        .rm      (rm_reg),
        .fd_data (res_mul),
        .fflags  (flg_mul)
    );

    // 7.3 除法
    fpu_div u_div (
        .fs1_data(src1_reg),
        .fs2_data(src2_reg),
        .rm      (rm_reg),
        .fd_data (res_div),
        .fflags  (flg_div)
    );

    // 7.4 开方
    fpu_sqrt u_sqrt (
        .fs1_data(src1_reg),
        .rm      (rm_reg),
        .fd_data (res_sqrt),
        .fflags  (flg_sqrt)
    );

    // 7.5 乘加类  (ctrl: 00=madd, 01=msub, 10=nmsub, 11=nmadd)
    wire [1:0] mac_ctrl;
    assign mac_ctrl = (op_reg == OP_FMADD ) ? 2'b00 :
                      (op_reg == OP_FMSUB ) ? 2'b01 :
                      (op_reg == OP_FNMSUB) ? 2'b10 :
                                              2'b11;

    fpu_fmac u_fmac (
        .fs1_data(src1_reg),
        .fs2_data(src2_reg),
        .fs3_data(src3_reg),
        .ctrl    (mac_ctrl),
        .rm      (rm_reg),
        .fd_data (res_fmac),
        .fflags  (flg_fmac)
    );

    // 7.6 符号注入类 (ctrl: 0=j, 1=jn, 2=jx)
    wire [2:0] sgnj_ctrl;
    assign sgnj_ctrl = (op_reg == OP_FSGNJ ) ? 3'd0 :
                       (op_reg == OP_FSGNJN) ? 3'd1 :
                                               3'd2;

    fpu_fsgnj_n_x u_sgnj (
        .fs1_data(src1_reg),
        .fs2_data(src2_reg),
        .ctrl    (sgnj_ctrl),
        .fd_data (res_sgnj)
    );

    // 7.7 比较与最值类  (ctrl: 0=max, 1=min, 2=eq, 3=lt, 4=le)
    wire [2:0] cpr_ctrl;
    assign cpr_ctrl = (op_reg == OP_FMAX) ? 3'd0 :
                      (op_reg == OP_FMIN) ? 3'd1 :
                      (op_reg == OP_FEQ ) ? 3'd2 :
                      (op_reg == OP_FLT ) ? 3'd3 :
                                            3'd4;

    fpu_max_min_cpr u_cpr (
        .fs1_data(src1_reg),
        .fs2_data(src2_reg),
        .ctrl    (cpr_ctrl),
        .fd_data (res_cpr)
    );

    // 7.8 浮点转整数
    fpu_ws_wus u_f2i (
        .fs1_data(src1_reg),
        .ctrl    (op_reg == OP_FCVT_WU_S),   // 0:w.s, 1:wu.s
        .rm      (rm_reg),
        .fd_data (res_f2i),
        .fflags  (flg_f2i)
    );

    // 7.9 整数转浮点
    fpu_sw_swu u_i2f (
        .rs1_data(src1_reg),
        .ctrl    (op_reg == OP_FCVT_S_WU),   // 0:s.w, 1:s.wu
        .rm      (rm_reg),
        .fd_data (res_i2f),
        .fflags  (flg_i2f)
    );

    // 7.10 分类
    fpu_fclass u_class (
        .fs1_data(src1_reg),
        .fd_data (res_class)
    );

    // 8. 结果选择器（组合）
    reg [31:0] result_comb;
    reg [4:0]  fflags_comb;

    always @(*) begin
        // 默认：非法操作返回 qNaN，并置 NV
        result_comb = 32'h7FC0_0000;
        fflags_comb = 5'b10000;

        case (op_reg)
            OP_FADD, OP_FSUB: begin
                result_comb = res_add_sub;
                fflags_comb = flg_add_sub;
            end

            OP_FMUL: begin
                result_comb = res_mul;
                fflags_comb = flg_mul;
            end

            OP_FDIV: begin
                result_comb = res_div;
                fflags_comb = flg_div;
            end

            OP_FSQRT: begin
                result_comb = res_sqrt;
                fflags_comb = flg_sqrt;
            end

            OP_FMADD, OP_FMSUB, OP_FNMSUB, OP_FNMADD: begin
                result_comb = res_fmac;
                fflags_comb = flg_fmac;
            end

            OP_FSGNJ, OP_FSGNJN, OP_FSGNJX: begin
                result_comb = res_sgnj;
                fflags_comb = 5'd0;
            end

            OP_FMAX, OP_FMIN, OP_FEQ, OP_FLT, OP_FLE: begin
                result_comb = res_cpr;
                fflags_comb = 5'd0;   // 若你的比较模块后续补异常，再替换这里
            end

            OP_FCVT_W_S, OP_FCVT_WU_S: begin
                result_comb = res_f2i;
                fflags_comb = flg_f2i;
            end

            OP_FCVT_S_W, OP_FCVT_S_WU: begin
                result_comb = res_i2f;
                fflags_comb = flg_i2f;
            end

            OP_FCLASS: begin
                result_comb = res_class;
                fflags_comb = 5'd0;
            end

            default: begin
                result_comb = 32'h7FC0_0000;
                fflags_comb = 5'b10000;
            end
        endcase
    end

    // 9. 输出寄存器
    //    在 ST_DONE 时锁存结果并拉高 o_valid 一个周期
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            o_valid  <= 1'b0;
            o_result <= 32'd0;
            o_fflags <= 5'd0;
        end else begin
            if (next_state == ST_DONE) begin
                o_valid  <= 1'b1;
                o_result <= result_comb;
                o_fflags <= fflags_comb;
            end else begin
                o_valid  <= 1'b0;
                o_result <= o_result;
                o_fflags <= o_fflags;
            end
        end
    end

endmodule
