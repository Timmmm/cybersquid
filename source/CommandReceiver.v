// Command handling. Commands are 1 byte, with optional 4 byte data (0 if unused).
//
// This *immediately* outputs the command, param, and command_valid for one cycle
// as soon as the last byte is received on serial_input_data with serial_input_valid set.
//
module CommandReceiver(
	// Global clock.
	input wire clock,

	// Input serial data and valid signal.
	input wire[7:0] serial_input_data,
	input wire serial_input_valid,

	// The command.
	output reg[7:0] command,
	// Optional parameter; ignored for some commands.
	output reg[31:0] param,
	// Asserted when the command is valid for one cycle.
	output reg command_valid
);
	// Buffer for data.
	reg[7:0] command_buffer;
	// We only need 3 bytes because the last one instantly comes from serial_input_data.
	reg[23:0] param_buffer;
	reg[2:0] index = 0;

	always @(posedge clock) begin
		// Zero outputs unless overridden below.
		command_valid <= 0;
		command <= 0;
		param <= 0;

		if (serial_input_valid == 1) begin
			case (index)
				0: begin
					if (serial_input_data[7] == 0) begin
						// It's a single-byte command. Immediately output it.
						command_valid <= 1;
						command <= serial_input_data;
						index <= 0;						
					end else begin
						command_buffer <= serial_input_data;
						index <= 1;
					end
				end
				1: begin
					param_buffer[7:0] <= serial_input_data;
					index <= 2;
				end
				2: begin
					param_buffer[15:8] <= serial_input_data;
					index <= 3;
				end
				3: begin
					param_buffer[23:16] <= serial_input_data;
					index <= 4;
				end
				4: begin
					command_valid <= 1;
					command <= command_buffer;
					param <= {serial_input_data, param_buffer};
					index <= 0;
				end
			endcase
		end
	end
endmodule