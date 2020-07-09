`include "source/ClockDivider.v"

// 1 ns unit, 10 ps precision.
`timescale 1ns/10ps

module ClockDivider_TB();

	reg clock = 0;
	reg[23:0] clock_divider = 1;
	wire output_clock;
	
	ClockDivider target(
		clock,
		clock_divider,
		output_clock
	);
	
	initial begin
		clock_divider <= 0;
		#10 clock <= 0;
		#10 clock <= 1;
		#10 clock <= 0;
		#10 clock <= 1;
		#10 clock <= 0;
		#10 clock <= 1;
		#10 clock <= 0;
		#10 clock <= 1;
		#10 clock <= 0;
		#10 clock <= 1;
		#10 clock <= 0;
		#10 clock <= 1;
		clock_divider <= 1;
		#10 clock <= 0;
		#10 clock <= 1;
		#10 clock <= 0;
		#10 clock <= 1;
		#10 clock <= 0;
		#10 clock <= 1;
		#10 clock <= 0;
		#10 clock <= 1;
		#10 clock <= 0;
		#10 clock <= 1;
		#10 clock <= 0;
		#10 clock <= 1;
		clock_divider <= 2;
		#10 clock <= 0;
		#10 clock <= 1;
		#10 clock <= 0;
		#10 clock <= 1;
		#10 clock <= 0;
		#10 clock <= 1;
		#10 clock <= 0;
		#10 clock <= 1;
		#10 clock <= 0;
		#10 clock <= 1;
		#10 clock <= 0;
		#10 clock <= 1;
		#10 clock <= 0;
		#10 clock <= 1;
		clock_divider <= 3;
		#10 clock <= 0;
		#10 clock <= 1;
		#10 clock <= 0;
		#10 clock <= 1;
		#10 clock <= 0;
		#10 clock <= 1;
		#10 clock <= 0;
		#10 clock <= 1;
		#10 clock <= 0;
		#10 clock <= 1;
		#10 clock <= 0;
		#10 clock <= 1;
		#10 clock <= 0;
		#10 clock <= 1;
		clock_divider <= 4;
		#10 clock <= 0;
		#10 clock <= 1;
		#10 clock <= 0;
		#10 clock <= 1;
		#10 clock <= 0;
		#10 clock <= 1;
		#10 clock <= 0;
		#10 clock <= 1;
		#10 clock <= 0;
		#10 clock <= 1;
		#10 clock <= 0;
		#10 clock <= 1;
		#10 clock <= 0;
		#10 clock <= 1;
		#10 clock <= 0;
		#10 clock <= 1;
		clock_divider <= 5;
		#10 clock <= 0;
		#10 clock <= 1;
		#10 clock <= 0;
		#10 clock <= 1;
		#10 clock <= 0;
		#10 clock <= 1;
		#10 clock <= 0;
		#10 clock <= 1;
		#10 clock <= 0;
		#10 clock <= 1;
		#10 clock <= 0;
		#10 clock <= 1;
		#10 clock <= 0;
		#10 clock <= 1;
		#10 clock <= 0;
		#10 clock <= 1;

		// Tested by visual inspection.

		$finish();
	end
	
	initial begin
		$dumpfile("build/dump.vcd");
		$dumpvars(0);
	end
	
endmodule
