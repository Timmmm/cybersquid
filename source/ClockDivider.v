// Divide a clock by `clock_divider + 1`. This isn't strictly a clock divider in the sense
// that if `clock_divider` is 4 it stretches clock three times. Instead it means
// that `output_clock` will be high exactly 1 out of every 3 times clock is high.
//
// In particular this means that if `clock_divider` is 0, then `output_clock` will
// always be 1.
//
module ClockDivider(
	input wire clock,
	input wire[23:0] clock_divider,
	output reg output_clock = 0
);
	// Note that the first clock will be a bit off but
	// iCE40 doesn't support initial values other than
	// 0 and it doesn't matter really.
	reg[23:0] counter = 0;

	always @(posedge clock) begin
		if (counter == 0) begin
			counter <= clock_divider;
			output_clock <= 1;
		end else begin
			counter <= counter - 1;
			output_clock <= 0;
		end
	end
endmodule