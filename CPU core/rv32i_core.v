`timescale 1ns/1ps
`include "rv32i_header.vh"
module rv32i_core(
input clk,
input rstn,
// memory interface (simple unified sync RAM ports)
output reg [31:0] mem_addr,
output reg [3:0] mem_wstrb,
output reg [31:0] mem_wdata,
output reg mem_write,
output reg mem_read,
input [31:0] mem_rdata,
input mem_ready,
// debug / control
input halt,
input set_pc,
input [31:0] new_pc
);
// IF stage
reg [31:0] pc_f;
wire [31:0] instr_f;
reg if_valid;


// IF/ID regs
reg [31:0] pc_id;
reg [31:0] instr_id;


// ID signals
wire [6:0] opcode = instr_id[6:0];
wire [4:0] rd_id = instr_id[11:7];
wire [2:0] funct3_id= instr_id[14:12];
wire [4:0] rs1_id = instr_id[19:15];
wire [4:0] rs2_id = instr_id[24:20];
wire [6:0] funct7_id= instr_id[31:25];

// immediate generation
wire [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;
rv32i_immgen uimm(.instr(instr_id), .imm_i(imm_i), .imm_s(imm_s), .imm_b(imm_b), .imm_u(imm_u), .imm_j(imm_j));


// control
wire reg_write_id, mem_read_id, mem_write_id, branch_id, jump_id;
wire [1:0] alu_src_id;
wire [3:0] alu_op_id;
wire [2:0] mem_width_id;
rv32i_control uctrl(.opcode(opcode), .funct3(funct3_id), .funct7(funct7_id), .reg_write(reg_write_id), .mem_read(mem_read_id), .mem_write(mem_write_id), .branch(branch_id), .jump(jump_id), .alu_src(alu_src_id), .alu_op(alu_op_id), .mem_width(mem_width_id));



// register file
wire [31:0] rs1_rdata, rs2_rdata;
reg regfile_we; reg [4:0] regfile_waddr; reg [31:0] regfile_wdata;
rv32i_basereg ureg(.clk(clk), .rstn(rstn), .we(regfile_we), .waddr(regfile_waddr), .wdata(regfile_wdata), .raddr1(rs1_id), .rdata1(rs1_rdata), .raddr2(rs2_id), .rdata2(rs2_rdata));


// ID/EX regs
reg [31:0] pc_ex, imm_ex, rs1_ex, rs2_ex; reg [4:0] rd_ex; reg [3:0] aluop_ex; reg [1:0] alusrc_ex; reg memread_ex, memwrite_ex, regwrite_ex; reg branch_ex, jump_ex; reg [2:0] funct3_ex;


// EX stage
wire [31:0] alu_in1, alu_in2, alu_out;
// forwarding signals
wire [1:0] forwardA, forwardB;
rv32i_forwarding ufwd(.rs1_id(rs1_id), .rs2_id(rs2_id), .rd_ex(rd_ex), .regwrite_ex(regwrite_ex), .rd_mem(rd_mem), .regwrite_mem(regwrite_mem), .forwardA(forwardA), .forwardB(forwardB));


// For simplicity we'll implement forwarding sources inside EX logic below


rv32i_alu ualu(.a(alu_in1), .b(alu_in2), .op(aluop_ex), .y(alu_out));
// EX/MEM regs
reg [31:0] alu_mem, rs2_mem; reg [4:0] rd_mem; reg memread_mem, memwrite_mem, regwrite_mem; reg [2:0] funct3_mem;


// MEM stage: memory interface is shared
// MEM/WB regs
reg [31:0] mem_rdata_wb; reg [31:0] alu_wb; reg [4:0] rd_wb; reg regwrite_wb;


// Hazard detection
wire pc_write, if_id_write, control_stall;
rv32i_hazard uhz(.rs1_id(rs1_id), .rs2_id(rs2_id), .rd_ex(rd_ex), .memread_ex(memread_ex), .pc_write(pc_write), .if_id_write(if_id_write), .control_stall(control_stall));


// Instruction fetch from unified RAM: simple read via mem interface
// For fetch: put mem_addr=pc_f, mem_read=1, when mem_ready asserted capture mem_rdata
reg fetch_req;
assign instr_f = mem_rdata; // combinational mapping (assumes mem_ready timing managed externally)


// ------------------ FETCH stage ---------------------
always @(posedge clk or negedge rstn) begin
if (!rstn) begin
pc_f <= 32'b0; fetch_req <= 0; if_valid<=0;
end else begin
if (set_pc) begin pc_f <= new_pc; end
else if (!halt && pc_write) begin pc_f <= pc_f + 4; end
// request read
mem_addr <= pc_f; mem_read <= 1'b1; mem_write <= 1'b0; mem_wstrb <= 4'b0000;
// capturing is left to MEM ready; simplified model: assume mem_ready cycles in same cycle
end
end
// ---------------- IF/ID -------------------------------
always @(posedge clk or negedge rstn) begin
if (!rstn) begin
pc_id <= 0; instr_id <= 32'h00000013; // NOP
end else begin
if (if_id_write) begin pc_id <= pc_f; instr_id <= instr_f; end
if (control_stall) instr_id <= 32'h00000013; // insert NOP
end
end


// ---------------- ID/EX -------------------------------
always @(posedge clk or negedge rstn) begin
if (!rstn) begin
pc_ex<=0; imm_ex<=0; rs1_ex<=0; rs2_ex<=0; rd_ex<=0; aluop_ex<=`ALU_ADD; alusrc_ex<=2'b00; memread_ex<=0; memwrite_ex<=0; regwrite_ex<=0; branch_ex<=0; jump_ex<=0; funct3_ex<=0;
end else begin
pc_ex <= pc_id; imm_ex <= imm_i; rs1_ex <= rs1_rdata; rs2_ex <= rs2_rdata; rd_ex <= rd_id; aluop_ex <= alu_op_id; alusrc_ex <= alu_src_id; memread_ex<=mem_read_id; memwrite_ex<=mem_write_id; regwrite_ex<=reg_write_id; branch_ex<=branch_id; jump_ex<=jump_id; funct3_ex<=mem_width_id;
end
end

/ ---------------- EX logic ---------------------------
wire [31:0] forwarded_a = (forwardA==2'b10)? alu_out : (forwardA==2'b01)? mem_rdata_wb : rs1_ex; // simplified
wire [31:0] forwarded_b = (forwardB==2'b10)? alu_out : (forwardB==2'b01)? mem_rdata_wb : rs2_ex;
assign alu_in1 = forwarded_a;
assign alu_in2 = (alusrc_ex==2'b00) ? forwarded_b : (alusrc_ex==2'b01 ? imm_ex : (alusrc_ex==2'b10 ? imm_ex : imm_ex));


always @(posedge clk or negedge rstn) begin
if (!rstn) begin
alu_mem<=0; rs2_mem<=0; rd_mem<=0; memread_mem<=0; memwrite_mem<=0; regwrite_mem<=0; funct3_mem<=0;
end else begin
alu_mem <= alu_out; rs2_mem <= forwarded_b; rd_mem <= rd_ex; memread_mem<=memread_ex; memwrite_mem<=memwrite_ex; regwrite_mem<=regwrite_ex; funct3_mem<=funct3_ex;
end
end


// ---------------- MEM stage --------------------------
always @(posedge clk or negedge rstn) begin
if (!rstn) begin
mem_addr<=0; mem_wdata<=0; mem_wstrb<=0; mem_write<=0; mem_read<=0; mem_rdata_wb<=0;
end else begin
if (memread_mem) begin
mem_addr <= alu_mem; mem_read <= 1; mem_write <= 0; mem_wstrb<=4'b0000;
// assume mem_ready and mem_rdata available next cycle
mem_rdata_wb <= mem_rdata;
end else if (memwrite_mem) begin
mem_addr <= alu_mem; mem_wdata <= rs2_mem; mem_wstrb<=4'b1111; mem_write<=1; mem_read<=0;
end else begin
mem_read<=0; mem_write<=0; mem_wstrb<=4'b0000;
end
end
end
// ---------------- WB stage ---------------------------
always @(posedge clk or negedge rstn) begin
if (!rstn) begin
regfile_we<=0; regfile_waddr<=0; regfile_wdata<=0; rd_wb<=0; regwrite_wb<=0; alu_wb<=0;
end else begin
rd_wb <= rd_mem; alu_wb <= alu_mem; regwrite_wb <= regwrite_mem;
if (regwrite_mem) begin
// select mem or alu
if (memread_mem) begin regfile_we<=1; regfile_waddr<=rd_mem; regfile_wdata<=mem_rdata_wb; end
else begin regfile_we<=1; regfile_waddr<=rd_mem; regfile_wdata<=alu_mem; end
end else begin regfile_we<=0; end
end
end
endmodule


