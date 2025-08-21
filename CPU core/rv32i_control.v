`timescale 1ns/1ps
reg [1:0] alus;
reg [2:0] mwid;
always @(*) begin
rw=0; mr=0; mw=0; br=0; jmp=0; alus=2'b00; aluop_r=`ALU_ADD; mwid=3'b010;
case(opcode)
7'b0110111: begin // LUI
rw=1; alus=2'b11; aluop_r=`ALU_PASSB; end
7'b0010111: begin // AUIPC
rw=1; alus=2'b11; aluop_r=`ALU_ADD; end
7'b1101111: begin // JAL
rw=1; jmp=1; alus=2'b00; aluop_r=`ALU_PASSB; end
7'b1100111: begin // JALR
rw=1; jmp=1; alus=2'b01; aluop_r=`ALU_PASSB; end
7'b1100011: begin // BRANCH
br=1; alus=2'b00; aluop_r=`ALU_SUB; end
7'b0000011: begin // LOAD
rw=1; mr=1; alus=2'b01; aluop_r=`ALU_ADD; mwid=3'b010; end
7'b0100011: begin // STORE
mw=1; alus=2'b01; aluop_r=`ALU_ADD; mwid=3'b010; end
7'b0010011: begin // OP-IMM
rw=1; alus=2'b01;
case(funct3)
3'b000: aluop_r=`ALU_ADD; // ADDI
3'b111: aluop_r=`ALU_AND; // ANDI
3'b110: aluop_r=`ALU_OR; // ORI
3'b100: aluop_r=`ALU_XOR; // XORI
3'b001: aluop_r=`ALU_SLL; // SLLI
3'b101: aluop_r=`ALU_SRL; // SRLI/SRAI (funct7 must be checked in core)
default: aluop_r=`ALU_ADD;
endcase
end
7'b0110011: begin // OP
rw=1; alus=2'b00;
case(funct3)
3'b000: aluop_r = (funct7[5])?`ALU_SUB:`ALU_ADD; // SUB/ADD
3'b111: aluop_r = `ALU_AND;
3'b110: aluop_r = `ALU_OR;
3'b100: aluop_r = `ALU_XOR;
3'b001: aluop_r = `ALU_SLL;
3'b101: aluop_r = (funct7[5])?`ALU_SRA:`ALU_SRL;
default: aluop_r=`ALU_ADD;
endcase
end
default: begin end
endcase
end
assign reg_write = rw;
assign mem_read = mr;
assign mem_write = mw;
assign branch = br;
assign jump = jmp;
assign alu_src = alus;
assign alu_op = aluop_r;
assign mem_width = mwid;
endmodule
