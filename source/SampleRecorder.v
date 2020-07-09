`include "ClockDivider.v"

// Module that records data to RAM.

module SampleRecorder(
	input wire clock,

	// Assert to run.
	input wire run,

	// Configuration settings
	input wire[15:0] flags,
	input wire[23:0] clock_divider,
	input wire[10:0] read_count_x4,
	input wire[10:0] trigger_delay_x4,
	input wire[7:0] trigger_mask,
	input wire[7:0] trigger_value,
	input wire[7:0] trigger_config,
	input wire[7:0] trigger_edge,

	// The input channels. Although SUMP can record 32 channels, we only have 8
	// and so we just record those. The RAM blocks are 512 bytes and there can
	// be up to 16 of them so the max number of samples is 8192, assuming
	// we don't use any for anything else.
	input wire[7:0] channels,

	// Where to save memory to.
	output reg write_en = 0,
	output reg[12:0] write_address,
	output reg[7:0] write_data,

	// Pulsed when we have finished recording, i.e. have been triggered
	// and recorded the data past the trigger.
	output reg finished
);
	reg running = 0;

	// True if the buffer is full (detected when the write address wraps to 0 again).
	reg full = 0;

	// If we have been triggered.
	reg triggered = 0;

	// How many samples we have left to record after being triggered.
	reg[12:0] samples_remaining;

	parameter FLAG_INTERNAL_TEST_MODE = 16'h0800;

	wire[7:0] sample = (flags & FLAG_INTERNAL_TEST_MODE) ? write_address[7:0] : channels;

	wire divided_clock;

	ClockDivider divider(
		.clock(clock),
		.clock_divider(clock_divider),
		.output_clock(divided_clock)
	);

	always @(posedge clock)
	begin
		finished <= 0;
		write_en <= 0;

		if (running) begin
			if (divided_clock == 1'b1) begin
				write_en <= 1;
				write_address <= write_address + 1;
				write_data <= sample;

				if (write_address + 13'b1 == 13'b0) begin
					full <= 1;
				end

				if (triggered) begin
					samples_remaining <= samples_remaining - 1;
					if (samples_remaining == 0) begin
						running <= 0;
						finished <= 1;
					end
				end else begin

					// See if we trigger. We only trigger if we have at least read_count
					// samples - technically not required (we could trigger after read_count - trigger_delay
					// samples) but this is simpler.
					if ((full || write_address > (read_count_x4 << 2)) &&
						(sample & trigger_mask) == (trigger_value & trigger_mask)) begin

						// I'm pretty sure this is the critical timing constraint.
						// Note that trigger_delay_x4 is always set equal to read_count_x4 by
						// sigrok if there are no triggers configured.
						samples_remaining <= (read_count_x4 - trigger_delay_x4) << 2;
						triggered <= 1;
					end
				end
			end

		end else if (run) begin
			full <= 0;
			triggered <= 0;
			running <= 1;
			write_address <= 0;
		end
	end

endmodule