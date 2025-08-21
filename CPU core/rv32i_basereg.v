`timescale 1ns/1ps
module rv32i_basereg(
input clk,
input rstn,
input we,
input [4:0] waddr,
input [31:0] wdata,
input [4:0] raddr1,
output [31:0] rdata1,
input [4:0] raddr2,
output [31:0] rdata2
);
reg [31:0] regs[31:0];
integer i;
always @(negedge rstn) begin
if (!rstn) begin
for(i=0;i<32;i=i+1) regs[i]=32'b0;
end
end
assign rdata1 = (raddr1==0) ? 32'b0 : regs[raddr1];
assign rdata2 = (raddr2==0) ? 32'b0 : regs[raddr2];
always @(posedge clk) begin
if (we && waddr!=0) regs[waddr] <= wdata;
end
endmodule
