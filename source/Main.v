`include "Main_pll.v"
`include "Core.v"

module Main(
	input wire INPUT_CLOCK,

	input wire SERIAL_RX,
	output wire SERIAL_TX,

	output wire PMOD_1,
	output wire PMOD_2,
	input wire PMOD_3,
	input wire PMOD_4,
	input wire PMOD_7,
	input wire PMOD_8,
	input wire PMOD_9,
	input wire PMOD_10,

	output wire LED1,
	output wire LED2,
	output wire LED3,
	output wire LED4,
	output wire LED5
);
	wire clock;
	
	// PLL. The input clock is 12 MHz. This increases it to 24 MHz (in production we'll use 96 MHz but my oscilloscope
	// is not fast enough for that).
	Main_pll Main_pll_inst(
		.REFERENCECLK(INPUT_CLOCK),
		.PLLOUTGLOBAL(clock),
		.RESET(1'b1) // Reset is active low.
	);

	Core #(
		.BAUD_RATE(115200),
		.CLOCK_SPEED(100500000)
	) core(
		.clock(clock),
		.SERIAL_RX(SERIAL_RX),
		.SERIAL_TX(SERIAL_TX),
		.PMOD_1(1'b0),
		.PMOD_2(1'b0),
		.PMOD_3(PMOD_3),
		.PMOD_4(PMOD_4),
		.PMOD_7(PMOD_7),
		.PMOD_8(PMOD_8),
		.PMOD_9(PMOD_9),
		.PMOD_10(PMOD_10),
		.LED1(LED1),
		.LED2(LED2),
		.LED3(LED3),
		.LED4(LED4),
		.LED5(LED5)
	);

	assign PMOD_1 = SERIAL_TX;
	assign PMOD_2 = core.serial_output_valid;

endmodule
