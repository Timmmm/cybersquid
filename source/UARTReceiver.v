module UARTReceiver #(
	parameter CLOCKS_PER_BIT = 1
) (
	input wire clock,
	input wire serial_rx,
	output reg input_valid = 0,
	output reg[7:0] input_data = 0
);
	// 1. Wait for the start bit (low).
	// 2. Wait half a bit.
	// 3. Loop waiting for a full bit and recording.
	// 4. Verify the last bit is 1.

	parameter COUNTER_WIDTH = $clog2(CLOCKS_PER_BIT);

	// Which bit are we at, including the start and stop bit.
	reg[3:0] bit_index = 0;
	// Counter for the bit clocks.
	reg[COUNTER_WIDTH-1:0] clock_count = 0;

	reg active = 0;

	// Previous serial_rx value, to detect negative edges.
	reg serial_rx_prev = 0;

	always @(posedge clock) begin
		input_valid <= 0;

		serial_rx_prev <= serial_rx;

		if (active) begin
			clock_count <= clock_count - 1;

			if (clock_count == 0) begin
				if (bit_index == 9) begin
					// Stop bit. Must be 1 or we ignore this.
					input_valid <= serial_rx;
					// Reset.
					active <= 0;
				end else begin
					// For the stop bit, bit_index index will be -1 (7) but that won't matter.
					input_data[bit_index - 1] <= serial_rx;
					bit_index <= bit_index + 1;
					clock_count <= CLOCKS_PER_BIT - 1;
				end
			end
		end else begin
			// Wait for negative edge.
			if (serial_rx == 1'b0 && serial_rx_prev == 1'b1) begin
				// Start bit detected, wait half a bit.
				bit_index <= 0;
				clock_count <= CLOCKS_PER_BIT/2;
				active <= 1;
			end
		end
	end

endmodule