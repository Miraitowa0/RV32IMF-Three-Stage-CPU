module fpu_mul (
    input  wire [31:0] fs1_data,  // 操作数 1
    input  wire [31:0] fs2_data,  // 操作数 2
    input  wire [2:0]  rm,        // 舍入模式 (默认 RNE: 3'b000)
    output reg  [31:0] fd_data,   // 乘法结果
    output wire [4:0]  fflags     // 异常标志位 (毕设简化，全0)
);

    assign fflags = 5'b00000;

    // 1. 浮点数解包 & 特殊值检测 (Unpack)
    wire        sign1 = fs1_data[31];
    wire [7:0]  exp1  = fs1_data[30:23];
    wire [22:0] frac1 = fs1_data[22:0];
    wire is_zero1 = (exp1 == 8'd0); // 包含 ±0 和 Subnormal (FTZ策略)
    wire is_inf1  = (exp1 == 8'hFF) && (frac1 == 23'd0);
    wire is_nan1  = (exp1 == 8'hFF) && (frac1 != 23'd0);

    wire        sign2 = fs2_data[31];
    wire [7:0]  exp2  = fs2_data[30:23];
    wire [22:0] frac2 = fs2_data[22:0];
    wire is_zero2 = (exp2 == 8'd0);
    wire is_inf2  = (exp2 == 8'hFF) && (frac2 == 23'd0);
    wire is_nan2  = (exp2 == 8'hFF) && (frac2 != 23'd0);

    // 2. 符号异或 & 真实指数相加
    // 乘法结果符号是两符号位异或
    wire final_sign = sign1 ^ sign2;
    
    // 采用 11 位有符号数防止相加时溢出
    wire signed [10:0] true_exp1 = {3'b0, exp1} - 11'd127;
    wire signed [10:0] true_exp2 = {3'b0, exp2} - 11'd127;
    wire signed [10:0] true_exp_res = true_exp1 + true_exp2;

    // 3. 24位 x 24位 尾数无符号乘法
    // 补全隐藏的 '1'
    wire [23:0] mant1 = {1'b1, frac1};
    wire [23:0] mant2 = {1'b1, frac2};
    
    // 24bit * 24bit = 48bit 乘积
    wire [47:0] prod = mant1 * mant2;

    // 4. 规格化 
    // 1.xx * 1.xx 的结果范围是 [1.00, 3.99)
    // 如果结果 >= 2.0，最高位会在 prod[47]，需要右移 1 位，指数 + 1
    // 如果结果 < 2.0， 最高位会在 prod[46]，无需移位
    wire norm_shift = prod[47];
    
    // 提取 23 位有效尾数
    wire [22:0] norm_frac = norm_shift ? prod[46:24] : prod[45:23];
    
    // 提取舍入保护位 (Guard, Round, Sticky)
    wire G = norm_shift ? prod[23] : prod[22];
    wire R = norm_shift ? prod[22] : prod[21];
    wire S = norm_shift ? (|prod[21:0]) : (|prod[20:0]); // 剩下的位只要有1就是1

    // 5. 舍入逻辑 (Rounding - RNE)
    reg round_up;
    always @(*) begin
        case(rm)
            3'b000: round_up = G & (R | S | norm_frac[0]); // RNE: 最近偶数
            3'b001: round_up = 1'b0;                       // RTZ: 截断
            3'b010: round_up = final_sign & (G | R | S);   // RDN: 向下
            3'b011: round_up = ~final_sign & (G | R | S);  // RUP: 向上
            3'b100: round_up = G;                          // RMM: 四舍五入
            default: round_up = G & (R | S | norm_frac[0]);
        endcase
    end

    // 加上进位。注意：如果 norm_frac 全是 1，加 1 会溢出到第 24 位！
    wire [23:0] rounded_frac_ext = {1'b0, norm_frac} + round_up;
    wire round_ovf = rounded_frac_ext[23]; 
    
    // 如果舍入发生溢出，尾数清零，指数需要再加 1
    wire [22:0] final_frac = round_ovf ? 23'd0 : rounded_frac_ext[22:0];

    // 6. 最终指数计算 & 边界异常判定
    wire signed [10:0] final_true_exp = true_exp_res + norm_shift + round_ovf;
    wire signed [10:0] final_exp_biased = final_true_exp + 11'd127;

    // 异常规范 1：0 乘以 Inf 等于 NaN (Invalid Operation)
    wire invalid_op = (is_zero1 & is_inf2) | (is_inf1 & is_zero2);
    // 异常规范 2：只要有 NaN 参与，或者触发无效运算，结果必定为 NaN
    wire any_nan = is_nan1 | is_nan2 | invalid_op;

    always @(*) begin
        if (any_nan) begin
            // RISC-V 规定 FMUL 遇到 NaN 直接输出标准 NaN (不同于 FMAX 的传播机制)
            fd_data = 32'h7FC00000; 
        end else if (is_zero1 | is_zero2) begin
            // 任意一方为 0，结果为 0 (保留符号)
            fd_data = {final_sign, 31'd0}; 
        end else if (is_inf1 | is_inf2 | (final_exp_biased >= 255)) begin
            // 任意一方为 Inf，或者结果上溢出，结果为 Inf (保留符号)
            fd_data = {final_sign, 8'hFF, 23'd0}; 
        end else if (final_exp_biased <= 0) begin
            // 结果下溢出，触发 FTZ (Flush to Zero) 变为 0
            fd_data = {final_sign, 31'd0}; 
        end else begin
            // 正常数值拼接
            fd_data = {final_sign, final_exp_biased[7:0], final_frac};
        end
    end

endmodule
