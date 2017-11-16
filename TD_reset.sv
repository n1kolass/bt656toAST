`timescale 1ns/1ns

`define MS_5 700000

module TD_reset (
	input clock,
	input reset,

	output nTDreset
);

logic [19:0] counter;
logic invert, res;

assign nTDreset = res;

always_ff @(posedge clock or posedge reset) begin
	if(reset) begin
		counter <= 0;
		res <= 1;
		invert <= 0;
	end else begin
		if (~invert)
			if (counter < `MS_5) begin
				counter <= counter + 1;
			end else begin 
				counter <= 0;
				invert <= 1;
				res <= 0;
			end
		else 
			if (counter < `MS_5) begin
				counter <= counter + 1;
			end else begin 
				res <= 1;
			end
	end
end

endmodule