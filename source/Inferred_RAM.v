// Inferred 512x8 Block RAM for the ICE40.
//
// Note that the first bytes cannot be initialised to anything other than 0.
//
// The default address size/width is for a single Embedded Block RAM (EBR),
// but you can increase the address with up to 13 and it will infer up
// to 16 EBRs (the limit for the iCE40 stick).

module Inferred_RAM #(
	parameter addr_width = 9,
	parameter data_width = 8,
	parameter init_file = ""
) (
	input wire write_en,
	input wire wclk,
	input wire[addr_width-1:0] waddr,
	input wire[data_width-1:0] din,
	input wire rclk,
	input wire[addr_width-1:0] raddr,
	output reg[data_width-1:0] dout
);

	reg[data_width-1:0] mem[0:(1<<addr_width)-1];

	// Write
	always @(posedge wclk) begin
		if (write_en)
			mem[waddr] <= din;
	end

	// Read
	always @(posedge rclk) begin
		dout <= mem[raddr];
	end

	// Initial contents
	initial begin
		if (init_file != "")
			$readmemh(init_file, mem);
	end
endmodule