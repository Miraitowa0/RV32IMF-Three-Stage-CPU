
module id_stage(
	input clk,
	input rst,
	input RegWrite_id_i,
	input [31:0] Wr_Data_id_i,
	input [31:0] instr_id_i,
	input [4:0]Rd_id_i,
	output [31:0] imme_id_o,
	output [31:0] Rs1_Data_id_o,
	output [31:0] Rs2_Data_id_o,
	output [4:0]Rd_id_o,
	
	output Memread_id_o, //数据存储器读使能
	output MemtoReg_id_o, //MemtoReg 为1时选择data_dm_to_reg,即数据存储器的数据，即load指令时
	output MemWrite_id_o,
	output ALUsrc_id_o,
	output RegWrite_id_o,
	output lui_id_o,
	output U_type_id_o,
	output jal_id_o,
	output jalr_id_o,
	output beq_id_o,
	output bne_id_o,
	output blt_id_o,
	output bge_id_o,
	output bltu_id_o,
	output bgeu_id_o,
	output [2:0]RW_type_id_o,
	output [4:0]ALU_Ctrl_id_o,
	
	//	浮点指令新增
	input fp_we_Write_id_i,
	input [31:0]fp_wdata_id_i,
	output [31:0]rdata1_id_o,
	output [31:0]rdata2_id_o,
	output [31:0]rdata3_id_o,
	output [2:0]rm_id_o,
	
	output FpMemRead_id_o,
	output FpMemWrite_id_o,
	output FCVT_S_W_WU_id_o,
	output [4:0]FpuOpType_id_o,
	output FMV_W_X_id_o,
	output FP_Res_to_GPR_id_o,
	output FMV_X_W_id_o,
	output fp_we_Write_id_o,
	output FpuEn_id_o
);
	wire [4:0]rs1;
	wire [4:0]rs2;
	wire [4:0]rd;
	wire [6:0] opcode;
	wire [2:0] funct3;
	wire [6:0] funct7;
	//浮点指令新增
	wire [4:0]rs3;
	
	instr_decode instr_decode_inst(
		.instr(instr_id_i),
		.opcode(opcode),
		.rs1(rs1),
		.rs2(rs2),
		.rd(rd),
		.funct3(funct3),
		.funct7(funct7),
		.imme(imme_id_o),
		.rs3(rs3),
		.rm(rm_id_o)
	);
	
	assign Rd_id_o = rd;
	
	registers registers_inst(
		.clk(clk),
		.rst_n(rst),
		.Rs1(rs1),
		.Rs2(rs2),
		.Rd(Rd_id_i),
		.W_en(RegWrite_id_i),
		.Wr_Data(Wr_Data_id_i),
		.Rs1_Data(Rs1_Data_id_o),
		.Rs2_Data(Rs2_Data_id_o)
	);

	fp_registers  fp_registers_inst(
		 .clk(clk),
		 .rst_n(rst),
		 .we(fp_we_Write_id_i),
		 .waddr(Rd_id_i),
		 .wdata(fp_wdata_id_i),

		 .raddr1(rs1),
		 .raddr2(rs2),
		 .raddr3(rs3),

		 .rdata1(rdata1_id_o),
		 .rdata2(rdata2_id_o),
		 .rdata3(rdata3_id_o)
	);
	
	control	control_inst(
		.opcode(opcode),
		.funct3(funct3),
		.funct7(funct7),
		.Memread(Memread_id_o), //数据存储器读使能
		.MemtoReg(MemtoReg_id_o), //MemtoReg 为1时选择data_dm_to_reg,即数据存储器的数据，即load指令时
		.MemWrite(MemWrite_id_o),
		.ALUsrc(ALUsrc_id_o),
		.RegWrite(RegWrite_id_o),
		.lui(lui_id_o),
		.U_type(U_type_id_o),
		.jal(jal_id_o),
		.jalr(jalr_id_o),
		.beq(beq_id_o),
		.bne(bne_id_o),
		.blt(blt_id_o),
		.bge(bge_id_o),
		.bltu(bltu_id_o),
		.bgeu(bgeu_id_o),
		.RW_type(RW_type_id_o),
		.ALU_Ctrl(ALU_Ctrl_id_o),
		
		//浮点指令新增
		.FpMemRead(FpMemRead_id_o),
		.FpMemWrite(FpMemWrite_id_o),
		.FCVT_S_W_WU(FCVT_S_W_WU_id_o),
		.FpuOpType(FpuOpType_id_o),
		.instr_20(rs2[0]),
		.FMV_W_X(FMV_W_X_id_o),
		.FP_Res_to_GPR(FP_Res_to_GPR_id_o),
		.FMV_X_W(FMV_X_W_id_o),
		.fp_we_Write(fp_we_Write_id_o),
		.FpuEn(FpuEn_id_o)
	);
	
endmodule
