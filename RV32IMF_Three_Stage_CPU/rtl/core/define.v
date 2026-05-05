`define		zero_word		32'd0

`define		U_lui		7'b0110111
`define		U_auipc	7'b0010111
`define		J_jal		7'b1101111
`define		I_jalr	7'b1100111
`define		I_laod	7'b0000011
`define		I_arith	7'b0010011
`define		B_instr	7'b1100011
`define		S_store	7'b0100011
`define 		R_arith	7'b0110011

`define 	ADD  			5'b00001
`define 	SUB  			5'b00011

`define 	AND  			5'b00100
`define 	OR   			5'b00101
`define 	XOR  			5'b00110
`define  NOR			5'b00111

`define 	SLT  			5'b01001
`define 	SLTU 			5'b01000

`define 	SLL  			5'b01100
`define 	SRL  			5'b01101
`define 	SRA  			5'b01110

`define  MUL    		5'b10000
`define  MULH   		5'b10001   
`define  MULHSU 		5'b10010
`define  MULHU  		5'b10011

`define  DIV    		5'b10100
`define  DIVU   		5'b10101
`define  REM    		5'b10110
`define  REMU   		5'b10111

//浮点指令opecode定义
`define     OP_FP       7'b1010011  // 基础浮点运算
`define     LOAD_FP     7'b0000111  // flw
`define     STORE_FP    7'b0100111  // fsw
`define     FMADD       7'b1000011  // 乘加
`define     FMSUB       7'b1000111
`define     FNMSUB      7'b1001011
`define     FNMADD      7'b1001111


//FPU运算操作码定义
`define    OP_FADD      5'd0
`define    OP_FSUB      5'd1
`define    OP_FMUL      5'd2
`define    OP_FDIV      5'd3
`define    OP_FSQRT     5'd4
   
`define    OP_FMADD     5'd5
`define    OP_FMSUB     5'd6
`define    OP_FNMSUB    5'd7
`define    OP_FNMADD    5'd8
   
`define    OP_FSGNJ     5'd9
`define    OP_FSGNJN    5'd10
`define    OP_FSGNJX    5'd11
   
`define    OP_FMAX      5'd12
`define    OP_FMIN      5'd13
`define    OP_FEQ       5'd14
`define    OP_FLT       5'd15
`define    OP_FLE       5'd16
   
`define    OP_FCLASS    5'd17
   
`define    OP_FCVT_W_S  5'd18
`define    OP_FCVT_WU_S 5'd19
`define    OP_FCVT_S_W  5'd20
`define    OP_FCVT_S_WU 5'd21


`define     Func7_FADD       7'b0000000
`define     Func7_FSUB       7'b0000100
`define     Func7_FMUL       7'b0001000
`define     Func7_FDIV       7'b0001100
`define     Func7_FSQRT      7'b0101100
`define     Func7_FSGNJ      7'b0010000
`define     Func7_MIN_MAX    7'b0010100
`define     Func7_FCVT_W_S   7'b1100000
`define     Func7_FMV_X_W    7'b1110000
`define     Func7_FMV_W_X    7'b1111000
`define     Func7_CPR        7'b1010000
`define     Func7_FCLASS     7'b1110000
`define     Func7_FCVT_S_W   7'b1101000
