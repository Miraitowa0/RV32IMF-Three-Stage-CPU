module fpu_add_sub (
    input  wire [31:0] fs1_data,  // 操作数 A
    input  wire [31:0] fs2_data,  // 操作数 B
    input  wire        ctrl,      // 0: fadd.s, 1: fsub.s
    input  wire [2:0]  rm,        // 舍入模式 (默认 RNE: 3'b000)
    output reg  [31:0] fd_data,   // 结果输出
    output wire [4:0]  fflags     // 异常标志位 (静态舍入简化为全0)
);

    assign fflags = 5'b00000;

    // 1. 预处理与减法转加法
    // 如果是 fsub.s，强行翻转 B 的符号位，转化为 A + (-B)
    wire [31:0] op_b = ctrl ? {~fs2_data[31], fs2_data[30:0]} : fs2_data;
    wire [31:0] op_a = fs1_data;

    wire sign_a = op_a[31];
    wire sign_b = op_b[31];
    wire [7:0] exp_a = op_a[30:23];
    wire [7:0] exp_b = op_b[30:23];
    wire [22:0] frac_a = op_a[22:0];
    wire [22:0] frac_b = op_b[22:0];

    // 特殊值检测 (FTZ 策略：非规格化数当作 0)
    wire a_is_zero = (exp_a == 8'd0);
    wire b_is_zero = (exp_b == 8'd0);
    wire a_is_inf  = (exp_a == 8'hFF) && (frac_a == 23'd0);
    wire b_is_inf  = (exp_b == 8'hFF) && (frac_b == 23'd0);
    wire a_is_nan  = (exp_a == 8'hFF) && (frac_a != 23'd0);
    wire b_is_nan  = (exp_b == 8'hFF) && (frac_b != 23'd0);

    // 2. 绝对值排序 (Sort) - 强行让 大数 = L, 小数 = S
    // 去掉符号位比大小
    wire a_lt_b = (op_a[30:0] < op_b[30:0]);

    wire        sign_L = a_lt_b ? sign_b : sign_a;
    wire [7:0]  exp_L  = a_lt_b ? exp_b  : exp_a;
    wire [22:0] frac_L = a_lt_b ? frac_b : frac_a;
    wire        L_is_zero = a_lt_b ? b_is_zero : a_is_zero;

    wire        sign_S = a_lt_b ? sign_a : sign_b;
    wire [7:0]  exp_S  = a_lt_b ? exp_a  : exp_b;
    wire [22:0] frac_S = a_lt_b ? frac_a : frac_b;
    wire        S_is_zero = a_lt_b ? a_is_zero : b_is_zero;

    // 决定是“真加法”还是“真减法”
    wire eff_sub = (sign_L ^ sign_S);  

    // 3. 对阶移位 (Alignment)
    wire [7:0] exp_diff = exp_L - exp_S;

    // 给小数补充隐藏的 '1'，并在末尾补 0 用于捕捉 G, R, S
    // L_mant: [26]隐藏1, [25:3]尾数, [2:0]补零
    wire [26:0] L_mant = L_is_zero ? 27'd0 : {1'b1, frac_L, 3'b000};
    wire [26:0] S_mant = S_is_zero ? 27'd0 : {1'b1, frac_S, 3'b000};

    // 小数向右平移对阶，最大移位量通常 26 位就够了，用一个宽移位器
    wire [53:0] S_shifted_wide = {S_mant, 27'b0} >> exp_diff;
    wire [26:0] S_aligned = S_shifted_wide[53:27];
    
    // 提取被挤出去的位作为额外的粘滞位 (Sticky)
    wire sticky_extra = (|S_shifted_wide[26:0]) | (exp_diff > 27);
    wire [26:0] S_aligned_final = {S_aligned[26:1], S_aligned[0] | sticky_extra};

    // 4. 尾数加减法 (Fraction Add/Sub)
    // 因为 L >= S，所以 L_mant - S_aligned_final 必定 >= 0，完美避开负数！
    // 扩展到 28 位，[27] 用来装加法可能产生的进位
    wire [27:0] sum_raw = eff_sub ? 
                          ({1'b0, L_mant} - {1'b0, S_aligned_final}) : 
                          ({1'b0, L_mant} + {1'b0, S_aligned_final});

    // 5. 规格化与前导 1 检测 (LOD & Normalization)
    reg [4:0] msb_pos;
    integer i;
    always @(*) begin
        msb_pos = 5'd0;
        // 在 [26:0] 范围内寻找最高位的 1 (优先编码器)
        for (i = 0; i <= 26; i = i + 1) begin
            if (sum_raw[i]) msb_pos = i[4:0];
        end
    end

    wire add_overflow = sum_raw[27]; // 加法产生了进位 (1x.xxx)
    wire [4:0] lzc = 5'd26 - msb_pos; // 减法产生的连续前导零个数

    wire [26:0] norm_mant;
    wire [8:0]  norm_exp; // 9位防止下溢

    assign norm_mant = add_overflow ? sum_raw[27:1] : (sum_raw[26:0] << lzc);
    // 如果加法进位，指数+1；否则指数减去前导零个数
    assign norm_exp  = add_overflow ? ({1'b0, exp_L} + 9'd1) : ({1'b0, exp_L} - {4'b0, lzc});

    // 6. 提取 GRS 与舍入 (Rounding)
    // norm_mant 格式: [26]隐藏1, [25:3]有效尾数, [2]G, [1]R, [0]S
    wire [22:0] frac_trunc = norm_mant[25:3];
    wire G = norm_mant[2];
    wire R = norm_mant[1];
    wire S = norm_mant[0] | (add_overflow & sum_raw[0]); // 如果加法右移了，最末位变成额外的Sticky

    reg round_up;
    always @(*) begin
        case(rm)
            3'b000: round_up = G & (R | S | frac_trunc[0]); // RNE
            3'b001: round_up = 1'b0;                        // RTZ
            3'b010: round_up = sign_L & (G | R | S);        // RDN
            3'b011: round_up = ~sign_L & (G | R | S);       // RUP
            3'b100: round_up = G;                           // RMM
            default: round_up = G & (R | S | frac_trunc[0]);
        endcase
    end

    wire [23:0] rounded_frac_ext = {1'b0, frac_trunc} + round_up;
    wire round_ovf = rounded_frac_ext[23];
    
    wire [22:0] final_frac = round_ovf ? 23'd0 : rounded_frac_ext[22:0];
    wire [8:0]  final_exp  = norm_exp + round_ovf;

    // 7. 特殊情况与结果组装
    wire is_nan_res = a_is_nan | b_is_nan | (a_is_inf & b_is_inf & eff_sub); 
    wire is_inf_res = a_is_inf | b_is_inf;
    wire is_zero_res = (sum_raw == 28'd0); // 彻底相消 (如 1.0 - 1.0)

    always @(*) begin
        if (is_nan_res) begin
            // 遇到 NaN 或 Inf - Inf，返回标准 NaN
            fd_data = 32'h7FC00000;
        end else if (is_inf_res) begin
            // Inf + 常数，返回 Inf (保留大数的符号)
            fd_data = {sign_L, 8'hFF, 23'd0};
        end else if (is_zero_res || final_exp == 0 || final_exp[8]) begin
            // 结果相消为 0，或者下溢出 (FTZ)
            // IEEE 规定除了 RDN 模式外，+0 + -0 等于 +0
            fd_data = (rm == 3'b010) ? 32'h80000000 : 32'h00000000;
        end else if (final_exp >= 255) begin
            // 结果上溢出到无穷大
            fd_data = {sign_L, 8'hFF, 23'd0};
        end else begin
            // 正常输出
            fd_data = {sign_L, final_exp[7:0], final_frac};
        end
    end

endmodule
