# Final Project

The task of this project was to design an FMA unit for IEEE754 FP16 using SystemVerilog.

## Overview
This repository contains a 16-bit floating-point fused multiply–add (FMA) implementation (`fma16`) targeting IEEE 754 half precision. The design supports configurable rounding modes and exception flag reporting (invalid, overflow, underflow, inexact), with a pipelined datapath suitable for synthesis.

## Features
- Pipelined fused multiply–add for half precision.
- Operand controls: negate multiplicand/addend (`negr`/`negz`), multiply-only, add-only via `mul`/`add`.
- Rounding modes: 00=RZ, 01=RNE, 10=RP, 11=RN.
- Exception flags: invalid, overflow, underflow, inexact.

## Repository layout
- `rtl/` — core `fma16` implementation and supporting modules.
- `tb/fma_tb.sv` — SystemVerilog testbench driving randomized and directed vectors.
- `tb/tests/` — hex test vector files (default `fma_2.tv`).

## DUT interface (fma16)
- Inputs: `x[15:0]`, `y[15:0]`, `z[15:0]`, `mul`, `add`, `negr`, `negz`, `roundmode[1:0]`, `clk`.
- Outputs: `result[15:0]`, `flags[3:0]` (invalid, overflow, underflow, inexact).
- Control: set `mul/add` to select op; `negr/negz` optionally negate operands before FMA.

## Verification
A SystemVerilog testbench (`tb/fma_tb.sv`) drives randomized and directed vectors to the DUT. Test vectors are read from hex files in `tb/tests/` (default: `fma_2.tv`) and checked cycle-by-cycle for result and flags.

### Running the testbench
Run your preferred simulator and override the test vector file with `+TEST_FILE=<file.tv>` if needed. Passing vectors increment the `passed` counter; mismatches display formatted inputs, outputs, expected values, and flags before finishing with a summary.

1. From repo root, run your simulator (e.g., `vsim -do ./scripts/test_fma.do -c`).
2. Execute with optional plusarg `+TEST_FILE=<file.tv>` to choose a vector set.
3. Pass/fail summary prints at completion; failures show decoded fields and flags for debugging.

### Quick start
- Default run: `vsim -do ./scripts/test_fma.do -c`
- Override vectors: `vsim -do ./scripts/test_fma.do -c +TEST_FILE=fma_special_rne.tv`
- Run all: `./scripts/test_all.bat`

## What works

To run all my tests, please run `./scripts/test_all.bat`

Passed:
- fadd_0.tv
- fadd_1.tv
- fadd_2.tv
- fmul_0.tv
- fmul_1.tv
- fmul_2.tv
- fma_0.tv
- fma_1.tv
- fma_2.tv (failing 4 vectors for unknown reason)
- fma_special_rz.tv
- fma_special_rne.tv
- fma_special_rp.tv
- fma_special_rm.tv (passing 77671/84447 vectors)
- Synthesis at 25Mhz

## What doesn't work

What is yet to be implemented:
- Underflow flag
- Clock staging between hierarchy levels for timing
- Resolving failing vectors in `fma_2.tv` and `fma_special_rm.tv`

## Conclusion
This FP16 FMA meets core functional goals, runs across the provided vector suite, and synthesizes at 25 MHz. Remaining work focuses on completing underflow flagging, tightening timing between hierarchy levels, and resolving the outstanding failures in `fma_2.tv` and `fma_special_rm.tv`.