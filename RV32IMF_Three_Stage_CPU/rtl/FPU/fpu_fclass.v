module fpu_fclass (
    input  [31:0] fs1_data,  // 输入操作数（32位单精度浮点）
    output reg [31:0] fd_data // 输出结果（32位整数：低10位为fclass独热码，高22位为0）
);

// -------------------------- 步骤1：解析浮点字段 --------------------------
	wire sign = fs1_data[31];                // 符号位：1=负，0=正
	wire [7:0] exp = fs1_data[30:23];        // 8位指数位
	wire [22:0] frac = fs1_data[22:0];       // 23位尾数位
	wire frac_msb = frac[22];                // 尾数最高位（区分SNaN/QNaN）
	wire frac_rest_nonzero = (frac[21:0] != 21'h000000); // 尾数除最高位外非0

// -------------------------- 步骤2：检测各类浮点类型 --------------------------
// 基础类型检测
	wire is_zero     = (exp == 8'h00) && (frac == 23'h000000); // ±0
	wire is_subnormal = (exp == 8'h00) && (frac != 23'h000000); // ±subnormal (非正规数)
	wire is_normal   = (exp != 8'h00) && (exp != 8'hFF);       // ±normal (正规数)
	wire is_inf      = (exp == 8'hFF) && (frac == 23'h000000); // ±Inf
	wire is_nan      = (exp == 8'hFF) && (frac != 23'h000000); // NaN（SNaN/QNaN）

// NaN细分：SNaN/QNaN
	wire is_snan     = is_nan && (frac_msb == 1'b0) && frac_rest_nonzero;
	wire is_qnan     = is_nan && (frac_msb == 1'b1);

// 符号细分：正/负类型
	wire is_neg_inf      = is_inf && (sign == 1'b1);
	wire is_neg_normal   = is_normal && (sign == 1'b1);
	wire is_neg_subnormal = is_subnormal && (sign == 1'b1);
	wire is_neg_zero     = is_zero && (sign == 1'b1);
	wire is_pos_zero     = is_zero && (sign == 1'b0);
	wire is_pos_subnormal = is_subnormal && (sign == 1'b0);
	wire is_pos_normal   = is_normal && (sign == 1'b0);
	wire is_pos_inf      = is_inf && (sign == 1'b0);

// -------------------------- 步骤3：生成fclass独热码 --------------------------
	always @(*) begin
		 // 初始化：全0（无匹配类型）
		 fd_data = 32'h00000000;

		 // 按优先级匹配（NaN优先级最高，±0最低）
		 case (1'b1)
			  is_snan:          fd_data = 32'h00000100; // bit8=1 (SNaN)
			  is_qnan:          fd_data = 32'h00000200; // bit9=1 (QNaN)
			  is_neg_inf:       fd_data = 32'h00000001; // bit0=1 (-∞)
			  is_pos_inf:       fd_data = 32'h00000080; // bit7=1 (+∞)
			  is_neg_normal:    fd_data = 32'h00000002; // bit1=1 (-normal)
			  is_pos_normal:    fd_data = 32'h00000040; // bit6=1 (+normal)
			  is_neg_subnormal: fd_data = 32'h00000004; // bit2=1 (-subnormal)
			  is_pos_subnormal: fd_data = 32'h00000020; // bit5=1 (+subnormal)
			  is_neg_zero:      fd_data = 32'h00000008; // bit3=1 (-0)
			  is_pos_zero:      fd_data = 32'h00000010; // bit4=1 (+0)
			  default:          fd_data = 32'h00000000; // 无匹配（理论上不会触发）
		 endcase
	end

endmodule
