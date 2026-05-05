module ex_stage(
	
	input [4:0]ALU_Ctrl_ex_i,
	input Memread_ex_i,
	input MemWrite_ex_i,
	input MemtoReg_ex_i,
	input beq_ex_i,
	input bne_ex_i,
	input blt_ex_i,
	input bge_ex_i,
	input bltu_ex_i,
	input bgeu_ex_i,
	input jal_ex_i,
	input jalr_ex_i,
	input lui_ex_i,
	input U_type_ex_i,
	input ALUsrc_ex_i,
	input [31:0]pc_order_ex_i, ////////////////////////
	input [31:0]data_dm_to_reg_ex_i,
	input [31:0]pc_ex_i,
	input [31:0]imme_ex_i,
	input [31:0]Rs1_Data_ex_i,
	input [31:0]Rs2_Data_ex_i,
	output [31:0]addr_to_dm_ex_o,
	output [31:0]pc_new_ex_o,
	output [31:0]data_reg_to_dm_ex_o, //store 指令需要存储RS2数据
	output [31:0]Wb_Data_ex_o,
	output jump_order_flag,
	
	//浮点指令新增
	output [31:0]WB_FPR_Data,
	input FpMemRead_ex_i,
	input FpMemWrite_ex_i,
	input FCVT_S_W_WU_ex_i,
	input clk,
	input rst,
	input [4:0]FpuOpType_ex_i,
	input [31:0]rdata1_ex_i,
	input [31:0]rdata2_ex_i,
	input [31:0]rdata3_ex_i,
	input [2:0]rm_ex_i,
	input FMV_W_X_ex_i,
	input FP_Res_to_GPR_ex_i,
	input FMV_X_W_ex_i,
	input FpuEn_ex_i,
	output stall_ex_o
);


	wire [31:0]ALU_result;
	wire ALU_zero;
	
	wire [31:0] pc_order; //这个只作为写回reg的PC+4，就是jalr，jal指令的写回PC+4
	wire [31:0]pc_jump; //B，J型跳转指令PC，用于更新PC
	wire [31:0]pc_jump_order;
	wire [31:0]pc_jalr;
	
	wire [31:0]WB_Data;
	wire [31:0]Wr_reg_data2;
	wire [31:0]Wr_reg_data1;
	wire reg_sel;
	
	wire [31:0]alu_data2_temp;
		
	my_mux	alu_data2_my_mux_temp( //ALUsrc 为1时选择Rs2_Data
		.a(imme_ex_i),
		.b(Rs2_Data_ex_i),
		.sel(ALUsrc_ex_i),
		.dout(alu_data2_temp)
	);	
	
	alu alu_inst(
		.ALU_Data1(Rs1_Data_ex_i),
		.ALU_Data2(alu_data2_temp),
		.ALU_Ctrl(ALU_Ctrl_ex_i),
		.ALU_Zero(ALU_zero),
		.ALU_Overflow(),
		.ALU_result(ALU_result)
	);
	
	//assign addr_to_dm_ex_o = ALU_result;
	//这样即使 lui 的 ALU 组合上算出了个值，也不会在 addr_to_dm_ex_o 上显示成一个“看起来很真的访存地址”
	assign addr_to_dm_ex_o =
    (Memread_ex_i || MemWrite_ex_i || FpMemRead_ex_i || FpMemWrite_ex_i)
    ? ALU_result
    : 32'b0;
	
	// FpMemWrite_ex_i 为1时写入dmem数据为rdata2_ex_i   //Rs2_Data数据会存入dmem中
	assign data_reg_to_dm_ex_o = FpMemWrite_ex_i ? rdata2_ex_i : Rs2_Data_ex_i;
	
	
	branch_judge branch_judge_inst (
		 .beq(beq_ex_i), 
		 .bne(bne_ex_i), 
		 .blt(blt_ex_i), 
		 .bge(bge_ex_i), 
		 .bltu(bltu_ex_i), 
		 .bgeu(bgeu_ex_i), 
		 .jal(jal_ex_i), 
		 .jalr(jalr_ex_i), 
		 .zero(ALU_zero), 
		 .ALU_result_zero(ALU_result[0]), //计算结果第0位
		 .jump_flag(jump_order_flag)
    );
	
	cal_adder32 pc_adder_4( //pc + 4 是执行阶段的PC+4，这个只作为写回reg的PC+4，就是jalr，jal指令的写回PC+4
		.A(pc_ex_i),
		.B(32'd4),
		.cin(1'd0),
		.result(pc_order),
		.cout()
	);
	
	cal_adder32 pc_adder_imme( //B，J型跳转指令时PC更新计算 pc + imme
		.A(pc_ex_i),
		.B(imme_ex_i),
		.cin(1'd0),
		.result(pc_jump),
		.cout()
	);
	
	my_mux	pc_order_jump_my_mux( //jump_order_flag 为1是选择pc_jump 
		.a(pc_order_ex_i),  //顺序执行的pc+4，这个pc是IF阶段的PC，因为更新PC要用实时的PC
		.b(pc_jump),
		.sel(jump_order_flag),
		.dout(pc_jump_order)
	);
	
	assign pc_jalr = {ALU_result[31:1],1'b0};//PC地址对其，所以最低位为0  
	
	my_mux  pc_jalr_my_mux( //jalr 为1时才选择pc_jalr 淦  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		.a(pc_jump_order),
		.b(pc_jalr),
		.sel(jalr_ex_i),
		.dout(pc_new_ex_o)
	);
			
	my_mux	WB_Data_my_mux( //MemtoReg 为1时选择data_dm_to_reg
		.a(ALU_result),
		.b(data_dm_to_reg_ex_i),
		.sel(MemtoReg_ex_i),
		.dout(WB_Data)
	);
		
	assign reg_sel = jalr_ex_i | jal_ex_i;
	
	my_mux	WB_jalr_pc( //reg_sel 为1时选择pc_order = pc + 4,而且是执行阶段的PC加上4
		.a(WB_Data),
		.b(pc_order),
		.sel(reg_sel),
		.dout(Wr_reg_data2)
	);	
	
	my_mux lui_my_mux(//lui为1时选择imme  为0时选择 pc_jump = pc + imme（auipc）
		.a(pc_jump),
		.b(imme_ex_i),
		.sel(lui_ex_i),
		.dout(Wr_reg_data1)
	);
	
	wire [31:0] WB_IM_Data;
	
	my_mux Wr_Reg_my_mux(//U_type为1时选择Wr_reg_data1
		.a(Wr_reg_data2),
		.b(Wr_reg_data1),
		.sel(U_type_ex_i),
		.dout(WB_IM_Data)
	);
	
	///////////////////浮点指令新增///////////////////
	
	wire [31:0]fpu_result;	
	
	//写回GPR数据变动
	wire [31:0] temp_wb_gpr_data;
	
	my_mux fp_to_gpr_mux1(//FP_Res_to_GPR_ex_i 为1时，将FPU结果写回GPR
		.a(WB_IM_Data),
		.b(fpu_result),
		.sel(FP_Res_to_GPR_ex_i),
		.dout(temp_wb_gpr_data)
	);
	
	my_mux fp_to_gpr_mux2(//FMV_X_W_ex_i 为1时，将搬运的浮点数写回GPR
		.a(temp_wb_gpr_data),
		.b(rdata1_ex_i),
		.sel(FMV_X_W_ex_i),
		.dout(Wb_Data_ex_o)
	);
	
	wire [31:0]i_src1;
	wire fpu_i_valid;
	wire fpu_o_valid;
	wire fpu_o_ready;
	
	reg fpu_req_sent;
	wire fpu_need = FpuEn_ex_i;
	wire fpu_handshake = fpu_i_valid & fpu_o_ready;

	assign fpu_i_valid = fpu_need & ~fpu_req_sent;
	
	assign stall_ex_o = FpuEn_ex_i & ~fpu_o_valid;

	always @(posedge clk or negedge rst) begin
		 if (!rst) begin
			  fpu_req_sent <= 1'b0;
		 end
		 else if (!fpu_need) begin
			  fpu_req_sent <= 1'b0;
		 end
		 else if (fpu_handshake) begin
			  fpu_req_sent <= 1'b1;
		 end
		 else if (fpu_o_valid) begin
			  fpu_req_sent <= 1'b0;
		 end
	end
	
	//源操作数1除了来自FPR，还可能来自GPR，比如fcvt.s.w(u)指令
	assign i_src1 =FCVT_S_W_WU_ex_i ? Rs1_Data_ex_i : rdata1_ex_i;
	
	fpu_top  FPU_INST(
		 .clk(clk),
		 .rst_n(rst),

		 .i_valid(fpu_i_valid),     // 来自整数核EX阶段的浮点请求有效
		 .o_ready(fpu_o_ready),     // FPU空闲，可接收新请求
		 .o_valid(fpu_o_valid),     // FPU结果有效（高1个周期）

		 .i_op_type(FpuOpType_ex_i),   // 运算类型编码
		 .i_rm(rm_ex_i),        // 舍入模式
		 .i_src1(i_src1),      // 源操作数1
		 .i_src2(rdata2_ex_i),      // 源操作数2
		 .i_src3(rdata3_ex_i),      // 源操作数3（仅FMA类使用）

		 .o_result(fpu_result),    // 运算结果
		 .o_fflags()     // 异常标志 {NV, DZ, OF, UF, NX}
	);
		
	//写回fpr选择
	
	wire [31:0]temp_fpr_wbdata;
	
	my_mux flw_wbdata(//FpMemRead_ex_i 为1时选择数据存储器的数据
		.a(fpu_result),
		.b(data_dm_to_reg_ex_i),
		.sel(FpMemRead_ex_i),
		.dout(temp_fpr_wbdata)
	);
	
	my_mux fpr_wbdata(//  FMV_W_X_ex_i 为1时选择fmv_w_x 搬运的GPR数据 Rs1_Data_ex_i
		.a(temp_fpr_wbdata),
		.b(Rs1_Data_ex_i),
		.sel(FMV_W_X_ex_i),
		.dout(WB_FPR_Data)
	);
	
	
endmodule

///////////额外加法器，用于PC值计算/////////////
module cal_adder32(
	input [31:0]A,
	input [31:0]B,
	input cin,
	output [31:0]result,
	output cout
);
	assign {cout,result} = A + B + cin;

endmodule

////////////////二选一选择器///////////////////
module my_mux(
	input [31:0]a,
	input [31:0]b,
	input sel,
	output [31:0]dout
);

	assign dout = (sel == 1'b0) ? a : b;

endmodule

////////////////jump_flag 是否跳转判断模块///////////
module branch_judge(
    beq, 
    bne, 
    blt, 
    bge, 
    bltu, 
    bgeu, 
    jal, 
    jalr, 
    zero, 
    ALU_result_zero, 
    jump_flag
);
	input jal;
	input jalr;
	input beq;
	input bne;
	input blt;
	input bge;
	input bltu;
	input bgeu;
	input zero;
	input ALU_result_zero;
	output jump_flag;
	
	assign jump_flag = jal | jalr 
							|(beq & zero) 
							|(bne & ~zero) 
							|(bltu & ALU_result_zero) //sltu 无符号小于置一
							|(bgeu & ~ALU_result_zero) //sltu 无符号小于置一
							|(blt & ALU_result_zero)  //slt 有符号 小于置一
							|(bge & ~ALU_result_zero);
	
endmodule

