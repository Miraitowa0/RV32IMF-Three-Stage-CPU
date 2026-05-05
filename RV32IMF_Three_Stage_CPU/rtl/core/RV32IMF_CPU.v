module RV32IMF_CPU(
	input clk,
	input rst,
	output [7:0]rom_addr
);
	wire [31:0]instr;
	wire [31:0]Wr_data_to_dem;
	wire [31:0]addr_dem;
	wire MemWrite;
	wire Memread;
	wire [2:0]RW_type;
	wire [31:0]data_dem_to_reg;
	
	instr_memory  instr_memory_inst(
		.addr(rom_addr),
		.instr(instr)
	);
	
	data_memory data_memory_inst(
		.clk(clk),
		.rst(rst),
		.data_in(Wr_data_to_dem),
		.addr(addr_dem),
		.W_en(MemWrite),
		.R_en(Memread),
		.RW_type(RW_type),
		.data_out(data_dem_to_reg)
	);
	
	Risc_v_top Risc_v_top_inst(
		.clk(clk),
		.rst(rst),
		.instr(instr),
		.data_dm_to_reg(data_dem_to_reg),
		.addr_to_im(rom_addr),
		.addr_to_dm(addr_dem),
		.data_reg_to_dm(Wr_data_to_dem),
		.RW_type(RW_type),
		.MemWrite(MemWrite),
		.Memread(Memread)
	);
	
endmodule
