
module pc_reg(
	clk,
	rst,
	pc_new,
	pc_out,
	stall_i
);
	input clk;
	input rst;
	input [31:0]pc_new;
	input stall_i;
	
	output reg [31:0]pc_out;
	
	always@(posedge clk or negedge rst) begin
		if(!rst) begin
			pc_out <= 32'd0;
		end else if(stall_i)begin
			pc_out <= pc_out;
		end else begin
			pc_out <= pc_new;
		end
	end

endmodule
