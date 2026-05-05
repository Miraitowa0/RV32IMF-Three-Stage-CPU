module fpu_fsgnj_n_x(
	input [31:0]fs1_data,
	input [31:0]fs2_data,
	input [2:0]ctrl,
	output reg [31:0]fd_data
);
	 // 操作类型编码：
    // ctrl[1:0] = 2'b00: FSGNJ.S  符号位来自 fs2
    // ctrl[1:0] = 2'b01: FSGNJN.S 符号位为 fs2 的取反
    // ctrl[1:0] = 2'b10: FSGNJX.S 符号位为 fs1 与 fs2 的异或
	always @(*) begin
		case(ctrl[1:0])
			2'b00:fd_data = {fs2_data[31],fs1_data[30:0]};
			2'b01:fd_data = {~fs2_data[31],fs1_data[30:0]};
			2'b10:fd_data = {fs2_data[31] ^ fs1_data[31],fs1_data[30:0]};
			default:fd_data = 32'd0;
		endcase
	end

endmodule

