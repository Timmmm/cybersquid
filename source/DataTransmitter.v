// Allows transmitting the data from RAM when it has been collected.
//
// The inputs are the memory read port, a "run" signal, and the details
// of how much memory is available.
//
// The outputs are signals to say what memory to read and the serial output stuff.
//
module DataTransmitter(
	input wire clock,

	// Assert to run.
	input wire run,

	// Configuration settings
	input wire[15:0] flags,
	input wire[10:0] read_count_x4,

	input wire[12:0] last_sample_address,

	// Reading memory.
	input wire[7:0] read_data,
	output reg[12:0] read_address,

	// Sending data via serial.
	input wire serial_output_active,
	output reg serial_output_valid,
	output reg[7:0] serial_output_data,

	// Asserted when finished.
	output reg finished = 0
);
	// Current state.
	parameter STATE_IDLE = 0;
	parameter STATE_SENDING_DATA = 1;

	reg state = STATE_IDLE;

	// Number of bytes left to send.
	reg[12:0] bytes_remaining = 0;

	// Used for to add a 1 cycle delay for reading from memory.
	reg data_ready = 0;

	// We have to output the data backwards.
	always @(posedge clock) begin
		serial_output_valid <= 0;
		data_ready <= 0;
		finished <= 0;

		case (state)
			STATE_IDLE: begin
				if (run) begin
					state <= STATE_SENDING_DATA;
					read_address <= last_sample_address;
					bytes_remaining <= read_count_x4 << 2;
				end
			end
			STATE_SENDING_DATA: begin
				if (data_ready) begin
					if (serial_output_active == 0 && serial_output_valid == 0) begin
						// Output the data.
						serial_output_valid <= 1;
						serial_output_data <= read_data;

						read_address <= read_address - 13'b1;
						bytes_remaining <= bytes_remaining - 1;

						// Go to next address.
						if (bytes_remaining == 13'b1) begin
							state <= STATE_IDLE;
							finished <= 1;
						end
					end
				end else begin
					// Add one sample delay.
					data_ready <= 1;
				end
			end
		endcase
	end

endmodule