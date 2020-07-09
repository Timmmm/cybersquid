`include "source/UARTReceiver.v"

// 1 ns unit, 10 ps precision.
`timescale 1ns/10ps

module UARTReceiver_TB();

	// 10 MHz clock, so clock period ist 100 ns.
	// 1 MHz baud so it takes 10 cycles per bit.
	parameter CLOCKS_PER_BIT = 5;
	parameter CLOCK_PERIOD_NS = 10;

	reg clock = 0;

	wire input_valid;
	wire[7:0] input_data;
	reg serial_rx = 1;

	UARTReceiver #(
		.CLOCKS_PER_BIT(CLOCKS_PER_BIT)
	) target (
		clock,
		serial_rx,
		input_valid,
		input_data
	);

	always
		#(CLOCK_PERIOD_NS/2) clock <= !clock;

	task transmit_byte(input [7:0] data);
		begin
			#(CLOCKS_PER_BIT * CLOCK_PERIOD_NS) serial_rx = 0;
			#(CLOCKS_PER_BIT * CLOCK_PERIOD_NS) serial_rx = data[0];
			#(CLOCKS_PER_BIT * CLOCK_PERIOD_NS) serial_rx = data[1];
			#(CLOCKS_PER_BIT * CLOCK_PERIOD_NS) serial_rx = data[2];
			#(CLOCKS_PER_BIT * CLOCK_PERIOD_NS) serial_rx = data[3];
			#(CLOCKS_PER_BIT * CLOCK_PERIOD_NS) serial_rx = data[4];
			#(CLOCKS_PER_BIT * CLOCK_PERIOD_NS) serial_rx = data[5];
			#(CLOCKS_PER_BIT * CLOCK_PERIOD_NS) serial_rx = data[6];
			#(CLOCKS_PER_BIT * CLOCK_PERIOD_NS) serial_rx = data[7];
			#(CLOCKS_PER_BIT * CLOCK_PERIOD_NS) serial_rx = 1;
		end
	endtask

	initial begin
		#(CLOCK_PERIOD_NS * CLOCKS_PER_BIT);
		transmit_byte(8'b01010011); // 0x53
		#(CLOCK_PERIOD_NS * CLOCKS_PER_BIT * 4);
		transmit_byte(8'b00010001); // 0x11
		transmit_byte(8'b00100010); // 0x22
		#(CLOCK_PERIOD_NS * CLOCKS_PER_BIT * 15);
		$finish();
	end

	initial begin
		$dumpfile("build/dump.vcd");
		$dumpvars(0);
	end

endmodule
