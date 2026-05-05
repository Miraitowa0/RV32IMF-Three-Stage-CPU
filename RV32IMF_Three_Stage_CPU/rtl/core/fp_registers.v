module fp_registers (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        we,
    input  wire [4:0]  waddr,
    input  wire [31:0] wdata,

    input  wire [4:0]  raddr1,
    input  wire [4:0]  raddr2,
    input  wire [4:0]  raddr3,

    output wire [31:0] rdata1,
    output wire [31:0] rdata2,
    output wire [31:0] rdata3
);

    reg [31:0] fregs [31:0];
	 
/////////////仿真测试所需代码//////////////	
// synthesis translate_off
	initial begin 
    // 读取初始化文件，赋值给fregs（对应索引0~31）
    // 格式：$readmemh("文件路径", 数组名, 起始索引, 结束索引)
    $readmemh("E:/RISCV_Prj/RV32IMF_CPU/fregs_init.txt", fregs, 0, 31);
    
    // 可选：调试打印，验证读取结果
    $display("fregs[0] = %h", fregs[0]); // 预期输出：00000000
    $display("fregs[1] = %h", fregs[1]); // 预期输出：AABBCCDD
	 $display("fregs[2] = %h", fregs[2]); // 预期输出：00112233
	 $display("fregs[3] = %h", fregs[3]); // 预期输出：11335577
	 $display("fregs[4] = %h", fregs[4]); // 预期输出：FFFF0000
end	 
// synthesis translate_on

    always @(negedge clk or negedge rst_n) begin : fp_reg_update
        integer i; // 将变量 i 声明在命名的 begin 块内部
        
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1)
                fregs[i] <= 32'd0;
        end
        else if (we) begin
            fregs[waddr] <= wdata;
        end
    end

    assign rdata1 = fregs[raddr1];
    assign rdata2 = fregs[raddr2];
    assign rdata3 = fregs[raddr3];

endmodule
