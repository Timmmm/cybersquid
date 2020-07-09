`include "CommandReceiver.v"
`include "MetadataTransmitter.v"
`include "UARTReceiver.v"
`include "UARTTransmitter.v"
`include "SampleRecorder.v"
`include "DataTransmitter.v"
`include "Inferred_RAM.v"

module Core #(
	parameter BAUD_RATE = 115200,
	parameter CLOCK_SPEED = 12000000
) (
	input wire clock,

	input wire SERIAL_RX,
	output wire SERIAL_TX,

	input wire PMOD_1,
	input wire PMOD_2,
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

	// Clocks per bit (26 by default).
	// +(BAUD_RATE/2) is to do round-to-nearest.
	parameter CLOCKS_PER_BIT = (CLOCK_SPEED + (BAUD_RATE/2))/ BAUD_RATE;

	initial begin
		$display("baud rate:", BAUD_RATE);
		$display("clocks speed:", CLOCK_SPEED);
		$display("clocks per bit:", CLOCKS_PER_BIT);
	end

	// UART received data.
	wire[7:0] serial_input_data;
	// Asserted for one cycle when serial_input_data is valid.
	wire serial_input_valid;

	// UART output.
	reg[7:0] serial_output_data;
	// Assert for one cycle to send the data in serial_output_data (it is copied).
	reg serial_output_valid;
	// 1 while the data is being sent (except for the first cycle where serial_output_valid
	// is 1).
	wire serial_output_active;

	// The current command and parameter, and a single cycle signal to say it is valid.
	wire[7:0] command_receiver_command;
	wire[31:0] command_receiver_param;
	// Asserted for one cycle when the above wires contain a valid command.
	wire command_receiver_valid;

	// Assert for one cycle to start the data transmitter.
	reg data_transmitter_run;
	// Asserted for one cycle to send a byte of data.
	wire data_transmitter_serial_output_valid;
	// The byte to send.
	wire[7:0] data_transmitter_serial_output_data;
	// Asserted for one cycle when the data transmission is finished.
	wire data_transmitter_finished;

	// Assert for one cycle to start the metadata transmitter.
	reg metadata_transmitter_run;
	// Entry to send. Set to 0 for ID, 1 for Metadata.
	reg metadata_entry;
	// Asserted for one cycle to send a byte of metadata.
	wire metadata_transmitter_serial_output_valid;
	// The byte to send.
	wire[7:0] metadata_transmitter_serial_output_data;
	// Asserted for one cycle when the metadata sending is finished.
	wire metadata_transmitter_finished;

	// Input channels.
	wire[7:0] channels = {PMOD_10, PMOD_9, PMOD_8, PMOD_7, PMOD_4, PMOD_3, PMOD_2, PMOD_1};

	// Assert for one cycle to begin the sampling process.
	reg recorder_run = 0;
	// Asserted for one cycle when the sampling process is finished.
	wire recorder_finished;

	// Interface for the sample memory.
	wire sample_mem_write_en;
	wire[12:0] sample_mem_write_address;
	wire[7:0] sample_mem_write_data;
	wire[12:0] sample_mem_read_address;
	wire[7:0] sample_mem_read_data;

	// Configuration state.
	reg[15:0] flags = 0;
	reg[23:0] clock_divider = 0;
	reg[10:0] read_count_x4 = 0;
	reg[10:0] trigger_delay_x4 = 0;
	reg[7:0] trigger_mask = 0;
	reg[7:0] trigger_value = 0;
	reg[7:0] trigger_config = 0;
	reg[7:0] trigger_edge = 0;

	// UART receiver.
	UARTReceiver #(CLOCKS_PER_BIT) serial_input (
		.clock(clock),
		.serial_rx(SERIAL_RX),
		.input_valid(serial_input_valid),
		.input_data(serial_input_data)
	);

	// UART transmitter.
	UARTTransmitter	#(CLOCKS_PER_BIT) serial_output (
		.clock(clock),
		.output_valid(serial_output_valid),
		.output_data(serial_output_data),
		.active(serial_output_active),
		.serial_tx(SERIAL_TX)
	);

	// Command input.
	CommandReceiver command_receiver(
		.clock(clock),
		.serial_input_data(serial_input_data),
		.serial_input_valid(serial_input_valid),
		.command(command_receiver_command),
		.param(command_receiver_param),
		.command_valid(command_receiver_valid)
	);

	// For recording samples.
	SampleRecorder recorder(
		.clock(clock),
		.run(recorder_run),
		.flags(flags),
		.clock_divider(clock_divider),
		.read_count_x4(read_count_x4),
		.trigger_delay_x4(trigger_delay_x4),
		.trigger_mask(trigger_mask),
		.trigger_value(trigger_value),
		.trigger_config(trigger_config),
		.trigger_edge(trigger_edge),

		.channels(channels),

		// Wire the write output directly to the sample memory.
		.write_en(sample_mem_write_en),
		.write_address(sample_mem_write_address),
		.write_data(sample_mem_write_data),

		.finished(recorder_finished)
	);

	// For transmitting the data.
	DataTransmitter data_transmitter(
		.clock(clock),
		.run(data_transmitter_run),
		.flags(flags),

		// The address to start from and the number of samples to send.
		// These are read once when `run` is asserted.
		.last_sample_address(sample_mem_write_address),
		.read_count_x4(read_count_x4),

		.read_data(sample_mem_read_data),
		.read_address(sample_mem_read_address),

		.serial_output_active(serial_output_active),
		.serial_output_valid(data_transmitter_serial_output_valid),
		.serial_output_data(data_transmitter_serial_output_data),
		.finished(data_transmitter_finished)
	);

	// Metadata sending.
	MetadataTransmitter metadata_transmitter(
		.clock(clock),
		.run(metadata_transmitter_run),
		.entry(metadata_entry),

		.serial_output_active(serial_output_active),
		.serial_output_valid(metadata_transmitter_serial_output_valid),
		.serial_output_data(metadata_transmitter_serial_output_data),
		.finished(metadata_transmitter_finished)
	);

	// Memory for storing samples.
	Inferred_RAM #(
		.addr_width(13)
	) sample_memory(
		.write_en(sample_mem_write_en),
		.wclk(clock),
		.waddr(sample_mem_write_address),
		.din(sample_mem_write_data),
		.rclk(clock),
		.raddr(sample_mem_read_address),
		.dout(sample_mem_read_data)
	);

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

	// State machine.
	parameter STATE_READY = 2'h0;
	parameter STATE_RUNNING = 2'h1;
	parameter STATE_SENDING_DATA = 2'h2;
	parameter STATE_SENDING_METADATA = 2'h3;

	reg[1:0] state = STATE_READY;

	wire reset = command_receiver_valid && command_receiver_command == CMD_RESET;

	always @(posedge clock) begin

		recorder_run <= 0;
		data_transmitter_run <= 0;
		metadata_transmitter_run <= 0;

		// Reset always works.
		if (reset) begin

			flags <= 0;
			clock_divider <= 0;
			read_count_x4 <= 0;
			trigger_delay_x4 <= 0;
			trigger_mask <= 0;
			trigger_value <= 0;
			trigger_config <= 0;
			trigger_edge <= 0;
			state <= STATE_READY;

		end else begin

			case (state)
				STATE_READY: begin
					if (command_receiver_valid) begin
						case (command_receiver_command)

							CMD_RUN: begin
								state <= STATE_RUNNING;
								recorder_run <= 1;
							end

							CMD_ID: begin
									// Set the read address. Next cycle the address
									// will be recognised by memory, and then the
									// cycle after that the data will be valid.
									// The metadata_data_ready flag is used to
									// add a single cycle delay so the memory is ready.

									state <= STATE_SENDING_METADATA;
									metadata_transmitter_run <= 1;
									metadata_entry <= 0;
								end

							CMD_TESTMODE: begin
								// TODO
							end

							CMD_METADATA: begin
									state <= STATE_SENDING_METADATA;
									metadata_transmitter_run <= 1;
									metadata_entry <= 1;
								end

							CMD_SET_DIVIDER: begin
								clock_divider <= command_receiver_param[23:0]; // TODO: Check endianness.
							end
							
							CMD_CAPTURE_SIZE: begin
								// The upper bits are ignored because we cannot use them and it improves
								// timing to not calculate them.
								
								// This is measured in lots of 4 samples, so we only need to take 11 bits
								// here.
								read_count_x4 <= command_receiver_param[10:0];
								trigger_delay_x4 <= command_receiver_param[26:16];
							end
							
							CMD_SET_FLAGS: begin
								flags <= command_receiver_param[15:0];
							end
							
							CMD_CAPTURE_DELAYCOUNT: begin
								trigger_delay_x4 <= command_receiver_param[10:0];
							end
							
							CMD_CAPTURE_READCOUNT: begin
								read_count_x4 <= command_receiver_param[10:0];
							end

							// TODO: Support 4-stage trigger.
							
							CMD_SET_TRIGGER_MASK_0: trigger_mask <= command_receiver_param[7:0];
							// CMD_SET_TRIGGER_MASK_1: trigger_mask[1] <= command_receiver_param[7:0];
							// CMD_SET_TRIGGER_MASK_2: trigger_mask[2] <= command_receiver_param[7:0];
							// CMD_SET_TRIGGER_MASK_3: trigger_mask[3] <= command_receiver_param[7:0];
							
							CMD_SET_TRIGGER_VALUE_0: trigger_value <= command_receiver_param[7:0];
							// CMD_SET_TRIGGER_VALUE_1: trigger_value[1] <= command_receiver_param[7:0];
							// CMD_SET_TRIGGER_VALUE_2: trigger_value[2] <= command_receiver_param[7:0];
							// CMD_SET_TRIGGER_VALUE_3: trigger_value[3] <= command_receiver_param[7:0];

							CMD_SET_TRIGGER_CONFIG_0: trigger_config <= command_receiver_param[7:0];
							// CMD_SET_TRIGGER_CONFIG_1: trigger_config[1] <= command_receiver_param[7:0];
							// CMD_SET_TRIGGER_CONFIG_2: trigger_config[2] <= command_receiver_param[7:0];
							// CMD_SET_TRIGGER_CONFIG_3: trigger_config[3] <= command_receiver_param[7:0];

							CMD_SET_TRIGGER_EDGE_0: trigger_edge <= command_receiver_param[7:0];
							// CMD_SET_TRIGGER_EDGE_1: trigger_edge[1] <= command_receiver_param[7:0];
							// CMD_SET_TRIGGER_EDGE_2: trigger_edge[2] <= command_receiver_param[7:0];
							// CMD_SET_TRIGGER_EDGE_3: trigger_edge[3] <= command_receiver_param[7:0];

						endcase
					end
				end

				STATE_RUNNING: begin
					if (recorder_finished) begin
						data_transmitter_run <= 1;
						state <= STATE_SENDING_DATA;
					end
				end

				STATE_SENDING_DATA: begin
					if (data_transmitter_finished) begin
						state <= STATE_READY;
					end
				end

				STATE_SENDING_METADATA: begin
					if (metadata_transmitter_finished) begin
						state <= STATE_READY;
					end
				end
			endcase
		end
	end

	always @* begin
		case (state)
			STATE_SENDING_DATA: begin
				serial_output_valid <= data_transmitter_serial_output_valid;
				serial_output_data <= data_transmitter_serial_output_data;
			end

			STATE_SENDING_METADATA: begin
				serial_output_valid <= metadata_transmitter_serial_output_valid;
				serial_output_data <= metadata_transmitter_serial_output_data;
			end

			default: begin
				serial_output_valid <= 1'b0;
				serial_output_data <= 8'b0;
			end
		endcase
	end

	assign LED1 = state[0];
	assign LED2 = state[1];
	assign LED3 = command_receiver_valid;
	assign LED4 = serial_output_active;
	assign LED5 = 0;

endmodule
