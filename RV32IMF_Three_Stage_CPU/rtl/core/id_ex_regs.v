`include "define.v"
module id_ex_regs(
	input clk,
	input rst,
	input jump_flag,
	
	input [31:0]pc_id_ex_i,
	input [31:0]imme_id_ex_i,
	input [31:0]Rs1_Data_id_ex_i,
	input [31:0]Rs2_Data_id_ex_i,
	input [4:0]Rd_id_ex_i,
	
	output reg [31:0]pc_id_ex_o,
	output reg [31:0]imme_id_ex_o,
	output reg [31:0]Rs1_Data_id_ex_o,
	output reg [31:0]Rs2_Data_id_ex_o,
	output reg [4:0]Rd_id_ex_o,
	
	input Memread_id_ex_i, //数据存储器读使能
	input MemtoReg_id_ex_i, //MemtoReg 为1时选择data_dm_to_reg,即数据存储器的数据，即load指令时
	input MemWrite_id_ex_i,
	input ALUsrc_id_ex_i,
	input RegWrite_id_ex_i,
	input lui_id_ex_i,
	input U_type_id_ex_i,
	input jal_id_ex_i,
	input jalr_id_ex_i,
	input beq_id_ex_i,
	input bne_id_ex_i,
	input blt_id_ex_i,
	input bge_id_ex_i,
	input bltu_id_ex_i,
	input bgeu_id_ex_i,
	input [2:0]RW_type_id_ex_i,
	input [4:0]ALU_Ctrl_id_ex_i,
	
	output reg Memread_id_ex_o, //数据存储器读使能
	output reg MemtoReg_id_ex_o, //MemtoReg 为1时选择data_dm_to_reg,即数据存储器的数据，即load指令时
	output reg MemWrite_id_ex_o,
	output reg ALUsrc_id_ex_o,
	output reg RegWrite_id_ex_o,
	output reg lui_id_ex_o,
	output reg U_type_id_ex_o,
	output reg jal_id_ex_o,
	output reg jalr_id_ex_o,
	output reg beq_id_ex_o,
	output reg bne_id_ex_o,
	output reg blt_id_ex_o,
	output reg bge_id_ex_o,
	output reg bltu_id_ex_o,
	output reg bgeu_id_ex_o,
	output reg [2:0]RW_type_id_ex_o,
	output reg [4:0]ALU_Ctrl_id_ex_o,
	
	//浮点指令新增	
	input FpMemRead_id_ex_i,
	output reg FpMemRead_id_ex_o,
	input FpMemWrite_id_ex_i,
	output reg FpMemWrite_id_ex_o,
	
	input [31:0]rdata1_id_ex_i,
	input [31:0]rdata2_id_ex_i,
	input [31:0]rdata3_id_ex_i,
	input [2:0]rm_id_ex_i,
	
	output reg [31:0]rdata1_id_ex_o,
	output reg [31:0]rdata2_id_ex_o,
	output reg [31:0]rdata3_id_ex_o,
	output reg [2:0]rm_id_ex_o,
	
	input FCVT_S_W_WU_id_ex_i,
	output reg FCVT_S_W_WU_id_ex_o,
	input [4:0]FpuOpType_id_ex_i,
	output reg [4:0]FpuOpType_id_ex_o,
	input FMV_W_X_id_ex_i,
	output reg FMV_W_X_id_ex_o,
	input FP_Res_to_GPR_id_ex_i,
	input FMV_X_W_id_ex_i,
	output reg FP_Res_to_GPR_id_ex_o,
	output reg FMV_X_W_id_ex_o,
	input fp_we_Write_id_ex_i,
	output reg fp_we_Write_id_ex_o,
	input FpuEn_id_ex_i,
	output reg FpuEn_id_ex_o,
	input stall_i
);

	//浮点指令新增
	always@(posedge clk or negedge rst) begin
		if(!rst)
			FpuEn_id_ex_o <= 1'b0;
		else if(jump_flag) 
			FpuEn_id_ex_o <= 1'b0;
		else if (stall_i)
			FpuEn_id_ex_o <= FpuEn_id_ex_o;
		else
			FpuEn_id_ex_o <= FpuEn_id_ex_i;
	end
	
	always@(posedge clk or negedge rst) begin
		if(!rst)
			FpMemRead_id_ex_o<= 1'b0;
		else if(jump_flag) 
			FpMemRead_id_ex_o <= 1'b0;
		else if (stall_i)
			FpMemRead_id_ex_o <= FpMemRead_id_ex_o;
		else
			FpMemRead_id_ex_o<=FpMemRead_id_ex_i;
	end

	always@(posedge clk or negedge rst) begin
		if(!rst)
			FpMemWrite_id_ex_o<= 1'b0;
		else if(jump_flag) 
			FpMemWrite_id_ex_o <= 1'b0;
		else if (stall_i)
			FpMemWrite_id_ex_o <= FpMemWrite_id_ex_o;
		else
			FpMemWrite_id_ex_o<=FpMemWrite_id_ex_i;
	end
	
	always@(posedge clk or negedge rst) begin
		if(!rst)
			FCVT_S_W_WU_id_ex_o <= 1'b0;
		else if(jump_flag) 
			FCVT_S_W_WU_id_ex_o <= 1'b0;
		else if (stall_i)
			FCVT_S_W_WU_id_ex_o <= FCVT_S_W_WU_id_ex_o;
		else
			FCVT_S_W_WU_id_ex_o <= FCVT_S_W_WU_id_ex_i ;
	end
	
	always@(posedge clk or negedge rst) begin
		if(!rst)
			FpuOpType_id_ex_o <= 5'b0;
		else if(jump_flag) 
			FpuOpType_id_ex_o <= 5'b0;
		else if (stall_i)
			FpuOpType_id_ex_o <= FpuOpType_id_ex_o;
		else
			FpuOpType_id_ex_o <= FpuOpType_id_ex_i ;
	end	
	
	always@(posedge clk or negedge rst) begin
		if(!rst)
			rdata1_id_ex_o <= `zero_word;
		else if (stall_i)
			rdata1_id_ex_o <= rdata1_id_ex_o;
		else
			rdata1_id_ex_o <= rdata1_id_ex_i;
	end
	
	always@(posedge clk or negedge rst) begin
		if(!rst)
			rdata2_id_ex_o <= `zero_word;
		else if (stall_i)
			rdata2_id_ex_o <= rdata2_id_ex_o;
		else
			rdata2_id_ex_o <= rdata2_id_ex_i;
	end	
	
	always@(posedge clk or negedge rst) begin
		if(!rst)
			rdata3_id_ex_o <= `zero_word;
		else if (stall_i)
			rdata3_id_ex_o <= rdata3_id_ex_o;
		else
			rdata3_id_ex_o <= rdata3_id_ex_i;
	end
	
	always@(posedge clk or negedge rst) begin
		if(!rst)
			 rm_id_ex_o <= 3'b0;
		else if (stall_i)
			 rm_id_ex_o <= rm_id_ex_o;
		else
			 rm_id_ex_o <= rm_id_ex_i;
	end
	
	always@(posedge clk or negedge rst) begin
		if(!rst)
			 FMV_W_X_id_ex_o <= 1'b0;
		else if(jump_flag) 
			 FMV_W_X_id_ex_o <= 1'b0;
		else if (stall_i)
			 FMV_W_X_id_ex_o <= FMV_W_X_id_ex_o;
		else
			 FMV_W_X_id_ex_o <= FMV_W_X_id_ex_i;
	end	

	always@(posedge clk or negedge rst) begin
		if(!rst)
			 FP_Res_to_GPR_id_ex_o <= 1'b0;
		else if(jump_flag) 
			 FP_Res_to_GPR_id_ex_o <= 1'b0;
		else if (stall_i)
			 FP_Res_to_GPR_id_ex_o <= FP_Res_to_GPR_id_ex_o;
		else
			 FP_Res_to_GPR_id_ex_o <= FP_Res_to_GPR_id_ex_i;
	end	

	always@(posedge clk or negedge rst) begin
		if(!rst)
			 FMV_X_W_id_ex_o <= 1'b0;
		else if(jump_flag) 
			 FMV_X_W_id_ex_o <= 1'b0;
		else if (stall_i)
			 FMV_X_W_id_ex_o <= FMV_X_W_id_ex_o;
		else
			 FMV_X_W_id_ex_o <= FMV_X_W_id_ex_i;
	end	
	
	always@(posedge clk or negedge rst) begin
		if(!rst)
			 fp_we_Write_id_ex_o <= 1'b0;
		else if(jump_flag) 
			 fp_we_Write_id_ex_o <= 1'b0;
		else if (stall_i)
			 fp_we_Write_id_ex_o <= fp_we_Write_id_ex_o;
		else
			 fp_we_Write_id_ex_o <= fp_we_Write_id_ex_i;
	end
	
	//原来的
	always@(posedge clk or negedge rst) begin
		if(!rst)
			pc_id_ex_o<=`zero_word;
		else if (stall_i)
			pc_id_ex_o <= pc_id_ex_o;
		else
			pc_id_ex_o<=pc_id_ex_i;
	end
		
	always@(posedge clk or negedge rst) begin
		if(!rst)
			imme_id_ex_o<=`zero_word;
		else if (stall_i)
			imme_id_ex_o <= imme_id_ex_o;
		else
			imme_id_ex_o<=imme_id_ex_i;
	end
		
	always@(posedge clk or negedge rst) begin
		if(!rst)
			Rs1_Data_id_ex_o<=`zero_word;
		else if (stall_i)
			Rs1_Data_id_ex_o <= Rs1_Data_id_ex_o;
		else
			Rs1_Data_id_ex_o<=Rs1_Data_id_ex_i;
	end

	always@(posedge clk or negedge rst) begin
		if(!rst)
			Rs2_Data_id_ex_o<=`zero_word;
		else if (stall_i)
			Rs2_Data_id_ex_o <= Rs2_Data_id_ex_o;
		else
			Rs2_Data_id_ex_o<=Rs2_Data_id_ex_i;
	end
		
	always@(posedge clk or negedge rst) begin
		if(!rst)
			Rd_id_ex_o <= 5'd0;
		else if (stall_i)
			Rd_id_ex_o <= Rd_id_ex_o;
		else
			Rd_id_ex_o <= Rd_id_ex_i;
	end
	
	always@(posedge clk or negedge rst) begin   //////////////////////////////控制冒险需要解决的信号
		if(!rst)
			Memread_id_ex_o <= 1'b0;
		else if(jump_flag) 
			Memread_id_ex_o <= 1'b0;
		else if (stall_i)
			Memread_id_ex_o <= Memread_id_ex_o;
		else
			Memread_id_ex_o <= Memread_id_ex_i;
	end

	always@(posedge clk or negedge rst) begin
		if(!rst)
			MemtoReg_id_ex_o <= 1'b0;
		else if(jump_flag) 
			MemtoReg_id_ex_o <= 1'b0;
		else if (stall_i)
			MemtoReg_id_ex_o <= MemtoReg_id_ex_o;
		else
			MemtoReg_id_ex_o <= MemtoReg_id_ex_i;
	end

	always@(posedge clk or negedge rst) begin
		if(!rst)
			MemWrite_id_ex_o <= 1'b0;
		else if(jump_flag) 
			MemWrite_id_ex_o <= 1'b0;
		else if (stall_i)
			MemWrite_id_ex_o <= MemWrite_id_ex_o;
		else
			MemWrite_id_ex_o <= MemWrite_id_ex_i;
	end

	always@(posedge clk or negedge rst) begin
		if(!rst)
			ALUsrc_id_ex_o <= 1'b0;
		else if(jump_flag) 
			ALUsrc_id_ex_o <= 1'b0;
		else if (stall_i)
			ALUsrc_id_ex_o <= ALUsrc_id_ex_o;
		else
			ALUsrc_id_ex_o <= ALUsrc_id_ex_i;
	end

	always@(posedge clk or negedge rst) begin
		if(!rst)
			RegWrite_id_ex_o <= 1'b0;
		else if(jump_flag) 
			RegWrite_id_ex_o <= 1'b0;
		else if (stall_i)
			RegWrite_id_ex_o <= RegWrite_id_ex_o;
		else
			RegWrite_id_ex_o <= RegWrite_id_ex_i;
	end

	always@(posedge clk or negedge rst) begin
		if(!rst)
			lui_id_ex_o <= 1'b0;
		else if(jump_flag) 
			lui_id_ex_o <= 1'b0;
		else if (stall_i)
			lui_id_ex_o <= lui_id_ex_o;
		else
			lui_id_ex_o <= lui_id_ex_i;
	end

	always@(posedge clk or negedge rst) begin
		if(!rst)
			U_type_id_ex_o <= 1'b0;
		else if(jump_flag) 
			U_type_id_ex_o <= 1'b0;
		else if (stall_i)
			U_type_id_ex_o <= U_type_id_ex_o;
		else
			U_type_id_ex_o <= U_type_id_ex_i;
	end

	always@(posedge clk or negedge rst) begin
		if(!rst)
			jal_id_ex_o  <= 1'b0;
		else if(jump_flag) 
			jal_id_ex_o  <= 1'b0;
		else if (stall_i)
			jal_id_ex_o <= jal_id_ex_o;
		else
			jal_id_ex_o <= jal_id_ex_i;
	end

	always@(posedge clk or negedge rst) begin
		if(!rst)
			jalr_id_ex_o <= 1'b0;
		else if(jump_flag) 
			jalr_id_ex_o <= 1'b0;
		else if (stall_i)
			jalr_id_ex_o <= jalr_id_ex_o;
		else
			jalr_id_ex_o <= jalr_id_ex_i;
	end

	always@(posedge clk or negedge rst) begin
		if(!rst)
			beq_id_ex_o <= 1'b0;
		else if(jump_flag) 
			beq_id_ex_o <= 1'b0;
		else if (stall_i)
			beq_id_ex_o <= beq_id_ex_o;
		else
			beq_id_ex_o <= beq_id_ex_i;
	end

	always@(posedge clk or negedge rst) begin
		if(!rst)
			bne_id_ex_o <= 1'b0;
		else if(jump_flag) 
			bne_id_ex_o <= 1'b0;
		else if (stall_i)
			bne_id_ex_o <= bne_id_ex_o;
		else
			bne_id_ex_o <= bne_id_ex_i;
	end

	always@(posedge clk or negedge rst) begin
		if(!rst)
			blt_id_ex_o <= 1'b0;
		else if(jump_flag) 
			blt_id_ex_o <= 1'b0;
		else if (stall_i)
			blt_id_ex_o <= blt_id_ex_o;
		else
			blt_id_ex_o <= blt_id_ex_i;
	end

	always@(posedge clk or negedge rst) begin
		if(!rst)
			bge_id_ex_o <= 1'b0;
		else if(jump_flag) 
			bge_id_ex_o <= 1'b0;
		else if (stall_i)
			bge_id_ex_o <= bge_id_ex_o;
		else
			bge_id_ex_o <= bge_id_ex_i;
	end

	always@(posedge clk or negedge rst) begin
		if(!rst)
			bltu_id_ex_o <= 1'b0;
		else if(jump_flag) 
			bltu_id_ex_o <= 1'b0;
		else if (stall_i)
			bltu_id_ex_o <= bltu_id_ex_o;
		else
			bltu_id_ex_o <= bltu_id_ex_i;
	end

	always@(posedge clk or negedge rst) begin
		if(!rst)
			bgeu_id_ex_o <= 1'b0;
		else if(jump_flag) 
			bgeu_id_ex_o <= 1'b0;
		else if (stall_i)
			bgeu_id_ex_o <= bgeu_id_ex_o;
		else
			bgeu_id_ex_o <= bgeu_id_ex_i;
	end

	always@(posedge clk or negedge rst) begin
		if(!rst)
			RW_type_id_ex_o <= 3'd0;
		else if(jump_flag) 
			RW_type_id_ex_o <= 3'd0;
		else if (stall_i)
			RW_type_id_ex_o <= RW_type_id_ex_o;
		else
			RW_type_id_ex_o <= RW_type_id_ex_i;
	end

	always@(posedge clk or negedge rst) begin
		if(!rst)
			ALU_Ctrl_id_ex_o <= 5'd0;
		else if(jump_flag) 
			ALU_Ctrl_id_ex_o <= 5'd0;
		else if (stall_i)
			ALU_Ctrl_id_ex_o <= ALU_Ctrl_id_ex_o;
		else
			ALU_Ctrl_id_ex_o <= ALU_Ctrl_id_ex_i;
	end
	
	
endmodule


