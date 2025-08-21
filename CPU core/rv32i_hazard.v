`timescale 1ns/1ps
module rv32i_hazard(
input [4:0] rs1_id,
input [4:0] rs2_id,
input [4:0] rd_ex,
input memread_ex,
output pc_write,
output if_id_write,
output control_stall
);
reg pcw, idw, cstall;
always @(*) begin
if (memread_ex && ((rd_ex==rs1_id) || (rd_ex==rs2_id))) begin
pcw = 0; idw = 0; cstall = 1; // stall one cycle
end else begin
pcw = 1; idw = 1; cstall = 0;
end
end
assign pc_write = pcw;
assign if_id_write = idw;
assign control_stall = cstall;
endmodule
