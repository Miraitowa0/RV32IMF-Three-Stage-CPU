module fpu_sqrt (
    input  wire [31:0] fs1_data,  // 输入操作数
    input  wire [2:0]  rm,        // 舍入模式 (默认 RNE)
    output reg  [31:0] fd_data,   // 结果输出
    output wire [4:0]  fflags     // 异常标志位
);

    assign fflags = 5'b00000;

    // 1. 解包与异常侦测
    wire        sign = fs1_data[31];
    wire [7:0]  exp  = fs1_data[30:23];
    wire [22:0] frac = fs1_data[22:0];
    
    wire is_zero = (exp == 8'd0);
    wire is_inf  = (exp == 8'hFF) && (frac == 23'd0);
    wire is_nan  = (exp == 8'hFF) && (frac != 23'd0);
    
    // 负数开根号是非法的 (除了 -0.0)
    wire is_invalid = (sign && !is_zero) | is_nan;

    // 指数减半计算
    // 真实指数 = 阶码 - 127
    wire signed [9:0] true_exp = {2'b0, exp} - 10'd127;
    // 指数除以 2 (算术右移自动处理奇偶和负数向下取整)
    wire signed [9:0] root_exp = true_exp >>> 1;

    // 构建 52 位被开方数 
    // 如果 exp[0] == 1 (真实的 exp 是偶数), 尾数范围 [1, 2)，左移 27 位
    // 如果 exp[0] == 0 (真实的 exp 是奇数), 尾数范围 [2, 4)，左移 28 位 (相当于乘 2)
    wire [51:0] radicand = (exp[0] == 1'b1) ? 
                           {1'b0, 1'b1, frac, 27'b0} : 
                           {1'b1, frac, 28'b0};

    // 4. 纯组合逻辑逐位开方算法 (Digit-by-Digit)
    reg [25:0] Q;       // 生成的 26 位根 (1位隐藏位 + 23位尾数 + G + R)
    reg [27:0] Rem;     // 余数寄存器
    reg [27:0] test;    // 试减数
    integer i;

    always @(*) begin
        Q = 26'd0;
        Rem = 28'd0;
        // 循环 26 次，每次生成根的 1 个 bit
        for (i = 25; i >= 0; i = i - 1) begin
            // 余数左移 2 位，并拉入被开方数的下 2 位
            Rem = {Rem[25:0], radicand[i*2+1], radicand[i*2]};
            // 构造试减数: {已计算的Q, 2'b01}
            test = {Q, 2'b01};
            if (Rem >= test) begin
                Rem = Rem - test;      // 够减，更新余数
                Q = {Q[24:0], 1'b1};   // 当前根位上 1
            end else begin
                Q = {Q[24:0], 1'b0};   // 不够减，当前根位上 0
            end
        end
    end

    // 5. 规格化与 GRS 提取
    // 因为我们巧妙地对齐了 radicand，Q[25] 必定永远是 1！天然规格化！
    wire [22:0] norm_frac = Q[24:2];
    wire G = Q[1];
    wire R = Q[0];
    wire S = (Rem != 28'd0); // 只要最后余数不为0，说明后面还有无限小数，Sticky 置 1

    // 6. 舍入逻辑 (Rounding RNE)
    reg round_up;
    always @(*) begin
        case(rm)
            3'b000: round_up = G & (R | S | norm_frac[0]); // RNE
            3'b001: round_up = 1'b0;                       // RTZ
            3'b010: round_up = sign & (G | R | S);         // RDN (几乎用不到，因为结果必正)
            3'b011: round_up = ~sign & (G | R | S);        // RUP
            3'b100: round_up = G;                          // RMM
            default: round_up = G & (R | S | norm_frac[0]);
        endcase
    end

    // 如果 23个1 进位，会导致溢出
    wire [23:0] rounded_frac_ext = {1'b0, norm_frac} + round_up;
    wire round_ovf = rounded_frac_ext[23]; 
    wire [22:0] final_frac = round_ovf ? 23'd0 : rounded_frac_ext[22:0];

    // 计算最终指数 (带偏置 127)
    wire signed [9:0] final_exp_biased = root_exp + 10'd127 + round_ovf;

    // 7. 异常拦截与最终输出
    always @(*) begin
        if (is_invalid) begin
            fd_data = 32'h7FC00000; // 负数(非0)或NaN开方 -> 标准NaN
        end else if (is_zero) begin
            fd_data = {sign, 31'd0}; // ±0 开方 -> ±0
        end else if (is_inf && !sign) begin
            fd_data = 32'h7F800000;  // +Inf 开方 -> +Inf
        end else begin
            // 正常输出 (平方根结果永远为正)
            fd_data = {1'b0, final_exp_biased[7:0], final_frac};
        end
    end

endmodule
