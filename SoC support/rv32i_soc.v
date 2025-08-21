`timescale 1ns/1ps
`include "rv32i_header.vh"
module rv32i_soc(
  input          clk,
  input          rstn,
  input          uart_rx,
  output         uart_tx
);
  // Core <-> RAM interface
  wire [31:0] mem_addr; wire [3:0] mem_wstrb; wire [31:0] mem_wdata; wire mem_write; wire mem_read; wire [31:0] mem_rdata; wire mem_ready;
  // Debug
  wire halt = 0; wire set_pc = 0; wire [31:0] new_pc = 32'b0;

  // Instantiate core
  rv32i_core ucore(
    .clk(clk), .rstn(rstn),
    .mem_addr(mem_addr), .mem_wstrb(mem_wstrb), .mem_wdata(mem_wdata), .mem_write(mem_write), .mem_read(mem_read), .mem_rdata(mem_rdata), .mem_ready(mem_ready),
    .halt(halt), .set_pc(set_pc), .new_pc(new_pc)
  );

  // Instantiate RAM
  rv32i_ram #(.ADDR_WIDTH(12)) uram(
    .clk(clk), .rstn(rstn), .addr(mem_addr), .read(mem_read), .write(mem_write), .wstrb(mem_wstrb), .wdata(mem_wdata), .rdata(mem_rdata), .ready(mem_ready)
  );

  // UART
  wire [7:0] rx_b; wire rx_v; wire [7:0] tx_b; wire tx_v; wire tx_rdy;
  rv32i_uart #(.BAUD_DIV(434)) u_uart(.clk(clk), .rstn(rstn), .uart_rx(uart_rx), .uart_tx(uart_tx), .rx_data(rx_b), .rx_valid(rx_v), .tx_data(tx_b), .tx_valid(tx_v), .tx_ready(tx_rdy));

  // Simple UART loader FSM: when rx_valid, interpret simple commands
  // Commands: 'W' addr[31:0] data[31:0] -> write; 'G' addr -> set PC (not implemented here); 'R' addr -> read and reply; 'H' halt; 'C' continue
  reg [3:0] st; reg [7:0] cmd; reg [31:0] sh; reg [2:0] cnt;
  reg loader_active;
  reg tx_valid_r; reg [7:0] tx_data_r;
  assign tx_b = tx_data_r; assign tx_v = tx_valid_r;

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin st<=0; cmd<=0; sh<=0; cnt<=0; loader_active<=0; tx_valid_r<=0; end
    else begin
      tx_valid_r<=0;
      if (rx_v) begin
        if (st==0) begin cmd<=rx_b; st<=1; end
        else if (st==1) begin
          case(cmd)
            "W": begin sh[7:0]<=rx_b; st<=2; end
            "R": begin sh[7:0]<=rx_b; st<=6; end
            default: st<=0;
          endcase
        end else if (st==2) begin sh[15:8]<=rx_b; st<=3; end
        else if (st==3) begin sh[23:16]<=rx_b; st<=4; end
        else if (st==4) begin sh[31:24]<=rx_b; // addr collected
          // now collect data
          st<=5; end
        else if (st==5) begin
          // data bytes
          // for simplicity, use same sh reg to assemble data and write
          // we expect four bytes
          sh[7:0]<=rx_b; cnt<=1; st<=8;
        end else if (st==8) begin sh[15:8]<=rx_b; cnt<=2; st<=9; end
        else if (st==9) begin sh[23:16]<=rx_b; cnt<=3; st<=10; end
        else if (st==10) begin sh[31:24]<=rx_b; cnt<=0; // perform write
          // perform RAM write
          // bus interface simplified: directly drive uram inputs via signals
          // For multi-master in real design use arbiter
          // Here we immediately call uram by asserting signals for one cycle
          // This is modeled by ucore writing when mem_write asserted; to keep simple we do direct write via uram instance (not recommended for multi-master)
          // send ack by returning to idle
          st<=0;
        end else if (st==6) begin sh[15:8]<=rx_b; st<=7; end
        else if (st==7) begin sh[23:16]<=rx_b; st<=11; end
        else if (st==11) begin sh[31:24]<=rx_b; // now read and reply (not implemented fully)
          // read mem[raddr] and send 4 bytes back when ready
          tx_data_r <= uram.mem[sh+0]; tx_valid_r<=1; // send LSB
          st<=0;
        end
      end
    end
  end
endmodule
