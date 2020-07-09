`include "source/DataTransmitter.v"
`include "source/Inferred_RAM.v"
`include "source/UARTTransmitter.v"

// 1 ns unit, 10 ps precision.
`timescale 1ns/10ps

module DataTransmitter_TB();
	parameter CLOCKS_PER_BIT = 5;
	parameter CLOCK_PERIOD_NS = 10;

	reg clock = 0;

	// Run the data transmitter
	reg run = 0;

	reg[15:0] flags = 0;

	// The final write address.
	reg[12:0] last_sample_address = 100;

	// If the buffer is full (i.e. looped round).
	reg full = 0;

	// Memory interface.
	wire[7:0] read_data;
	wire[12:0] read_address;
	wire read_en;

	// Serial interface.
	wire serial_output_active;
	wire serial_output_valid;
	wire[7:0] serial_output_data;
	
	// Is the transmission finished.
	wire finished;

	// The transmitter.
	DataTransmitter target(
		clock,
		run,
		flags,
		last_sample_address,
		read_data,
		read_address,
		serial_output_active,
		serial_output_valid,
		serial_output_data,
		finished
	);

	wire mem_rclk;
	wire[12:0] mem_raddr;
	wire[7:0] mem_dout;

	// Memory to store the data it should send.
	Inferred_RAM #(
		.addr_width(13),
		.init_file("tests/DataTransmitter_Data.hex")
	) mem (
		.write_en(1'b0),
		.wclk(1'b0),
		.waddr(13'b0),
		.din(8'b0),
		.rclk(clock),
		.raddr(mem_raddr),
		.dout(mem_dout)
	);

	// Wire the memory up.
	assign read_data = mem_dout;
	assign mem_raddr = read_address;

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
		#(CLOCK_PERIOD_NS * CLOCKS_PER_BIT * 2500);
		// TODO: Wait for finish flag.

		$finish();
	end
	
	initial begin
		$dumpfile("build/dump.vcd");
		$dumpvars(0);
	end
	
endmodule
