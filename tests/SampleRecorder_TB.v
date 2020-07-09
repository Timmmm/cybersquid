`include "source/SampleRecorder.v"

// 1 ns unit, 10 ps precision.
`timescale 1ns/10ps

module SampleRecorder_TB();
	reg clock;
	reg run = 0;
	reg[15:0] flags = 0;
	reg[23:0] clock_divider = 0;
	reg[10:0] read_count_x4 = 0;
	reg[10:0] trigger_delay_x4 = 0;
	reg[7:0] trigger_mask = 8'b00000111;
	reg[7:0] trigger_value = 8'b00000101;
	reg[7:0] trigger_config = 0;
	reg[7:0] trigger_edge = 0;
	reg[7:0] channels = 0;

	wire write_en;
	wire[12:0] write_address;
	wire[7:0] write_data;

	wire finished;

	SampleRecorder target(
		clock,
		run,
		flags,
		clock_divider,
		read_count_x4,
		trigger_delay_x4,
		trigger_mask,
		trigger_value,
		trigger_config,
		trigger_edge,
		channels,
		write_en,
		write_address,
		write_data,
		finished
	);
	
	initial begin
		read_count_x4 <= 25;
		trigger_delay_x4 <= 12;
		#10 clock <= 0;
		#10 clock <= 1;
		#10 clock <= 0;
		#10 clock <= 1;
		#10 clock <= 0;
		#10 clock <= 1;
		#10 clock <= 0;
		run <= 1;
		#10 clock <= 1;
		#10 clock <= 0;
		run <= 0;
		#10 clock <= 1;
		#10 clock <= 0;
		channels <= 1;
		#10 clock <= 1;
		#10 clock <= 0;
		channels <= 2;
		#10 clock <= 1;
		#10 clock <= 0;
		channels <= 3;
		#10 clock <= 1;
		#10 clock <= 0;
		channels <= 4;
		#10 clock <= 1;
		#10 clock <= 0;
		channels <= 5;
		#10 clock <= 1;
		#10 clock <= 0;
		channels <= 6;
		#10 clock <= 1;
		#10 clock <= 0;
		channels <= 7;
		#10 clock <= 1;
		#10 clock <= 0;
		channels <= 8;
		#10 clock <= 1;
		#10 clock <= 0;
		channels <= 9;
		#10 clock <= 1;
		#10 clock <= 0;
		channels <= 10;
		#10 clock <= 1;
		

		$finish();
	end
	
	initial begin
		// Required to dump signals to EPWave
		$dumpfile("build/dump.vcd");
		$dumpvars(0);
	end
	
endmodule
