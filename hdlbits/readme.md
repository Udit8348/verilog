# HDLBits

Repo of Verilog Practice Exercises from the HDLBits Curriculum. Good practice to help memorize core syntax and constructs.

## Workflow
HDLBits provides an online code editor that executes Quartus Prime Analysis Shell to synthesize the submission and verify its functionality.

```
quartus_sh -t /home/h/hdlbits/compile.tcl
...
Info (23030): Evaluation of Tcl script /home/h/hdlbits/compile.tcl was successful
```

Then, ModelSim simulates the top level module against a hidden test bench.
```
Reading pref.tcl

# 2020.1

# do /home/h/hdlbits/runsim.do
# Model Technology ModelSim - Intel FPGA Edition vlog 2020.1 Compiler 2020.02 Feb 28 2020
# Start time: 21:47:02 on May 23,2026
# vlog -sv tb.sv "+incdir+../../hdlbits" 
# -- Compiling module reference_module
# -- Compiling module stimulus_gen
# -- Compiling module tb
# -- Compiling module wavedrom_mod
# 
# Top level modules:
# 	tb
# End time: 21:47:02 on May 23,2026, Elapsed time: 0:00:00
# Errors: 0, Warnings: 0
# Model Technology ModelSim - Intel FPGA Edition vlog 2020.1 Compiler 2020.02 Feb 28 2020
# Start time: 21:47:02 on May 23,2026
# vlog top_module.vo 
# -- Compiling module top_module
# 
# Top level modules:
# 	top_module
# End time: 21:47:02 on May 23,2026, Elapsed time: 0:00:00
# Errors: 0, Warnings: 0
# vsim -c -t 1ps -L cyclonev_ver -L altera_ver -L altera_mf_ver -L 220model_ver -L sgate_ver -L altera_lnsim_ver work.tb -voptargs=""+acc"" 
# Start time: 21:47:02 on May 23,2026
# Loading sv_std.std
# Loading work.tb
# Loading work.stimulus_gen
# Loading work.reference_module
# Loading work.top_module
# Loading cyclonev_ver.cyclonev_io_obuf
# Loading cyclonev_ver.cyclonev_io_ibuf
# Loading work.wavedrom_mod
# ** Note: $finish    : tb.sv(35)
#    Time: 1080 ps  Iteration: 1  Instance: /tb/stim1
# Hint: Output 'w' has no mismatches.
# Hint: Output 'x' has no mismatches.
# Hint: Output 'y' has no mismatches.
# Hint: Output 'z' has no mismatches.
# Hint: Total mismatched samples is 0 out of 215 samples
# 
# Simulation finished at 1080 ps
# Mismatches: 0 in 215 samples
# End time: 21:47:02 on May 23,2026, Elapsed time: 0:00:00
# Errors: 0, Warnings: 0
```
