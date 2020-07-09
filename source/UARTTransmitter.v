// Allows sending data on the UART.
// Set CLOCKS_PER_BIT to the number of clocks cycles per UART bit. I.e. CLOCK_SPEED/BAUD_RATE
// Round to nearest.
//
// While `active` is 1, the module is transmitting and ignores its inputs.
// A single cycle pulse on `output_valid` will cause it to buffer `output_data` and transmit it.
//
module UARTTransmitter #(
	parameter CLOCKS_PER_BIT = 1
) (
	input wire clock,
	input wire output_valid,
	input wire[7:0] output_data,
	// Note, this should be 1 but it is actually ignored but it gets set on the first
	// cycle anyway.
	output reg serial_tx = 0,
	output reg active = 0
);

	parameter COUNTER_WIDTH = $clog2(CLOCKS_PER_BIT);

	// There are 10 bit: {0, data[0..7], 1}.

	// Which bit are we at, including the start and stop bits.
	reg[3:0] bit_index = 0;
	// Counter for the bit clocks.
	reg[COUNTER_WIDTH-1:0] clock_count = 0;
	// Store data to send.
	reg[7:0] data;

	// Note bit 9 is the 1 and bit 0 is the 0. It's written big endian.
	wire[9:0] all_data = {1'b1, data, 1'b0};
	
	always @(posedge clock) begin
		if (active) begin
			serial_tx <= all_data[bit_index];

			if (clock_count == CLOCKS_PER_BIT - 1) begin
				clock_count <= 0;
				if (bit_index == 9)
					active <= 0;
				else
					bit_index <= bit_index + 1;
			end else
				clock_count <= clock_count + 1;

		end else begin
			serial_tx <= 1'b1;

			if (output_valid) begin
				active <= 1'b1;
				data <= output_data;
				bit_index <= 0;
			end
		end
	end
	
endmodule
