module MetadataTransmitter(
	input wire clock,

	// Assert to run.
	input wire run,

	// Which metadata entry to send. 0 = id, 1 = metadata.
	input wire entry,

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

	parameter ENTRY_ID = 0;
	parameter ENTRY_METADATA = 1;

	reg state = STATE_IDLE;

	reg[5:0] remaining = 0;

	// Metadata (See Protocol.md)
	//
	// Start with 32-bit integers: (1 << 5) | N:
	//
	// Channels: 0x20 0x00000008
	// Sample memory in bytes (512*16): 0x21 0x00002000
	// Max sample rate in Hertz: 100 MHz (actually 100.5 MHz): 0x23 0x05F5E100
	// Device name: 0x01 4379626572737175696400
	// Firmware version: 0x02 302e3100
	// Ancillary version: 0x03 302e3100
	//
	// Altogether now:
	//
	// 200000000821000020002305F5E10001437962657273717569640002302e310003302e3100

	always @(posedge clock) begin
		serial_output_valid <= 0;
		serial_output_data <= 0;
		finished <= 0;

		case (state)
			STATE_IDLE: begin
				if (run) begin
					state <= STATE_SENDING_DATA;
					case (entry)
						ENTRY_ID: remaining <= 3;
						ENTRY_METADATA: remaining <= 100;
					endcase
				end
			end
			STATE_SENDING_DATA: begin
				if (serial_output_active == 0 && serial_output_valid == 0) begin
					// Output the data.
					serial_output_valid <= 1;
					case (entry)
						ENTRY_ID: case (remaining)
							3: serial_output_data <= 8'h31;
							2: serial_output_data <= 8'h53;
							1: serial_output_data <= 8'h4c;
							0: serial_output_data <= 8'h4f;
						endcase
						ENTRY_METADATA: case (remaining)
							36: serial_output_data <= 8'h20;
							35: serial_output_data <= 8'h00;
							34: serial_output_data <= 8'h00;
							33: serial_output_data <= 8'h00;
							32: serial_output_data <= 8'h08;
							31: serial_output_data <= 8'h21;
							30: serial_output_data <= 8'h00;
							29: serial_output_data <= 8'h00;
							28: serial_output_data <= 8'h20;
							27: serial_output_data <= 8'h00;
							26: serial_output_data <= 8'h23;
							25: serial_output_data <= 8'h05;
							24: serial_output_data <= 8'hF5;
							23: serial_output_data <= 8'hE1;
							22: serial_output_data <= 8'h00;
							21: serial_output_data <= 8'h01;
							20: serial_output_data <= 8'h43;
							19: serial_output_data <= 8'h79;
							18: serial_output_data <= 8'h62;
							17: serial_output_data <= 8'h65;
							16: serial_output_data <= 8'h72;
							15: serial_output_data <= 8'h73;
							14: serial_output_data <= 8'h71;
							13: serial_output_data <= 8'h75;
							12: serial_output_data <= 8'h69;
							11: serial_output_data <= 8'h64;
							10: serial_output_data <= 8'h00;
							9: serial_output_data <= 8'h02;
							8: serial_output_data <= 8'h30;
							7: serial_output_data <= 8'h2e;
							6: serial_output_data <= 8'h31;
							5: serial_output_data <= 8'h00;
							4: serial_output_data <= 8'h03;
							3: serial_output_data <= 8'h30;
							2: serial_output_data <= 8'h2e;
							1: serial_output_data <= 8'h31;
							0: serial_output_data <= 8'h00;
						endcase
					endcase

					if (remaining == 0) begin
						finished <= 1;
						state <= STATE_IDLE;
					end else
						remaining <= remaining - 1;
				end
			end
		endcase
	end

endmodule