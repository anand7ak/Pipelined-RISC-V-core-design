`include "rv32i_header.vh"
`timescale 1ns/1ps
module rv32i_alu(
input [31:0] a,
input [31:0] b,
input [3:0] op,
output reg [31:0] y
);
wire [31:0] add = a + b;
wire [31:0] sub = a - b;
wire [31:0] _and= a & b;
wire [31:0] _or = a | b;
wire [31:0] _xor= a ^ b;
wire [31:0] sll = a << b[4:0];
wire [31:0] srl = a >> b[4:0];
wire [31:0] sra = $signed(a) >>> b[4:0];
always @(*) begin
  case(op)
    `ALU_ADD: y = add;
    `ALU_SUB: y = sub;
    `ALU_AND: y = _and;
    `ALU_OR : y = _or;
    `ALU_XOR: y = _xor;
    `ALU_SLL: y = sll;
    `ALU_SRL: y = srl;
    `ALU_SRA: y = sra;
    `ALU_PASSB: y = b;
    default: y = add;
  endcase
end
endmodule
