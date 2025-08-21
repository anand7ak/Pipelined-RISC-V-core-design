`timescale 1ns/1ps
module rv32i_uart #(
  parameter BAUD_DIV = 434
)(
  input          clk,
  input          rstn,
  input          uart_rx,
  output         uart_tx,
  // Simple byte-level interface
  output reg [7:0] rx_data,
  output reg       rx_valid,
  input      [7:0] tx_data,
  input            tx_valid,
  output reg       tx_ready
);
  // Instantiate small RX/TX cores
  // RX
  reg [15:0] rx_cnt; reg [3:0] rx_bit; reg rx_busy; reg rx_d1, rx_d2;
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin rx_cnt<=0; rx_bit<=0; rx_busy<=0; rx_valid<=0; rx_data<=0; rx_d1<=1; rx_d2<=1; end
    else begin
      rx_valid<=0; rx_d1<=uart_rx; rx_d2<=rx_d1;
      if (!rx_busy) begin
        if (!rx_d2) begin rx_busy<=1; rx_cnt<=BAUD_DIV+BAUD_DIV/2; rx_bit<=0; end
      end else begin
        if (rx_cnt==0) begin
          rx_cnt<=BAUD_DIV;
          if (rx_bit<8) begin rx_data[rx_bit]<=rx_d2; rx_bit<=rx_bit+1; end
          else if (rx_bit==8) begin rx_bit<=rx_bit+1; end
          else begin rx_busy<=0; rx_valid<=1; end
        end else rx_cnt<=rx_cnt-1;
      end
    end
  end
  // TX
  reg [15:0] tx_cnt; reg [3:0] tx_bit; reg tx_busy; reg [7:0] tx_shift; reg tx_reg;
  assign uart_tx = tx_reg;
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin tx_cnt<=0; tx_bit<=0; tx_busy<=0; tx_ready<=1; tx_shift<=0; tx_reg<=1; end
    else begin
      if (!tx_busy) begin
        tx_ready<=1;
        if (tx_valid) begin tx_busy<=1; tx_shift<=tx_data; tx_reg<=0; tx_cnt<=BAUD_DIV; tx_bit<=0; tx_ready<=0; end
      end else begin
        if (tx_cnt==0) begin
          tx_cnt<=BAUD_DIV;
          if (tx_bit<8) begin tx_reg<=tx_shift[tx_bit]; tx_bit<=tx_bit+1; end
          else if (tx_bit==8) begin tx_reg<=1; tx_bit<=tx_bit+1; end
          else begin tx_busy<=0; tx_ready<=1; end
        end else tx_cnt<=tx_cnt-1;
      end
    end
  end
endmodule
