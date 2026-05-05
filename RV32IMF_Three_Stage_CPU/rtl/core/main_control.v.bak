`include "define.v"

module main_control(
	input [6:0]opcode,
	input [2:0]funct3,
	output Memread, //数据存储器读使能
	output [1:0]ALUop,
	output MemtoReg, //MemtoReg 为1时选择data_dm_to_reg,即数据存储器的数据，即load指令时
	output MemWrite,
	output ALUsrc,
	output Wen_Reg_Wr,
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
	output [2:0]RW_type
);
	wire Branch;
	wire R_type; //包括 I 指令集和 M 指令集的指令
	wire I_type;
	wire Load;
	wire Store;
	wire auipc;
	
	assign Branch = (opcode == `B_instr) ? 1'b1 : 1'b0;
	assign R_type = (opcode == `R_arith) ? 1'b1 : 1'b0;
	assign I_type = (opcode == `I_arith) ? 1'b1 : 1'b0;
	assign Load = (opcode == `I_laod) ? 1'b1 : 1'b0;
	assign Store = (opcode == `S_store) ? 1'b1 : 1'b0;
	
	assign jal = (opcode == `J_jal) ? 1'b1 : 1'b0;
	assign jalr = (opcode == `I_jalr) ? 1'b1 : 1'b0;
	
	assign beq = Branch & ( funct3 == 3'b000);
	assign bne = Branch & ( funct3 == 3'b001);
	assign blt = Branch & ( funct3 == 3'b100);
	assign bge = Branch & ( funct3 == 3'b101);
	assign bltu = Branch & ( funct3 == 3'b110);
	assign bgeu = Branch & ( funct3 == 3'b111);
	assign lui = (opcode == `U_lui) ? 1'b1 : 1'b0;
	assign auipc = (opcode == `U_auipc) ? 1'b1 : 1'b0;
	assign U_type = lui | auipc;
	
	assign RW_type = funct3;
	
	assign Memread= Load;//取数指令写入
	
	assign Wen_Reg_Wr = R_type | I_type | Load | jal | U_type | jalr;
	assign MemWrite = Store;
	
	assign ALUsrc = R_type | Branch; //选择RS2_data
	
	assign MemtoReg = Load;//MemtoReg 为1时选择data_dm_to_reg,即数据存储器的数据，即load指令时
	
	assign ALUop[1] = R_type | Branch; // 10 R ; 01 I ; 11 Branch
	assign ALUop[0] = I_type | Branch;
	
endmodule
