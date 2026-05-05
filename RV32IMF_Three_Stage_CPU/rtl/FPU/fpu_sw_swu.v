module fpu_sw_swu (
    input  wire [31:0] rs1_data,  // 输入的 32 位整数
    input  wire        ctrl,      // 0: fcvt.s.w (有符号), 1: fcvt.s.wu (无符号)
    input  wire [2:0]  rm,        // 舍入模式 (默认 RNE: 3'b000)
    output reg  [31:0] fd_data,   // 输出的单精度浮点数
    output wire [4:0]  fflags     // 异常标志位 (毕设简化，全0)
);

    // ==========================================
    // 0. 异常标志位简化
    // ==========================================
    // 整数转浮点永远不会发生上溢/下溢，顶多丢失精度(NX)。毕设直接置 0。
    assign fflags = 5'b00000;

    // ==========================================
    // 1. 提取符号与绝对值 (Magnitude First)
    // ==========================================
    wire is_signed_neg = (ctrl == 1'b0) && rs1_data[31];
    wire final_sign    = is_signed_neg;
    
    // 如果是有符号负数，求补码得到绝对值；否则直接用
    wire [31:0] int_mag = is_signed_neg ? (~rs1_data + 1'b1) : rs1_data;

    // ==========================================
    // 2. 前导 1 检测器 (Leading One Detector, LOD)
    // ==========================================
    // 找出绝对值中最高位的 1 在哪，这是决定浮点数“指数”的关键
    reg [4:0] msb_pos;
    integer i;
    always @(*) begin
        msb_pos = 5'd0;
        // 倒序遍历，找到的第一个 1 就是最高位
        for (i = 0; i <= 31; i = i + 1) begin
            if (int_mag[i]) begin
                msb_pos = i[4:0];
            end
        end
    end

    // ==========================================
    // 3. 规格化左移 (Normalization Shift)
    // ==========================================
    // 将最高位的 1 强行平移到第 31 位。
    // 这样，norm_mag[31] 就是隐藏的 1，[30:8] 就是 23 位尾数，
    // 被挤到低位的 [7:0] 就是用来判断舍入的 G、R、S 位！
    wire [4:0]  shift_amt = 5'd31 - msb_pos;
    wire [31:0] norm_mag  = int_mag << shift_amt;

    wire [22:0] frac_trunc = norm_mag[30:8];           // 截断后的尾数
    wire        G_bit      = norm_mag[7];              // Guard 保护位
    wire        R_bit      = norm_mag[6];              // Round 舍入位
    wire        S_bit      = (norm_mag[5:0] != 6'd0);  // Sticky 粘滞位

    // ==========================================
    // 4. 舍入逻辑 (Rounding)
    // ==========================================
    // 整数只有大于 2^24 时才会发生舍入（低位被截掉）
    reg round_up;
    always @(*) begin
        case (rm)
            3'b000: round_up = G_bit & (R_bit | S_bit | frac_trunc[0]); // RNE
            3'b001: round_up = 1'b0;                                    // RTZ
            3'b010: round_up = final_sign & (G_bit | R_bit | S_bit);    // RDN
            3'b011: round_up = ~final_sign & (G_bit | R_bit | S_bit);   // RUP
            3'b100: round_up = G_bit;                                   // RMM
            default: round_up = G_bit & (R_bit | S_bit | frac_trunc[0]);
        endcase
    end

    // 进位可能会导致尾数溢出 (比如 23个1 再加 1)，所以要补全隐藏的 1 共同做加法
    wire [24:0] mant_rounded = {1'b0, 1'b1, frac_trunc} + round_up;
    wire        mant_ovf     = mant_rounded[24]; // 进位溢出标志

    // 最终提取 23 位尾数：如果溢出了，说明变大了，尾数右移 1 位
    wire [22:0] final_frac   = mant_ovf ? mant_rounded[23:1] : mant_rounded[22:0];

    // ==========================================
    // 5. 组合结果并输出
    // ==========================================
    // IEEE 754 规定单精度指数要加 127 偏移量
    wire [7:0] final_exp = 8'd127 + {3'b000, msb_pos} + mant_ovf;

    always @(*) begin
        if (int_mag == 32'd0) begin
            // 整数为 0 时，浮点数严格输出全 0
            fd_data = 32'h00000000;
        end else begin
            // 拼接：符号位(1) + 指数(8) + 尾数(23)
            fd_data = {final_sign, final_exp, final_frac};
        end
    end

endmodule
