# Pipelined-RISC-V-core-design

This project is a minimal, didactic RV32I SoC with a 5-stage pipeline (IF, ID, EX, MEM, WB).
It is intended for learning, simulation, and as a starting point for SoC integration.

Files (Batch 1 - CPU core):
- rv32i_header.vh : ALU op definitions
- rv32i_basereg.v : Register file (x0 hardwired to zero)
- rv32i_alu.v : ALU implementation
- rv32i_immgen.v : Immediate generator
- rv32i_control.v : Control unit mapping opcodes -> control signals
- rv32i_forwarding.v : Forwarding unit
- rv32i_hazard.v : Hazard detection unit
- rv32i_pipeline_regs.v : Placeholder (pipeline regs implemented inside core)
- rv32i_core.v : Top CPU core wiring and pipeline stages


Files (Batch 2 - SoC support):
- rv32i_ram.v : Simple synchronous byte-addressable RAM
- rv32i_uart.v : Byte-level UART RX/TX (loader stub)
- rv32i_soc.v : Top-level wrapper (core + ram + uart)


Files (Batch 3 - Testbench):
- tb_rv32i_soc.v : Testbench that preloads program and verifies result



