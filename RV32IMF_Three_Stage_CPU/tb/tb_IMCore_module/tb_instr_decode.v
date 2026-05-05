`timescale 1ns/1ps

module tb_instr_decode;

    reg [31:0] instr;  // 输入指令（reg类型，用于驱动激励）
    wire [6:0] opcode; // 输出操作码
    wire [4:0] rs1;    // 输出源寄存器1
    wire [4:0] rs2;    // 输出源寄存器2
    wire [4:0] rd;     // 输出目标寄存器
    wire [2:0] funct3; // 输出功能码3
    wire [6:0] funct7; // 输出功能码7
    wire [31:0] imme;  // 输出解码后的立即数

    instr_decode uut_instr_decode(
        .instr(instr),
        .opcode(opcode),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .funct3(funct3),
        .funct7(funct7),
        .imme(imme)
    );

    initial begin
        // 初始化输入指令
        instr = 32'd0;
        #10; // 等待仿真稳定

        // ---------------------- 测试1:    I型指令（加载指令 lw，`I_laod`）----------------------
        // 指令示例:    lw x1, 0x10(x2)  二进制简化:    32'h01002083
        // 各字段解析:    
        // opcode: 7'b0000011 (`I_laod)
        // rs1: 5'b00010 (x2)
        // rd: 5'b00001 (x1)
        // funct3: 3'b010 (lw对应funct3=010)
        // 立即数: 0x10 (对应instr[31:20]=0x10)
        instr = 32'h01002083;
        #20; // 保持20ns，便于观察和打印
        print_result("I_TYPE (lw)");

        // ---------------------- 测试2:    I型指令（算术指令 addi，`I_arith`）----------------------
        // 指令示例:    addi x3, x4, 0x5  二进制简化:    32'h00504183
        // 各字段解析:    
        // opcode: 7'b0000011 (`I_arith)
        // rs1: 5'b00100 (x4)
        // rd: 5'b00011 (x3)
        // funct3: 3'b000 (addi对应funct3=000)
        // 立即数: 0x5 (对应instr[31:20]=0x5)
        instr = 32'h00504183;
        #20;
        print_result("I_TYPE (addi)");

        // ---------------------- 测试3:    S型指令（存储指令 sw，`S_store`）----------------------
        // 指令示例:    sw x5, 0x8(x6)  二进制简化:    32'h00506223
        // 各字段解析:    
        // opcode: 7'b0100011 (`S_store)
        // rs1: 5'b00110 (x6)
        // rs2: 5'b00101 (x5)
        // funct3: 3'b010 (sw对应funct3=010)
        // 立即数: 0x8 (对应instr[31:25]=0x0, instr[11:7]=0x8，拼接后为0x8)
        instr = 32'h00506223;
        #20;
        print_result("S_TYPE (sw)");

        // ---------------------- 测试4:    B型指令（分支指令 beq，`B_instr`）----------------------
        // 指令示例:    beq x7, x8, 0x10  二进制简化:    32'h00807463
        // 各字段解析:    
        // opcode: 7'b1100011 (`B_instr)
        // rs1: 5'b00111 (x7)
        // rs2: 5'b01000 (x8)
        // funct3: 3'b000 (beq对应funct3=000)
        // 立即数: 0x10 (分支偏移量，拼接后为0x10)
        instr = 32'h00807463;
        #20;
        print_result("B_TYPE (beq)");

        // ---------------------- 测试5:    U型指令（lui，`U_lui`）----------------------
        // 指令示例:    lui x9, 0x12345  二进制简化:    32'h12345437
        // 各字段解析:    
        // opcode: 7'b0110111 (`U_lui)
        // rd: 5'b01001 (x9)
        // 立即数: 0x12345000 (U型立即数左移12位)
        instr = 32'h12345437;
        #20;
        print_result("U_TYPE (lui)");

        // ---------------------- 测试6:    U型指令（auipc，`U_auipc`）----------------------
        // 指令示例:    auipc x10, 0x67890  二进制简化:    32'h678904B7
        // 各字段解析:    
        // opcode: 7'b0010111 (`U_auipc)
        // rd: 5'b01010 (x10)
        // 立即数: 0x67890000 (U型立即数左移12位)
        instr = 32'h678904B7;
        #20;
        print_result("U_TYPE (auipc)");

        // ---------------------- 测试7:    J型指令（jal，`J_jal`）----------------------
        // 指令示例:    jal x11, 0x20  二进制简化:    32'h000005EF
        // 各字段解析:    
        // opcode: 7'b1101111 (`J_jal)
        // rd: 5'b01011 (x11)
        // 立即数: 0x20 (跳转偏移量，拼接后为0x20)
        instr = 32'h000005EF;
        #20;
        print_result("J_TYPE (jal)");

        // ---------------------- 仿真结束 ----------------------
        #50;
        $display("=====================================");
        $display("Test Finished ,all instr have tested！");
        $display("=====================================");
        $finish; // 终止仿真
    end

    // 自定义打印函数,简化调试,清晰展示结果
    task print_result;
        input [31:0] msg; // 指令类型说明
        begin
            $display("=====================================");
            $display("Instr :    %s", msg);
            $display("Input instr(Hex):    %h", instr);
            $display("Decode outcome:    ");
            $display("  opcode:   %b (Hex:    %h)", opcode, opcode);
            $display("  rs1:      %b (Decimal:    %d)", rs1, rs1);
            $display("  rs2:      %b (Decimal:    %d)", rs2, rs2);
            $display("  rd:       %b (Decimal:    %d)", rd, rd);
            $display("  funct3:   %b", funct3);
            $display("  funct7:   %b", funct7);
            $display("  imme:     %h (Decimal:    %d)", imme, imme);
            $display("=====================================");
            $display("");
        end
    endtask

    initial begin
        $dumpfile("tb_instr_decode.vcd"); // 波形文件保存路径
        $dumpvars(0, tb_instr_decode);    // 捕获所有模块的信号波形
    end

endmodule