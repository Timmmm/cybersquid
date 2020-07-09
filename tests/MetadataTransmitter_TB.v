`include "source/MetadataTransmitter.v"
`include "source/UARTTransmitter.v"

// 1 ns unit, 10 ps precision.
`timescale 1ns/10ps

module Metadata_TB();

	parameter CLOCKS_PER_BIT = 5;
	parameter CLOCK_PERIOD_NS = 10;

	reg clock = 0;

	// Run the transmitter
	reg run = 0;

	// Which entry to send.
	reg entry = 0;

	// Serial interface.
	wire serial_output_active;
	wire serial_output_valid;
	wire[7:0] serial_output_data;
	
	// Is the transmission finished.
	wire finished;
	
	MetadataTransmitter target (
		.clock(clock),
		.run(run),
		.entry(entry),
		.serial_output_active(serial_output_active),
		.serial_output_valid(serial_output_valid),
		.serial_output_data(serial_output_data),
		.finished(finished)
	);
	
	wire serial_tx;

	// Serial transmitter.
	UARTTransmitter #(
		.CLOCKS_PER_BIT(10)
	) uart_tx (
		.clock(clock),
		.output_valid(serial_output_valid),
		.output_data(serial_output_data),
		.serial_tx(serial_tx),
		.active(serial_output_active)
	);
	
	always
		#(CLOCK_PERIOD_NS/2) clock <= !clock;
	
	initial begin
		// Tell it to run.
		#(CLOCK_PERIOD_NS * CLOCKS_PER_BIT)
		run <= 0;
		#(CLOCK_PERIOD_NS)
		run <= 1;
		#(CLOCK_PERIOD_NS)
		run <= 0;
		#(CLOCK_PERIOD_NS * CLOCKS_PER_BIT * 8 * 15);

		$finish();
	end
	
	initial begin
		// Required to dump signals to EPWave
		$dumpfile("build/dump.vcd");
		$dumpvars(0);
	end
	
endmodule
