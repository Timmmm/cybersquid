`include "source/CommandReceiver.v"

// 1 ns unit, 10 ps precision.
`timescale 1ns/10ps

module CommandReceiver_TB();

	reg clock = 0;
	reg[7:0] serial_input_data = 0;
	reg serial_input_valid = 0;
	
	wire[7:0] output_command;
	wire[31:0] output_param;
	wire output_command_valid;
	
	task serial_write_byte(input [7:0] command);
		begin;
			clock <= 0;
			#10
			serial_input_valid <= 0;
			serial_input_data <= command;
			#10
			clock <= 1;
			#10
			clock <= 0;
			#10
			serial_input_valid <= 1;
			#10
			clock <= 1;
			#10;
		end
	endtask
	
	CommandReceiver target(
		.clock(clock),
		.serial_input_data(serial_input_data),
		.serial_input_valid(serial_input_valid),
		.command(output_command),
		.param(output_param),
		.command_valid(output_command_valid)
	);
	
	initial begin
		serial_write_byte(8'h03);
					
		if (output_command_valid == 1'b1 && output_command == 8'h03)
			$display("Pass");
		else
			$display("Fail");

		serial_write_byte(8'h84);
					
		if (output_command_valid == 1'b0)
			$display("Pass");
		else
			$display("Fail");

		serial_write_byte(8'h01);
					
		if (output_command_valid == 1'b0)
			$display("Pass");
		else
			$display("Fail");

		serial_write_byte(8'h02);
					
		if (output_command_valid == 1'b0)
			$display("Pass");
		else
			$display("Fail");

		serial_write_byte(8'h03);
					
		if (output_command_valid == 1'b0)
			$display("Pass");
		else
			$display("Fail");

		serial_write_byte(8'h04);
					
		if (output_command_valid == 1'b1 && output_command == 8'h84 && output_param == 32'h04030201)
			$display("Pass");
		else
			$display("Fail");

		$finish();
	end
	
	initial begin
		// Required to dump signals to EPWave
		$dumpfile("build/dump.vcd");
		$dumpvars(0);
	end
	
endmodule
