`include "define.v"
 
module instr_decode(
	instr,
	opcode,
	rs1,
	rs2,
	rd,
	funct3,
	funct7,
	imme,
	rs3,
	rm
);

	input [31:0]instr;
	output [6:0]opcode;
	output [4:0]rs1;
	output [4:0]rs2;
	output [4:0]rd;
	output [2:0]funct3;
	output [6:0]funct7;
	output [31:0]imme;
	//浮点指令新增
	output [4:0]rs3;
	output [2:0]rm;

	wire [31:0]I_imme;
	wire [31:0]S_imme;
	wire [31:0]B_imme;
	wire [31:0]U_imme;
	wire [31:0]J_imme;
	
	wire I_type;
	wire S_type;
	wire B_type;
	wire U_type;
	wire J_type;
	
	assign opcode = instr[6:0];
	assign rs1 = instr[19:15];
	assign rs2 = instr[24:20];
	assign rd = instr[11:7];
	assign funct3 = instr[14:12];
	assign funct7 = instr[31:25]; //funct7 要全部提取出 便于后面判断M F拓展里面的操作
	
	//浮点指令新增
	assign rs3 = instr[31:27];
	assign rm = instr[14:12];
	
	assign I_imme = {{20{instr[31]}},instr[31:20]};
	assign S_imme = {{20{instr[31]}},instr[31:25],instr[11:7]};
	assign B_imme = {{20{instr[31]}},instr[7],instr[30:25],instr[11:8],1'b0};//已经乘以二了
	assign U_imme = {instr[31:12],{12{1'b0}}};// 20 位立即数的值左移 12 位（低 12 位补 0 ）
	assign J_imme = {{12{instr[31]}},instr[19:12],instr[20],instr[30:21],1'b0};//已经乘以二了
	//改变后的I,S类型
	assign I_type = (opcode == `I_laod) | (opcode == `I_arith) | (opcode == `I_jalr) | (opcode == `LOAD_FP);
	assign S_type = (opcode == `S_store) | (opcode == `STORE_FP);
	
	assign B_type = (opcode == `B_instr);
	assign U_type = (opcode == `U_lui) | (opcode == `U_auipc);
	assign J_type = (opcode == `J_jal);
	
	assign imme = I_type ? I_imme :
					  S_type ? S_imme :
					  B_type ? B_imme :
					  U_type ? U_imme :
					  J_type ? J_imme : 32'd0;
	
	
endmodule
