module Risc_v_top(
	input clk,
	input rst,
	input [31:0]instr,
	input [31:0]data_dm_to_reg,//load指令时 从mem中输入的数据
	output [7:0]addr_to_im,
	output [31:0]addr_to_dm,
	output [31:0]data_reg_to_dm,
	output [2:0]RW_type,
	output MemWrite,
	output Memread
);
	wire [31:0]pc_if_i;
	wire [31:0]pc_if_o;
	
	wire [31:0]pc_if_id_o;
	wire [31:0]instr_if_id_o;
	
	wire [31:0]Wr_Data_id_i;
	wire [31:0]imme_id_o;
	wire [31:0]Rs1_Data_id_o;
	wire [31:0]Rs2_Data_id_o;
	
	wire [4:0]Rd_id_o;
	wire Memread_id_o; //数据存储器读使能
	wire MemtoReg_id_o; //MemtoReg 为1时选择data_dm_to_reg,即数据存储器的数据，即load指令时
	wire MemWrite_id_o;
	wire ALUsrc_id_o;
	wire RegWrite_id_o;
	wire lui_id_o;
	wire U_type_id_o;
	wire jal_id_o;
	wire jalr_id_o;
	wire beq_id_o;
	wire bne_id_o;
	wire blt_id_o;
	wire bge_id_o;
	wire bltu_id_o;
	wire bgeu_id_o;
	wire [2:0]RW_type_id_o;
	wire [4:0]ALU_Ctrl_id_o;
	
	wire [4:0]Rd_id_ex_o;
	wire MemtoReg_id_ex_o; //MemtoReg 为1时选择data_dm_to_reg,即数据存储器的数据，即load指令时
	wire ALUsrc_id_ex_o;
	wire RegWrite_id_ex_o;
	wire lui_id_ex_o;
	wire U_type_id_ex_o;
	wire jal_id_ex_o;
	wire jalr_id_ex_o;
	wire beq_id_ex_o;
	wire bne_id_ex_o;
	wire blt_id_ex_o;
	wire bge_id_ex_o;
	wire bltu_id_ex_o;
	wire bgeu_id_ex_o;
	wire [4:0]ALU_Ctrl_id_ex_o;
	
	wire [31:0]pc_id_ex_o;
	wire [31:0]imme_id_ex_o;
	wire [31:0]Rs1_Data_id_ex_o;
	wire [31:0]Rs2_Data_id_ex_o;
	
	wire [31:0]pc_order_if_o;
	wire jump_flag;
	
	//浮点指令新增
	wire fp_we_Write_id_ex_o;
	wire [31:0]WB_FPR_Data;
	wire [31:0]rdata1_id_o;
	wire [31:0]rdata2_id_o;
	wire [31:0]rdata3_id_o;
	wire [2:0]rm_id_o;
	wire FpMemRead_id_o;
	wire FpMemWrite_id_o;
	wire FCVT_S_W_WU_id_o;
	wire [4:0]FpuOpType_id_o;
	wire FMV_W_X_id_o;
	wire FP_Res_to_GPR_id_o;
	wire FMV_X_W_id_o;
	wire fp_we_Write_id_o;
	
	wire [31:0]rdata1_id_ex_o;
	wire [31:0]rdata2_id_ex_o;
	wire [31:0]rdata3_id_ex_o;
	wire [2:0]rm_id_ex_o;
	wire FpMemRead_id_ex_o;
	wire FpMemWrite_id_ex_o;
	wire FCVT_S_W_WU_id_ex_o;
	wire [4:0]FpuOpType_id_ex_o;
	wire FMV_W_X_id_ex_o;
	wire FP_Res_to_GPR_id_ex_o;
	wire FMV_X_W_id_ex_o;
	wire FpuEn_id_o;
	wire FpuEn_id_ex_o;
	wire stall_ex_o;
	
	if_stage if_stage_inst(
		.clk(clk),
		.rst(rst),
		.pc_if_i(pc_if_i),
		.pc_if_o(pc_if_o),
		.pc_order_if_o(pc_order_if_o), //////////////////////// 更新PC要输出IF阶段的PC+4到EX里面选择出来再输回来
		.rom_addr(addr_to_im),
		.stall_i(stall_ex_o)
	);
	
	if_id_regs if_id_regs_inst(
		.clk(clk),
		.rst(rst),
		.jump_flag(jump_flag), ///////////////控制冒险，冲刷标志位
		
		.pc_if_id_i(pc_if_o),
		.instr_if_id_i(instr),
		.pc_if_id_o(pc_if_id_o),
		.instr_if_id_o(instr_if_id_o),
		.stall_i(stall_ex_o)
	);
	
	wire fpu_done_ex;
	wire RegWrite_wb;

	assign fpu_done_ex = FpuEn_id_ex_o & ~stall_ex_o;

	// 只有“FPU结果写回GPR”需要等 done，其余整数/搬运类可以直接写
	assign RegWrite_wb = RegWrite_id_ex_o & (~FP_Res_to_GPR_id_ex_o | fpu_done_ex);
	
	wire fp_we_wb;

	assign fp_we_wb = fp_we_Write_id_ex_o & (~FpuEn_id_ex_o | fpu_done_ex);
	
	id_stage  id_stage_inst(
		.clk(clk),
		.rst(rst),
		.RegWrite_id_i(RegWrite_wb),
		.Wr_Data_id_i(Wr_Data_id_i),
		.instr_id_i(instr_if_id_o),
		.Rd_id_i(Rd_id_ex_o),
		
		.imme_id_o(imme_id_o),
		.Rs1_Data_id_o(Rs1_Data_id_o),
		.Rs2_Data_id_o(Rs2_Data_id_o),
		.Rd_id_o(Rd_id_o),
		
		.Memread_id_o(Memread_id_o), //数据存储器读使能
		.MemtoReg_id_o(MemtoReg_id_o), //MemtoReg 为1时选择data_dm_to_reg,即数据存储器的数据，即load指令时
		.MemWrite_id_o(MemWrite_id_o),
		.ALUsrc_id_o(ALUsrc_id_o),
		.RegWrite_id_o(RegWrite_id_o),
		.lui_id_o(lui_id_o),
		.U_type_id_o(U_type_id_o),
		.jal_id_o(jal_id_o),
		.jalr_id_o(jalr_id_o),
		.beq_id_o(beq_id_o),
		.bne_id_o(bne_id_o),
		.blt_id_o(blt_id_o),
		.bge_id_o(bge_id_o),
		.bltu_id_o(bltu_id_o),
		.bgeu_id_o(bgeu_id_o),
		.RW_type_id_o(RW_type_id_o),
		.ALU_Ctrl_id_o(ALU_Ctrl_id_o),
		
		//浮点指令新增
		.fp_we_Write_id_i(fp_we_wb),
		.fp_wdata_id_i(WB_FPR_Data),
		.rdata1_id_o(rdata1_id_o),
		.rdata2_id_o(rdata2_id_o),
		.rdata3_id_o(rdata3_id_o),
		.rm_id_o(rm_id_o),
		
		.FpMemRead_id_o(FpMemRead_id_o),
		.FpMemWrite_id_o(FpMemWrite_id_o),
		.FCVT_S_W_WU_id_o(FCVT_S_W_WU_id_o),
		.FpuOpType_id_o(FpuOpType_id_o),
		.FMV_W_X_id_o(FMV_W_X_id_o),
		.FP_Res_to_GPR_id_o(FP_Res_to_GPR_id_o),
		.FMV_X_W_id_o(FMV_X_W_id_o),
		.fp_we_Write_id_o(fp_we_Write_id_o),
		.FpuEn_id_o(FpuEn_id_o)
	);

	wire Memread_int_ex_o;
	wire MemWrite_int_ex_o;
	
	id_ex_regs id_ex_regs_inst(
		.clk(clk),
		.rst(rst),
		.jump_flag(jump_flag), ///////////////控制冒险，冲刷标志位
		
		.pc_id_ex_i(pc_if_id_o),
		.imme_id_ex_i(imme_id_o),
		.Rs1_Data_id_ex_i(Rs1_Data_id_o),
		.Rs2_Data_id_ex_i(Rs2_Data_id_o),
		.Rd_id_ex_i(Rd_id_o),
		.pc_id_ex_o(pc_id_ex_o),
		.imme_id_ex_o(imme_id_ex_o),
		.Rs1_Data_id_ex_o(Rs1_Data_id_ex_o),
		.Rs2_Data_id_ex_o(Rs2_Data_id_ex_o),
		.Rd_id_ex_o(Rd_id_ex_o),
		
		.Memread_id_ex_i(Memread_id_o), //数据存储器读使能
		.MemtoReg_id_ex_i(MemtoReg_id_o), //MemtoReg 为1时选择data_dm_to_reg,即数据存储器的数据，即load指令时
		.MemWrite_id_ex_i(MemWrite_id_o),
		.ALUsrc_id_ex_i(ALUsrc_id_o),
		.RegWrite_id_ex_i(RegWrite_id_o),
		.lui_id_ex_i(lui_id_o),
		.U_type_id_ex_i(U_type_id_o),
		.jal_id_ex_i(jal_id_o),
		.jalr_id_ex_i(jalr_id_o),
		.beq_id_ex_i(beq_id_o),
		.bne_id_ex_i(bne_id_o),
		.blt_id_ex_i(blt_id_o),
		.bge_id_ex_i(bge_id_o),
		.bltu_id_ex_i(bltu_id_o),
		.bgeu_id_ex_i(bgeu_id_o),
		.RW_type_id_ex_i(RW_type_id_o),
		.ALU_Ctrl_id_ex_i(ALU_Ctrl_id_o),
		
		.Memread_id_ex_o(Memread_int_ex_o), //数据存储器读使能,改了
		.MemtoReg_id_ex_o(MemtoReg_id_ex_o), //MemtoReg 为1时选择data_dm_to_reg,即数据存储器的数据，即load指令时
		.MemWrite_id_ex_o(MemWrite_int_ex_o),//也要改，改了
		.ALUsrc_id_ex_o(ALUsrc_id_ex_o),
		.RegWrite_id_ex_o(RegWrite_id_ex_o),
		.lui_id_ex_o(lui_id_ex_o),
		.U_type_id_ex_o(U_type_id_ex_o),
		.jal_id_ex_o(jal_id_ex_o),
		.jalr_id_ex_o(jalr_id_ex_o),
		.beq_id_ex_o(beq_id_ex_o),
		.bne_id_ex_o(bne_id_ex_o),
		.blt_id_ex_o(blt_id_ex_o),
		.bge_id_ex_o(bge_id_ex_o),
		.bltu_id_ex_o(bltu_id_ex_o),
		.bgeu_id_ex_o(bgeu_id_ex_o),
		.RW_type_id_ex_o(RW_type),
		.ALU_Ctrl_id_ex_o(ALU_Ctrl_id_ex_o),
		
		//浮点指令新增	
		.FpMemRead_id_ex_i(FpMemRead_id_o),
		.FpMemRead_id_ex_o(FpMemRead_id_ex_o),
		.FpMemWrite_id_ex_i(FpMemWrite_id_o),
		.FpMemWrite_id_ex_o(FpMemWrite_id_ex_o),
		
		.rdata1_id_ex_i(rdata1_id_o),
		.rdata2_id_ex_i(rdata2_id_o),
		.rdata3_id_ex_i(rdata3_id_o),
		.rm_id_ex_i(rm_id_o),
		
		.rdata1_id_ex_o(rdata1_id_ex_o),
		.rdata2_id_ex_o(rdata2_id_ex_o),
		.rdata3_id_ex_o(rdata3_id_ex_o),
		.rm_id_ex_o(rm_id_ex_o),
		
		.FCVT_S_W_WU_id_ex_i(FCVT_S_W_WU_id_o),
		.FCVT_S_W_WU_id_ex_o(FCVT_S_W_WU_id_ex_o),
		.FpuOpType_id_ex_i(FpuOpType_id_o),
		.FpuOpType_id_ex_o(FpuOpType_id_ex_o),
		.FMV_W_X_id_ex_i(FMV_W_X_id_o),
		.FMV_W_X_id_ex_o(FMV_W_X_id_ex_o),
		.FP_Res_to_GPR_id_ex_i(FP_Res_to_GPR_id_o),
		.FMV_X_W_id_ex_i(FMV_X_W_id_o),
		.FP_Res_to_GPR_id_ex_o(FP_Res_to_GPR_id_ex_o),
		.FMV_X_W_id_ex_o(FMV_X_W_id_ex_o),
		.fp_we_Write_id_ex_i(fp_we_Write_id_o),
		.fp_we_Write_id_ex_o(fp_we_Write_id_ex_o),
		.FpuEn_id_ex_i(FpuEn_id_o),
		.FpuEn_id_ex_o(FpuEn_id_ex_o),
		.stall_i(stall_ex_o)
	);
	
	//这样 flw/fsw 才真的能访存
	assign Memread  = Memread_int_ex_o  | FpMemRead_id_ex_o;
	assign MemWrite = MemWrite_int_ex_o | FpMemWrite_id_ex_o;
	
	ex_stage  ex_stage_inst(
		
		.ALU_Ctrl_ex_i(ALU_Ctrl_id_ex_o),
		.MemtoReg_ex_i(MemtoReg_id_ex_o),
		.Memread_ex_i(Memread_int_ex_o),
		.MemWrite_ex_i(MemWrite_int_ex_o),
		.beq_ex_i(beq_id_ex_o),
		.bne_ex_i(bne_id_ex_o),
		.blt_ex_i(blt_id_ex_o),
		.bge_ex_i(bge_id_ex_o),
		.bltu_ex_i(bltu_id_ex_o),
		.bgeu_ex_i(bgeu_id_ex_o),
		.jal_ex_i(jal_id_ex_o),
		.jalr_ex_i(jalr_id_ex_o),
		.lui_ex_i(lui_id_ex_o),
		.U_type_ex_i(U_type_id_ex_o),
		.ALUsrc_ex_i(ALUsrc_id_ex_o),
		.pc_order_ex_i(pc_order_if_o),////////////更新PC要输出IF阶段的PC+4到EX里面选择出来再输回来
		.data_dm_to_reg_ex_i(data_dm_to_reg),
		.pc_ex_i(pc_id_ex_o),
		.imme_ex_i(imme_id_ex_o),
		.Rs1_Data_ex_i(Rs1_Data_id_ex_o),
		.Rs2_Data_ex_i(Rs2_Data_id_ex_o),
		.addr_to_dm_ex_o(addr_to_dm),
		.pc_new_ex_o(pc_if_i),
		.data_reg_to_dm_ex_o(data_reg_to_dm), //store 指令需要存储RS2数据
		.Wb_Data_ex_o(Wr_Data_id_i),
		.jump_order_flag(jump_flag), ///////////////控制冒险，冲刷标志位
		
		//浮点指令新增
		.WB_FPR_Data(WB_FPR_Data),
		.FpMemRead_ex_i(FpMemRead_id_ex_o),
		.FpMemWrite_ex_i(FpMemWrite_id_ex_o),
		.FCVT_S_W_WU_ex_i(FCVT_S_W_WU_id_ex_o),
		.clk(clk),
		.rst(rst),
		.FpuOpType_ex_i(FpuOpType_id_ex_o),
		.rdata1_ex_i(rdata1_id_ex_o),
		.rdata2_ex_i(rdata2_id_ex_o),
		.rdata3_ex_i(rdata3_id_ex_o),
		.rm_ex_i(rm_id_ex_o),
		.FMV_W_X_ex_i(FMV_W_X_id_ex_o),
		.FP_Res_to_GPR_ex_i(FP_Res_to_GPR_id_ex_o),
		.FMV_X_W_ex_i(FMV_X_W_id_ex_o),
		.FpuEn_ex_i(FpuEn_id_ex_o),
		.stall_ex_o(stall_ex_o)
	);
	
endmodule

