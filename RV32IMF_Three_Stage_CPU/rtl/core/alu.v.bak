
module alu(
	ALU_Data1,
	ALU_Data2,
	ALU_Ctrl, 
	ALU_Zero,
	ALU_Overflow,
	ALU_result
);
	input [31:0]ALU_Data1;
	input [31:0]ALU_Data2;
	//ALU_Ctrl 决定的运算类型如下
	// 00001 add ; 00011 sub ; 
	// 00100 and ; 00101 or ; 00110 xor ; 00111 或非
	// 01000 sltu ;01001 slt ;
	//	01100 sll ; 01101 srl ; 01110 sra
	// 10000 mul ; 10001 mulh ; 10010 mulhsu ; 10011 mulhu ; 10100 div ;10101 divu ; 10110 rem ; 10111 remu
	input [4:0]ALU_Ctrl;
	output ALU_Zero;
	output ALU_Overflow;
	output reg [31:0]ALU_result;

////////////////////逻辑运算////////////////////	
	reg [31:0]logic_result;
	
	always @(*) begin
		case(ALU_Ctrl[1:0])
			2'b00: logic_result = ALU_Data1 & ALU_Data2 ;
			2'b01: logic_result = ALU_Data1 | ALU_Data2 ;
			2'b10: logic_result = ALU_Data1 ^ ALU_Data2 ;
			2'b11: logic_result = ~(ALU_Data1 | ALU_Data2) ;
		endcase
	end
	
//////////////////移位运算///////////////////
	wire [31:0]shift_result;
	wire [4:0]shift_data;
	
	assign shift_data = ALU_Data2[4:0];
	
	shifter shifter_inst(
		.data(ALU_Data1),
		.shifter(shift_data),
		.shift_type(ALU_Ctrl[1:0]),
		.shift_out(shift_result)
	);
	
//////////////////加减运算///////////////////
	wire [31:0]ADD_result;
	wire SUB_str;
	wire [31:0]add_data2;
	wire ADD_carry,ADD_Overflow;
	wire Ovctr;
	
	assign Ovctr = ALU_Ctrl[0] & ~ ALU_Ctrl[3]  & ~ALU_Ctrl[2] ;//
	assign SUB_str = (~ALU_Ctrl[3] & ~ALU_Ctrl[2] & ALU_Ctrl[1]) | (ALU_Ctrl[3] & ~ALU_Ctrl[2]);//减法运算和置位运算，都用减法；
	assign add_data2 = ALU_Data2 ^ {32{SUB_str}}; //减法，被减数取反，即和1异或，同时cin 为1
	
	Adder  Adder_inst(
		.A(ALU_Data1),
		.B(add_data2),
		.cin(SUB_str),
		.ALU_Ctrl(ALU_Ctrl),
		.ADD_carry(ADD_carry),
		.ADD_Overflow(ADD_Overflow),
		.ADD_Zero(ALU_Zero),
		.ADD_result(ADD_result)
	);
	
	assign ALU_Overflow = ADD_Overflow & Ovctr;
	
////////////////置位运算//////////////
	wire [31:0]slt_result;
	wire Less_unsigned,Less_signed,Less_which;
	
	assign Less_unsigned = ADD_carry ^ SUB_str ; //无符号若满足小于，则ADD_carrya按照算法为0，否则为1
	assign Less_signed = ADD_Overflow ^ ADD_result[31];//看作有符号数，小于时，如没有溢出，则结果最高位为1
	
	assign Less_which = ALU_Ctrl[0] ? Less_signed : Less_unsigned;// 1000 sltu ;1001 slt ;
	
	assign slt_result = Less_which ? 32'h00000001 : 32'h00000000;
	
///////////////M拓展计算运算///////////
// 10000 mul ; 10001 mulh ; 10010 mulhsu ; 10011 mulhu ; 10100 div ;10101 divu ; 10110 rem ; 10111 remu
	wire [31:0]M_D_result;

	riscv_m_extension  riscv_m_extension_inst(
		 .Data1(ALU_Data1),   
		 .Data2(ALU_Data2),   
		 .Ctrl(ALU_Ctrl),    
		 .Result(M_D_result)   
	);
	
///////////////ALU 计算结果///////////

	always @(*) begin
		case(ALU_Ctrl[4:2])
			3'b000:ALU_result = ADD_result;
			3'b001:ALU_result = logic_result;
			3'b010:ALU_result = slt_result;
			3'b011:ALU_result = shift_result;
			3'b100,3'b101:ALU_result = M_D_result;
			default:ALU_result = 32'd0;
		endcase
	end

endmodule


///////////////shifter 模块///////////////
module shifter(
	data,
	shifter,
	shift_type,
	shift_out
);
	input [31:0]data;
	input [4:0]shifter;
	input [1:0]shift_type;
	output reg [31:0]shift_out;
	
	always @(*) begin
		case(shift_type)
			2'b00:shift_out = data << shifter;
			2'b01:shift_out = data >> shifter;
			2'b10:shift_out = $signed (data) >>> shifter;//有符号数 算术右移
			default:shift_out = data;
		endcase
	end

