module fpu_fmac (
    input  wire [31:0] fs1_data, // 操作数 rs1
    input  wire [31:0] fs2_data, // 操作数 rs2
    input  wire [31:0] fs3_data, // 操作数 rs3
    input  wire [1:0]  ctrl,     // 指令控制: 00=fmadd, 01=fmsub, 10=fnmsub, 11=fnmadd
    input  wire [2:0]  rm,       // 舍入模式
    output wire [31:0] fd_data,  // 最终结果
    output wire [4:0]  fflags    // 异常标志位
);

    // 1. 符号反转逻辑 (Instruction Folding)
    // ctrl[1] 控制是否翻转乘积的符号 (fnmsub, fnmadd)
    // ctrl[0] 控制是否翻转加数 rs3 的符号 (fmsub, fnmadd)
    
    wire inv_mul = ctrl[1]; 
    wire inv_add = ctrl[0]; 

    // 对 rs1 翻转符号，等效于翻转整个乘积的符号
    wire [31:0] mul_op1 = {fs1_data[31] ^ inv_mul, fs1_data[30:0]};
    wire [31:0] mul_op2 = fs2_data;
    // 对 rs3 翻转符号，等效于将减法转化为加法
    wire [31:0] add_op2 = {fs3_data[31] ^ inv_add, fs3_data[30:0]};

    // 2. 例化：浮点乘法器 (Stage 1)
    wire [31:0] mul_result;
    wire [4:0]  mul_flags;
    
    fpu_mul u_mul (
        .fs1_data (mul_op1),
        .fs2_data (mul_op2),
        .rm       (rm),
        .fd_data  (mul_result),
        .fflags   (mul_flags)
    );

    // 3. 例化：浮点加法器 (Stage 2)
    wire [31:0] add_result;
    wire [4:0]  add_flags;
    
    // 注意：这里的 ctrl 固定给 1'b0 (fadd.s)
    // 因为所有的减法都在第一步通过反转 add_op2 的符号转化为加法了！
    fpu_add_sub u_add (
        .fs1_data (mul_result),
        .fs2_data (add_op2),
        .ctrl     (1'b0),     
        .rm       (rm),
        .fd_data  (add_result),
        .fflags   (add_flags)
    );

    // 4. 结果与异常汇总
    assign fd_data = add_result;
    assign fflags  = mul_flags | add_flags;

endmodule
