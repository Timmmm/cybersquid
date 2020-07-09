# How To Do FPGA Stuff

## Simulating / Testing Verilog

1. Use Icarus Verilog (`iverilog`).
2. Download and install Windows binaries from [here](http://bleyer.org/icarus/).
3. During installation allow it to install GTKWave, and select the "Add installation folders to the user PATH" option.
4. Start a shell. Run a command like this:

    iverilog -o out.vvp Module.v TestBench.v

Where the `TestBench.v` is written in normal Verilog test bench style. This compiles the Verilog into some kind of assembly-like IR that can be executed by `vvp`.

5. Execute it

    vvp out.vvp

6. This will print the test results (assuming your code has `$display()` commands), and write the signals to disk (assuming your code runs `$dumpfile("dump.vcd"); $dumpvars(0);`).

7. Now view the results in GTKWave.

    gtkwave out.vvp