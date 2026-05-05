module fpu_ws_wus (
    input  wire [31:0] fs1_data,  // 输入单精度浮点数
    input  wire        ctrl,      // 0: fcvt.w.s (有符号), 1: fcvt.wu.s (无符号)
    input  wire [2:0]  rm,        // 舍入模式 (默认 RNE: 3'b000)
    output reg  [31:0] fd_data,   // 输出 32 位整数
    output wire [4:0]  fflags     // 异常标志位 (毕设中直接置0)
);

    // ==========================================
    // 0. 简化：禁用异常输出，节省逻辑
    // ==========================================
    // RISC-V 规定超出范围触发 NV(bit 4)，但毕设中无 fcsr，直接全 0 即可。
    assign fflags = 5'b00000; 

    // ==========================================
    // 1. 浮点数解包 (Unpack)
    // ==========================================
    wire        sign = fs1_data[31];
    wire [7:0]  exp  = fs1_data[30:23];
    wire [22:0] frac = fs1_data[22:0];

    // 特殊值判断
    wire is_zero    = (exp == 8'd0);// 包含 ±0 和 Subnormal (FTZ策略)
    wire is_nan_inf = (exp == 8'hFF);
    wire is_nan     = is_nan_inf && (frac != 23'd0);

    // 计算真实的指数 (True Exponent)
    // 采用 10 位有符号数防止计算越界
    wire signed [9:0] true_exp = {2'b0, exp} - 10'd127;

    // ==========================================
    // 2. 核心：绝对值对齐移位 (Alignment)
    // ==========================================
    // 我们需要提取整数部分和判断舍入的 G, R, S 位。
    // 使用一个 56 位的移位寄存器，将小数定点化。
    wire [55:0] base_frac = {1'b1, frac, 32'b0}; 
    wire signed [9:0] exp_diff = 10'd31 - true_exp;
    
    reg [32:0] int_mag; // 整数绝对值 (33位防止无符号数溢出检测)
    reg G_bit, R_bit, S_bit; // 舍入保护位
    reg [55:0] aligned_frac;
	 
    always @(*) begin
        // 默认初始化
        int_mag = 33'd0; 
        G_bit = 0; R_bit = 0; S_bit = 0;
        aligned_frac = 56'd0;
		  
        if (is_zero) begin
            // 0 值直接全 0
        end else if (true_exp > 10'd32) begin
            // 指数极大，绝对超出 32 位整数范围，强制设为溢出态
            int_mag = 33'h1_0000_0000; 
        end else if (true_exp >= 10'd0) begin
            // 正常范围 (0 <= true_exp <= 31)
            // 将浮点尾数向右平移，提取出整数和舍入位
            aligned_frac = base_frac >> exp_diff;
            int_mag = {1'b0, aligned_frac[55:24]}; // 高 32 位是整数部分
            G_bit   = aligned_frac[23];            // 小数点后第 1 位
            R_bit   = aligned_frac[22];            // 小数点后第 2 位
            S_bit   = (aligned_frac[21:0] != 22'd0); // 剩余所有位求或
        end else if (true_exp == -10'd1) begin
            // 值在 0.5 ~ 0.999 之间，整数部分为 0
            int_mag = 33'd0;
            G_bit   = 1'b1;  // 隐藏的 '1' 变成了 0.5
            R_bit   = frac[22];
            S_bit   = (frac[21:0] != 22'd0);
        end else begin
            // 值 < 0.5
            int_mag = 33'd0;
            G_bit   = 1'b0;
            R_bit   = 1'b0;
            S_bit   = 1'b1;  // 只要不是 0，后面肯定有有效数字
        end
    end

    // ==========================================
    // 3. 舍入逻辑 (Rounding) - 仅针对绝对值
    // ==========================================
    reg round_up;
    always @(*) begin
        case (rm)
            3'b000: round_up = G_bit & (R_bit | S_bit | int_mag[0]); // RNE: 最近偶数
            3'b001: round_up = 1'b0;                                 // RTZ: 直接截断
            3'b010: round_up = sign & (G_bit | R_bit | S_bit);       // RDN: 向下舍入
            3'b011: round_up = ~sign & (G_bit | R_bit | S_bit);      // RUP: 向上舍入
            3'b100: round_up = G_bit;                                // RMM: 四舍五入
            default: round_up = G_bit & (R_bit | S_bit | int_mag[0]);
        endcase
    end
    
    // 得到舍入后的最终绝对值
    wire [32:0] rounded_mag = int_mag + round_up;

    // ==========================================
    // 4. 符号应用与溢出检测 (RISC-V 规范饱和处理)
    // ==========================================
    always @(*) begin
        if (is_nan) begin
            // RISC-V 规范：NaN 转换为目标格式的最大正整数
            fd_data = (ctrl == 1'b0) ? 32'h7FFFFFFF : 32'hFFFFFFFF;
        end 
        else if (ctrl == 1'b0) begin 
            // ----- fcvt.w.s (转换为有符号 32 位整数) -----
            if (sign) begin
                if (rounded_mag > 33'h080000000 || is_nan_inf) begin
                    fd_data = 32'h80000000; // 负数溢出或 -Inf -> -2^31
                end else begin
                    fd_data = ~rounded_mag[31:0] + 1'b1; // 应用负号求补码
                end
            end else begin
                if (rounded_mag > 33'h07FFFFFFF || is_nan_inf) begin
                    fd_data = 32'h7FFFFFFF; // 正数溢出或 +Inf -> 2^31 - 1
                end else begin
                    fd_data = rounded_mag[31:0];
                end
            end
        end 
        else begin 
            // ----- fcvt.wu.s (转换为无符号 32 位整数) -----
            if (sign) begin
                // RISC-V 规范：将负浮点数转为无符号数，结果为 0
                fd_data = 32'h00000000; 
            end else begin
                if (rounded_mag > 33'h0FFFFFFFF || is_nan_inf) begin
                    fd_data = 32'hFFFFFFFF; // 正数溢出或 +Inf -> 2^32 - 1
                end else begin
                    fd_data = rounded_mag[31:0];
                end
            end
        end
    end

endmodule
