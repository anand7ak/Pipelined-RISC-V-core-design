`timescale 1ns/1ps
module rv32i_ram #(
  parameter ADDR_WIDTH = 16, // bytes addressed memory
  parameter INIT_FILE = ""
)(
  input                clk,
  input                rstn,
  // Simple bus: address, read, write, wstrb, wdata, rdata, ready
  input  [31:0]        addr,
  input                read,
  input                write,
  input   [3:0]        wstrb,
  input  [31:0]        wdata,
  output reg [31:0]    rdata,
  output reg           ready
);
  localparam DEPTH = (1<<ADDR_WIDTH);
  reg [7:0] mem [0:DEPTH-1];
  integer i;
  initial begin
    if (INIT_FILE!="") begin
      $display("Loading RAM init file: %s", INIT_FILE);
      $readmemh(INIT_FILE, mem);
    end else begin
      for (i=0;i<DEPTH;i=i+1) mem[i] = 8'h00;
    end
  end

  // Simple synchronous read/write with one-cycle latency
  always @(posedge clk) begin
    ready <= 1'b0;
    if (write) begin
      if (wstrb[0]) mem[addr+0] <= wdata[7:0];
      if (wstrb[1]) mem[addr+1] <= wdata[15:8];
      if (wstrb[2]) mem[addr+2] <= wdata[23:16];
      if (wstrb[3]) mem[addr+3] <= wdata[31:24];
      ready <= 1'b1;
      rdata <= 32'b0;
    end else if (read) begin
      rdata <= {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr+0]};
      ready <= 1'b1;
    end
  end
endmodule
