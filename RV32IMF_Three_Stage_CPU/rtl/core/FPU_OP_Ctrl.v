
`include "define.v"

module FPU_OP_Ctrl(
    input  [6:0] opcode,
    input  [2:0] funct3,
    input  [6:0] funct7, 
    input        instr_20,
    output reg [4:0] FpuOpType // 注意：这里必须是 reg
);

    always @(*) begin
        // 默认状态，防止产生 Latch
        FpuOpType = 5'b11111;

        case (opcode)
            `OP_FP: begin
                case(funct7)
                    `Func7_FADD : FpuOpType = `OP_FADD;
                    `Func7_FSUB : FpuOpType = `OP_FSUB;
                    `Func7_FMUL : FpuOpType = `OP_FMUL;
                    `Func7_FDIV : FpuOpType = `OP_FDIV;
                    `Func7_FSQRT: FpuOpType = `OP_FSQRT;
                    `Func7_FSGNJ: begin
                        case(funct3)
                            3'b000: FpuOpType = `OP_FSGNJ;
                            3'b001: FpuOpType = `OP_FSGNJN;
                            3'b010: FpuOpType = `OP_FSGNJX;
                            default: FpuOpType = 5'b11111;
                        endcase
                    end   
                    `Func7_MIN_MAX: begin
                        case(funct3)
                            3'b000: FpuOpType = `OP_FMIN;
                            3'b001: FpuOpType = `OP_FMAX;
                            default: FpuOpType = 5'b11111;
                        endcase
                    end 
                    `Func7_FCVT_W_S: begin
                        if(instr_20) FpuOpType = `OP_FCVT_WU_S;
                        else         FpuOpType = `OP_FCVT_W_S;
                    end
                    `Func7_CPR: begin
                        case(funct3)
                            3'b000: FpuOpType = `OP_FLE;
                            3'b001: FpuOpType = `OP_FLT;
                            3'b010: FpuOpType = `OP_FEQ;
                            default: FpuOpType = 5'b11111;
                        endcase
                    end 
                    // 区分 FCLASS 和 FMV.X.W
                    `Func7_FCLASS: begin 
                        if (funct3 == 3'b001) begin
                            FpuOpType = `OP_FCLASS;
                        end else begin
                            FpuOpType = 5'b11111; // FMV.X.W 不需要进 FPU 计算
                        end
                    end
                    `Func7_FCVT_S_W: begin
                        if(instr_20) FpuOpType = `OP_FCVT_S_WU;
                        else         FpuOpType = `OP_FCVT_S_W;
                    end
                    default: FpuOpType = 5'b11111;
                endcase
            end
            `FMADD : FpuOpType = `OP_FMADD;
            `FMSUB : FpuOpType = `OP_FMSUB;
            `FNMSUB: FpuOpType = `OP_FNMSUB;
            `FNMADD: FpuOpType = `OP_FNMADD;
            default: FpuOpType = 5'b11111;
        endcase
    end

endmodule
