`timescale 1ns/1ps

module tb_data_memory();
	reg clk;
	reg rst;
	reg [31:0]data_in;
	reg [31:0]addr;
	reg W_en;
	reg R_en;
	reg [2:0]RW_type;
	wire [31:0]data_out;

	data_memory uut(
		.clk(clk),
		.rst(rst),
		.data_in(data_in),
		.addr(addr),
		.W_en(W_en),
		.R_en(R_en),
		.RW_type(RW_type),
		.data_out(data_out)
	);
	
	// 生成时钟（10ns周期）
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end
    
    // 波形生成
    initial begin
        $dumpfile("tb_data_memory.vcd");
        $dumpvars(0, tb_data_memory);
    end
	
	// 仿真激励（验证初始化数据读取）
    initial begin
        // 步骤1：复位（若需保留初始化数据，可将rst置0，避免复位清0）
        W_en = 1'b0;
        addr = 32'd0;
        RW_type = 3'b000;
        #10;
        
		  data_in = 32'h00000000;
		  
        // 步骤2：验证字节读取（addr=0x00，lbu，无符号扩展）
        addr = 32'd0;       // 字节地址0x00，对应ram[0][7:0]=0x44
        RW_type = 3'b100;  // lbu（无符号扩展）
        #20;
        $display("addr=0x00, lbu, data_out=%h", data_out); // 预期：00000044
        
        // 步骤3：验证字节读取（addr=0x05，lbu，无符号扩展）
        addr = 32'd5;       // 字节地址0x05，对应ram[1][15:8]=0xCC
        RW_type = 3'b100;
        #20;
        $display("addr=0x05, lbu, data_out=%h", data_out); // 预期：000000CC
        
        // 步骤4：验证字读取（addr=0x00，lw，32位字）
        addr = 32'd0;       // 字节地址0x00，对应ram[0]=32'h11223344
        RW_type = 3'b010;  // lw
        #20;
        $display("addr=0x00, lw, data_out=%h", data_out);  // 预期：11223344
        
        // 步骤5：验证半字读取（addr=0x04，lhu，无符号扩展）
        addr = 32'd4;       // 字节地址0x04，对应ram[1][15:0]=0xCCDD
        RW_type = 3'b101;  // lhu
        #20;
        $display("addr=0x04, lhu, data_out=%h", data_out); // 预期：0000CCDD
        
		  W_en = 1'b1;
		  data_in = 32'h11335577;
		  addr = 32'd0;
		  RW_type = 3'b010; //sw
		  #20
		  
		  data_in = 32'h000000ff;
		  addr = 32'd5;
		  RW_type = 3'b000; //sb
		  #20
		   
		  W_en = 1'b0;
		  addr = 32'd0;
		  RW_type = 3'b010; //lw
		  #20
		  $display("addr=0x00, lw, data_out=%h", data_out);  // 预期：11335577
		  
		  
		  addr = 32'd5;
		  RW_type = 3'b101; //lhu
		  #20
		  $display("addr=0x05, lhu, data_out=%h", data_out);  // 预期：0000ffdd
		  
		  
        // 结束仿真
        #20;
        $finish;
    end


endmodule
