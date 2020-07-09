`include "source/UARTTransmitter.v"

// 1 ns unit, 10 ps precision.
`timescale 1ns/10ps

module UARTTransmitter_TB();

	// 10 MHz clock, so clock period ist 100 ns.
	// 1 MHz baud so it takes 10 cycles per bit.
	parameter CLOCKS_PER_BIT = 5;
	parameter CLOCK_PERIOD_NS = 10;

	reg clock = 0;

	reg output_valid = 0;
	reg[7:0] output_data = 0;
	wire serial_tx;
	wire active;

	UARTTransmitter #(
		.CLOCKS_PER_BIT(CLOCKS_PER_BIT)
	) target (
		clock,
		output_valid,
		output_data,
		serial_tx,
		active
	);

	always
		#(CLOCK_PERIOD_NS/2) clock <= !clock;

	task transmit_byte(input [7:0] data);
		begin
			#(CLOCK_PERIOD_NS);
			output_valid <= 1;
			output_data <= data;
			#(CLOCK_PERIOD_NS);
			output_valid <= 0;
			output_data <= 0;
		end
	endtask

	initial begin
		#(CLOCK_PERIOD_NS * CLOCKS_PER_BIT);
		transmit_byte(8'b01010011);
		#(CLOCK_PERIOD_NS * CLOCKS_PER_BIT * 15);
		$finish();
	end

	initial begin
		$dumpfile("build/dump.vcd");
		$dumpvars(0);
	end

endmodule
