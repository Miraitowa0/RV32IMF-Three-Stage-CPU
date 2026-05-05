`include "define.v"
module control(
	input [6:0]opcode,
	input [2:0]funct3,
	input [6:0]funct7,
	output Memread, //数据存储器读使能
	output MemtoReg, //MemtoReg 为1时选择data_dm_to_reg,即数据存储器的数据，即load指令时
	output MemWrite,
	output ALUsrc,
	output RegWrite,
	output lui,
	output U_type,
	output jal,
	output jalr,
	output beq,
	output bne,
	output blt,
	output bge,
	output bltu,
	output bgeu,
	output [2:0]RW_type,
	output [4:0]ALU_Ctrl,
	
	//浮点指令新增
	output FpMemRead, //flw指令读取mem 数据写回fpr
	output FpMemWrite,//fsw指令将fpr里面rs2数据写到mem里面
	output FCVT_S_W_WU,
	output [4:0]FpuOpType,
	input instr_20,
	output FMV_W_X,
	output FP_Res_to_GPR,
	output FMV_X_W,
	output fp_we_Write,
	output FpuEn
);

	wire [1:0]ALUop;
	wire gpr_we;
	
	main_control main_control_inst(
		.opcode(opcode),
		.funct3(funct3),
		.Memread(Memread), //数据存储器读使能
		.ALUop(ALUop),
		.MemtoReg(MemtoReg), //MemtoReg 为1时选择data_dm_to_reg,即数据存储器的数据，即load指令时
		.MemWrite(MemWrite),
		.ALUsrc(ALUsrc),
		.Wen_Reg_Wr(gpr_we),
		.lui(lui),
		.U_type(U_type),
		.jal(jal),
		.jalr(jalr),
		.beq(beq),
		.bne(bne),
		.blt(blt),
		.bge(bge),
		.bltu(bltu),
		.bgeu(bgeu),
		.RW_type(RW_type)
	);
	
	
	//浮点指令新增
	assign FpMemRead = (opcode == `LOAD_FP) ? 1'b1 : 1'b0;
	assign FpMemWrite = (opcode == `STORE_FP) ? 1'b1 : 1'b0;

	//源操作数1除了来自FPR，还可能来自GPR，比如fcvt.s.w(u)指令
	assign FCVT_S_W_WU = (opcode == `OP_FP && funct7 == `Func7_FCVT_S_W) ? 1'b1 : 1'b0;
	//写回fpr数据来源，可能来自FMV 搬运的GPR 数据
	assign FMV_W_X = (opcode == `OP_FP && funct7 == `Func7_FMV_W_X  && funct3 == 3'b000) ? 1'b1 : 1'b0;

	//这几类指令FPU计算结果写回GPR
	wire FCVT_W_WU_S = (opcode == `OP_FP && funct7 == `Func7_FCVT_W_S) ? 1'b1 : 1'b0;
	wire F_CPR = (opcode == `OP_FP && funct7 == `Func7_CPR) ? 1'b1 : 1'b0;
	wire F_CLass = (opcode == `OP_FP && funct7 == `Func7_FCLASS && funct3 == 3'b001) ? 1'b1 : 1'b0;
	
	assign FP_Res_to_GPR = FCVT_W_WU_S | F_CPR | F_CLass;
	
	//搬运指令，将浮点数搬运 写回GPR
	assign FMV_X_W = (opcode == `OP_FP && funct7 == `Func7_FMV_X_W && funct3 == 3'b000) ? 1'b1 : 1'b0;
	
	//写GPR现在是3种情况
	assign RegWrite = gpr_we | FP_Res_to_GPR | FMV_X_W;
	
	
	wire F_ari = (opcode == `OP_FP && 
					 (funct7 == `Func7_FADD 
					 |funct7 == `Func7_FSUB
					 |funct7 == `Func7_FMUL  
					 |funct7 == `Func7_FDIV   
					 |funct7 == `Func7_FSQRT )  
					 ) ? 1'b1 : 1'b0;
					 
	wire F_MIN_MAX = (opcode == `OP_FP && funct7 == `Func7_MIN_MAX ) ? 1'b1 : 1'b0;
	
	wire FMAC = (opcode == `FMADD | opcode == `FMSUB | opcode == `FNMSUB| opcode == `FNMADD) ? 1'b1 : 1'b0;
	
	wire F_SGNJ = (opcode == `OP_FP && funct7 == `Func7_FSGNJ ) ? 1'b1 : 1'b0;
	                        
	//这几类指令写回FPR
	assign fp_we_Write = FpMemRead | F_ari | F_MIN_MAX |
								FMAC | FCVT_S_W_WU | F_SGNJ | FMV_W_X ;
								
	//这几类指令启动FPU运算
	assign FpuEn = F_ari | F_MIN_MAX | FMAC | FCVT_S_W_WU | 
					 FCVT_W_WU_S | F_SGNJ | F_CPR | F_CLass;
	
	FPU_OP_Ctrl  FPU_OP_Ctrl_inst(
		.opcode(opcode),
		.funct3(funct3),
		.funct7(funct7), 
		.instr_20(instr_20),
		.FpuOpType(FpuOpType)
	);
	
	 Alu_Control Alu_Control_inst(
		.opcode(opcode),
		.ALUop(ALUop),
		.funct3(funct3),
		.funct7(funct7),
		.ALUctl(ALU_Ctrl)
	);

endmodule
