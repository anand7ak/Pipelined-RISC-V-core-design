`timescale 1ns/1ps
module rv32i_immgen(
input [31:0] instr,
output [31:0] imm_i,
output [31:0] imm_s,
output [31:0] imm_b,
output [31:0] imm_u,
output [31:0] imm_j
);
assign imm_i = {{20{instr[31]}}, instr[31:20]};
assign imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};
assign imm_b = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
assign imm_u = {instr[31:12], 12'b0};
assign imm_j = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
endmodule
