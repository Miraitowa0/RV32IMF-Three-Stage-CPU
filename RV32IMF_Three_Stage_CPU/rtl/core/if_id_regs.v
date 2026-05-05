`include "define.v"

module if_id_regs(
	input clk,
	input rst,
	input jump_flag,
	
	input [31:0]pc_if_id_i,
	input [31:0]instr_if_id_i,
	output reg [31:0]pc_if_id_o,
	output reg [31:0]instr_if_id_o,
	input stall_i
);

	always@(posedge clk or negedge rst) begin
		if(!rst)
			pc_if_id_o<=`zero_word;
		else if (jump_flag)
        pc_if_id_o <= `zero_word;
		else if (stall_i)
			pc_if_id_o <= pc_if_id_o;
		else
			pc_if_id_o<=pc_if_id_i;
	end
	
	always@(posedge clk or negedge rst) begin
		if(!rst)
			instr_if_id_o<=`zero_word;
		else if (jump_flag)   //控制冒险解决
			instr_if_id_o <= `zero_word;
		else if(stall_i)
			instr_if_id_o <= instr_if_id_o;
		else
			instr_if_id_o<=instr_if_id_i;
	end

endmodule


