`include "source/Core.v"

// 1 ns unit, 10 ps precision.
`timescale 1ns/10ps

module Core_TB();

	parameter CMD_RESET = 8'h00;
	parameter CMD_RUN = 8'h01;
	parameter CMD_ID = 8'h02;
	parameter CMD_TESTMODE = 8'h03;
	parameter CMD_METADATA = 8'h04;
	parameter CMD_SET_DIVIDER = 8'h80;
	parameter CMD_CAPTURE_SIZE = 8'h81;
	parameter CMD_SET_FLAGS = 8'h82;
	parameter CMD_CAPTURE_DELAYCOUNT = 8'h83; // Extension for Pipistrello
	parameter CMD_CAPTURE_READCOUNT = 8'h84; // Extension for Pipistrello
	parameter CMD_SET_TRIGGER_MASK_0 = 8'hC0;
	parameter CMD_SET_TRIGGER_MASK_1 = 8'hC4;
	parameter CMD_SET_TRIGGER_MASK_2 = 8'hC8;
	parameter CMD_SET_TRIGGER_MASK_3 = 8'hCC;
	parameter CMD_SET_TRIGGER_VALUE_0 = 8'hC1;
	parameter CMD_SET_TRIGGER_VALUE_1 = 8'hC5;
	parameter CMD_SET_TRIGGER_VALUE_2 = 8'hC9;
	parameter CMD_SET_TRIGGER_VALUE_3 = 8'hCD;
	parameter CMD_SET_TRIGGER_CONFIG_0 = 8'hC2;
	parameter CMD_SET_TRIGGER_CONFIG_1 = 8'hC6;
	parameter CMD_SET_TRIGGER_CONFIG_2 = 8'hCA;
	parameter CMD_SET_TRIGGER_CONFIG_3 = 8'hCE;
	parameter CMD_SET_TRIGGER_EDGE_0 = 8'hC3; // Extension for Pipistrello
	parameter CMD_SET_TRIGGER_EDGE_1 = 8'hC7; // Extension for Pipistrello
	parameter CMD_SET_TRIGGER_EDGE_2 = 8'hCB; // Extension for Pipistrello
	parameter CMD_SET_TRIGGER_EDGE_3 = 8'hCF; // Extension for Pipistrello


	// 10 MHz clock, so clock period ist 100 ns.
	// 1 MHz baud so it takes 10 cycles per bit.
	parameter BAUD_RATE = 1000000;
	parameter CLOCK_SPEED = 10000000;
	parameter CLOCK_PERIOD_NS = 100;
	parameter BIT_PERIOD_NS = 1000;

	reg clock = 0;
	reg SERIAL_RX = 1;
	wire SERIAL_TX;
	wire LED1;
	wire LED2;
	wire LED3;
	wire LED4;
	wire LED5;
	wire PMOD_1;
	wire PMOD_2;
	wire PMOD_3;
	wire PMOD_4;
	wire PMOD_7;
	wire PMOD_8;
	wire PMOD_9;
	wire PMOD_10;

	Core #(
		.BAUD_RATE(BAUD_RATE),
		.CLOCK_SPEED(CLOCK_SPEED)
	) target (
		clock,
		SERIAL_RX,
		SERIAL_TX,
		LED1,
		LED2,
		LED3,
		LED4,
		LED5,
		PMOD_1,
		PMOD_2,
		PMOD_3,
		PMOD_4,
		PMOD_7,
		PMOD_8,
		PMOD_9,
		PMOD_10
	);

	always
		#(CLOCK_PERIOD_NS/2) clock <= !clock;

	task send_byte(input [7:0] data);
		integer i;
		begin
			// Start bit
			SERIAL_RX <= 1'b0;
			#(BIT_PERIOD_NS);

			// Data
			for (i = 0; i < 8; i = i+1)
			begin
				SERIAL_RX <= data[i];
				#(BIT_PERIOD_NS);
			end

			// Stop bit
			SERIAL_RX <= 1'b1;
			#(BIT_PERIOD_NS);
		end
	endtask
	
	initial begin

		// To test in Termite:

		// 0x02
		//
		// 0x04
		//
		// 0x817c007c00
		// 0x823a080000
		// 0x01
		//
		// 0xc000000000
		// 0xc010000000
		// 0xc020000008
		// 0x8118001800
		// 0x823a080000
		// 0x01

		// Wait a bit.
		#(BIT_PERIOD_NS);

		send_byte(CMD_ID);

		// Receive data.
		#(BIT_PERIOD_NS * 50);

		send_byte(CMD_METADATA);

		// Receive data.
		#(BIT_PERIOD_NS * 400);

		send_byte(CMD_CAPTURE_SIZE);
		send_byte(8'h7c); // 500 samples ((0x7c + 1) * 4 = 500)
		send_byte(8'h00);
		send_byte(8'h7c);
		send_byte(8'h00);

		#(BIT_PERIOD_NS * 5);

		send_byte(CMD_SET_FLAGS);
		send_byte(8'h3a); // Default with internal test mode.
		send_byte(8'h08);
		send_byte(8'h00); // Ignored.
		send_byte(8'h00);

		#(BIT_PERIOD_NS * 5);

		send_byte(CMD_RUN);

		#(BIT_PERIOD_NS * 10000);

		// Run again without reset.

		send_byte(CMD_SET_TRIGGER_MASK_0);
		send_byte(8'h00);
		send_byte(8'h00);
		send_byte(8'h00);
		send_byte(8'h00);

		send_byte(CMD_SET_TRIGGER_VALUE_0);
		send_byte(8'h00);
		send_byte(8'h00);
		send_byte(8'h00);
		send_byte(8'h00);

		send_byte(CMD_SET_TRIGGER_CONFIG_0);
		send_byte(8'h00);
		send_byte(8'h00);
		send_byte(8'h00);
		send_byte(8'h08); // TODO: What is this?

		send_byte(CMD_CAPTURE_SIZE);
		send_byte(8'h18); // 100 samples
		send_byte(8'h00);
		send_byte(8'h18);
		send_byte(8'h00);

		send_byte(CMD_SET_FLAGS);
		send_byte(8'h3a); // Default with internal test mode.
		send_byte(8'h08);
		send_byte(8'h00); // Ignored.
		send_byte(8'h00);

		send_byte(CMD_RUN);

		#(BIT_PERIOD_NS * 5000);

		$finish();
	end
	
	initial begin
		// Required to dump signals to EPWave
		$dumpfile("build/dump.vcd");
		$dumpvars(0);
	end
	
endmodule
