`timescale 1ns/1ps
module tb_rv32i_soc;
  reg clk = 0; always #10 clk = ~clk; // 50 MHz
  reg rstn = 0;
  reg uart_rx = 1; wire uart_tx;

  // Instantiate SoC
  rv32i_soc dut(.clk(clk), .rstn(rstn), .uart_rx(uart_rx), .uart_tx(uart_tx));

  // Access to RAM instance for preload/inspection (testbench uses hierarchical path)
  integer i;

  initial begin
    // reset
    rstn = 0; repeat(10) @(posedge clk); rstn = 1;

    // preload a simple program into RAM (direct memory access for testbench)
    // Program at address 0x0000:
    // addi x1,x0,5
    // addi x2,x0,7
    // add x3,x1,x2
    // sw x3,0x100(x0)
    // jal x0,0
    reg [31:0] instrs [0:4];
    instrs[0] = 32'h00500093; // addi x1,x0,5
    instrs[1] = 32'h00700113; // addi x2,x0,7
    instrs[2] = 32'h002081b3; // add x3,x1,x2
    instrs[3] = 32'h00312023; // sw x3,0x100(x0)
    instrs[4] = 32'h0000006f; // jal x0,0

    // write instructions into uram.mem (little-endian)
    for (i=0;i<5;i=i+1) begin
      dut.uram.mem[i*4+0] = instrs[i][7:0];
      dut.uram.mem[i*4+1] = instrs[i][15:8];
      dut.uram.mem[i*4+2] = instrs[i][23:16];
      dut.uram.mem[i*4+3] = instrs[i][31:24];
    end

    // run
    repeat(2000) @(posedge clk);

    // check memory at 0x100
    reg [31:0] res;
    res = {dut.uram.mem[256+3], dut.uram.mem[256+2], dut.uram.mem[256+1], dut.uram.mem[256+0]};
    $display("Memory[0x100] = %0d (expected 12)", res);
    if (res == 32'd12) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule





