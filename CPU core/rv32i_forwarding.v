`timescale 1ns/1ps
module rv32i_forwarding(
input [4:0] rs1_id,
input [4:0] rs2_id,
input [4:0] rd_ex,
input regwrite_ex,
input [4:0] rd_mem,
input regwrite_mem,
output [1:0] forwardA, // 00=ID, 10=EX, 01=MEM
output [1:0] forwardB
);
reg [1:0] fA, fB;
always @(*) begin
fA=2'b00; fB=2'b00;
if (regwrite_ex && (rd_ex!=0) && (rd_ex==rs1_id)) fA=2'b10;
else if (regwrite_mem && (rd_mem!=0) && (rd_mem==rs1_id)) fA=2'b01;
if (regwrite_ex && (rd_ex!=0) && (rd_ex==rs2_id)) fB=2'b10;
else if (regwrite_mem && (rd_mem!=0) && (rd_mem==rs2_id)) fB=2'b01;
end
assign forwardA = fA;
assign forwardB = fB;
endmodule
