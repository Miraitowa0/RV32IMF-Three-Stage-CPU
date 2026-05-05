module fpu_max_min_cpr (
    input  [31:0] fs1_data,  
    input  [31:0] fs2_data,  
    input  [2:0]  ctrl,      // 000:max, 001:min, 010:eq, 011:lt, 100:le
    output reg [31:0] fd_data  
);

// -------------------------- 1. 基础字段与特殊值 --------------------------
    wire fs1_sign = fs1_data[31];
    wire fs2_sign = fs2_data[31];
    
    // 仅需检测 NaN 和 ±0
    wire fs1_is_nan = (fs1_data[30:23] == 8'hFF) && (fs1_data[22:0] != 23'h0);
    wire fs2_is_nan = (fs2_data[30:23] == 8'hFF) && (fs2_data[22:0] != 23'h0);
    wire both_zero  = (fs1_data[30:0] == 31'b0) && (fs2_data[30:0] == 31'b0);

// -------------------------- 2. 核心：浮点比较的魔法逻辑 --------------------------
    // 技巧：去掉符号位后，把低31位当成无符号整数直接比较大小！
    wire mag1_gt_mag2 = (fs1_data[30:0] > fs2_data[30:0]);
    wire mag1_lt_mag2 = (fs1_data[30:0] < fs2_data[30:0]);

    // 针对 FEQ, FLT, FLE 的严格比较 (注意：-0 == +0)
    wire is_eq = (fs1_data[30:0] == fs2_data[30:0]) && (fs1_sign == fs2_sign || both_zero);
    wire is_lt = (fs1_sign != fs2_sign) ? (fs1_sign && !both_zero) : // 异号：负 < 正 (排除两个都是0)
                 (fs1_sign ? mag1_gt_mag2 : mag1_lt_mag2);           // 同号：正数比绝对值，负数反着比

    // 针对 FMAX, FMIN 的比较 (RISC-V 规定对于 max/min 指令，-0.0 严格小于 +0.0)
    wire minmax_lt = (fs1_sign != fs2_sign) ? fs1_sign :             // 这里不排除 both_zero，让 -0 自动小于 +0
                     (fs1_sign ? mag1_gt_mag2 : mag1_lt_mag2);

// -------------------------- 3. 指令结果输出 --------------------------
    always @(*) begin
        fd_data = 32'h0;
        case (ctrl)
            // 1. fmax.s
            3'b000: begin
                if (fs1_is_nan && fs2_is_nan) fd_data = 32'h7FC00000; // 都是 NaN，返回标准 NaN
                else if (fs1_is_nan)          fd_data = fs2_data;     // fs1 是 NaN，返回 fs2
                else if (fs2_is_nan)          fd_data = fs1_data;     // fs2 是 NaN，返回 fs1
                else                          fd_data = minmax_lt ? fs2_data : fs1_data;
            end

            // 2. fmin.s
            3'b001: begin
                if (fs1_is_nan && fs2_is_nan) fd_data = 32'h7FC00000; 
                else if (fs1_is_nan)          fd_data = fs2_data;     
                else if (fs2_is_nan)          fd_data = fs1_data;     
                else                          fd_data = minmax_lt ? fs1_data : fs2_data;
            end

            // 3. feq.s (任何包含 NaN 的比较均为 False)
            3'b010: fd_data = (fs1_is_nan | fs2_is_nan) ? 32'h0 : {31'b0, is_eq};

            // 4. flt.s
            3'b011: fd_data = (fs1_is_nan | fs2_is_nan) ? 32'h0 : {31'b0, is_lt};

            // 5. fle.s
            3'b100: fd_data = (fs1_is_nan | fs2_is_nan) ? 32'h0 : {31'b0, (is_lt | is_eq)};
            
            default: fd_data = 32'h0;
        endcase
    end

endmodule