endmodule

///////////////adder  模块///////////////
module Adder(
	input [31:0]A,
	input [31:0]B,
	input cin,
	input [4:0]ALU_Ctrl,
	output ADD_carry,
	output ADD_Overflow,
	output ADD_Zero,
	output [31:0]ADD_result
);
	
	assign {ADD_carry , ADD_result} = A + B + cin; //减法也可以看做加法 ，减数只要“取反加一”就行
	
	assign ADD_Zero = ~(|ADD_result);
	
	assign ADD_Overflow = (((ALU_Ctrl == 5'b00001) & A[31] & B[31] & ~ADD_result[31])|   //	b.负数+负数=正数，则溢出
								  ((ALU_Ctrl == 5'b00001) & ~A[31] & ~B[31] & ADD_result[31])|	 //	a.正数+正数=负数，则溢出
								  ((ALU_Ctrl == 5'b00011)& A[31] & B[31] & ~ADD_result[31])|	 //	d.负数-正数=正数，则溢出	
								  ((ALU_Ctrl == 5'b00011) & ~A[31] & ~B[31] & ADD_result[31]));  //	c.正数-负数=负数，则溢出
						//减法的B参数，进来的数字是已经取反的数字，所以c,d要如上所示，即B的符号要在变一下，而不是如下所示，犯错了
						//((ALU_Ctrl == 5'b00011)& A[31] & ~B[31] & ~ADD_result[31])   //	d.负数-正数=正数，则溢出
						//((ALU_Ctrl == 5'b00011) & ~A[31] & B[31] & ADD_result[31])); //	c.正数-负数=负数，则溢出
							
endmodule

////////////////M 拓展计算///////////////
module riscv_m_extension (
    input  wire [31:0] Data1,   // 被除数/被乘数
    input  wire [31:0] Data2,   // 除数/乘数
    input  wire [4:0]  Ctrl,    // 运算控制信号
    output reg  [31:0] Result   // 32位运算结果
);

	// 指令编码定义（和ALU_Ctrl完全对齐）
	localparam MUL    = 5'b10000;
	localparam MULH   = 5'b10001;
	localparam MULHSU = 5'b10010;
	localparam MULHU  = 5'b10011;
	localparam DIV    = 5'b10100;
	localparam DIVU   = 5'b10101;
	localparam REM    = 5'b10110;
	localparam REMU   = 5'b10111;

	// 64位中间变量，用于乘法高32位计算
	wire [63:0] mul_signed;
	wire [63:0] mul_hsu;
	wire [63:0] mul_unsigned;

	// 手动扩展为64位再计算（适配Quartus的有符号处理）
	assign mul_signed   = {{32{Data1[31]}}, Data1} * {{32{Data2[31]}}, Data2};  // 有符号×有符号
	assign mul_hsu      = {{32{Data1[31]}}, Data1} * {32'd0, Data2};            // 有符号×无符号 不要用signed * unsigned
	assign mul_unsigned = {32'd0, Data1} * {32'd0, Data2};                      // 无符号×无符号

	always @(*) begin
		 case (Ctrl)  
			  // 乘法指令
			  MUL:     Result = mul_signed[31:0];       // 低32位
			  MULH:    Result = mul_signed[63:32];      // 有符号×有符号 高32位
			  MULHSU:  Result = mul_hsu[63:32];         // 有符号×无符号 高32位
			  MULHU:   Result = mul_unsigned[63:32];    // 无符号×无符号 高32位

			  // 有符号除法
			  DIV: begin
					if (Data2 == 32'b0) begin
						 Result = 32'hFFFFFFFF;  // 除数为0时商为-1（全1）
					end else if (Data1 == 32'h80000000 && Data2 == 32'hFFFFFFFF) begin
						 Result = 32'h80000000;  // 溢出情况：-2^31 / -1 = -2^31
					end else begin
						 Result = $signed(Data1) / $signed(Data2);
					end
			  end

			  // 无符号除法
			  DIVU: begin
					if (Data2 == 32'b0) begin
						 Result = 32'hFFFFFFFF;  // 除数为0时商为2^32-1（全1）
					end else begin
						 Result = $unsigned(Data1) / $unsigned(Data2);
					end
			  end

			  // 有符号取余
			  REM: begin
					if (Data2 == 32'b0) begin
						 Result = Data1;     // 除数为0时余数为被除数
					end else if (Data1 == 32'h80000000 && Data2 == 32'hFFFFFFFF) begin
						 Result = 32'b0;         // 溢出情况余数为0
					end else begin
						 Result = $signed(Data1) % $signed(Data2);
					end
			  end

			  // 无符号取余
			  REMU: begin
					if (Data2 == 32'b0) begin
						 Result = Data1;     // 除数为0时余数为被除数
					end else begin 
						 Result = $unsigned(Data1) % $unsigned(Data2);
					end
			  end
			  default: Result = 32'b0;
		 endcase
	end

endmodule

