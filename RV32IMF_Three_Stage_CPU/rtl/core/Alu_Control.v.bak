`include "define.v"

module Alu_Control(
	opcode,
	ALUop,
	funct3,
	funct7,
	ALUctl
);
	input [6:0]opcode;
	input [1:0]ALUop;
	input [2:0]funct3;
	input [6:0]funct7;
	output [4:0]ALUctl;
	
	wire [4:0]branchop;
	reg  [4:0]RIop;
	
	assign branchop = (funct3[2] & funct3[1]) ? `SLTU : (funct3[2] ^ funct3[1]) ? `SLT : `SUB;
	
	always @(*) begin
		if(funct7[0] && opcode == `R_arith) begin
			case(funct3)
				3'b000: RIop = `MUL;   
				3'b001: RIop = `MULH;
				3'b010: RIop = `MULHSU;
				3'b011: RIop = `MULHU;
				3'b100: RIop = `DIV;
				3'b101: RIop = `DIVU;
				3'b110: RIop = `REM;
				3'b111: RIop = `REMU;
			endcase
		end else begin
			case(funct3)
				3'b000: if(ALUop[1] & funct7[5])
								RIop = `SUB;   //仅R型有减法
						  else
								RIop = `ADD;  //R I 都有加法
				3'b001: RIop = `SLL;
				3'b010: RIop = `SLT;
				3'b011: RIop = `SLTU;
				3'b100: RIop = `XOR;
				3'b101: if(funct7[5])
								RIop = `SRA;
						  else
								RIop = `SRL;
				3'b110: RIop = `OR;
				3'b111: RIop = `AND;
			endcase
		end
	end
	
	assign ALUctl = (ALUop[0] ^ ALUop[1]) ? RIop : (ALUop[0] & ALUop[1]) ? branchop : `ADD;
	
endmodule
