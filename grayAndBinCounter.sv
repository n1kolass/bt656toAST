`timescale 1ns/1ns

module grayAndBinCounter (
	clock,
	reset,

	count_en,
	gray_out,
	bin_out
);

parameter COUNTER_WIDTH = 3;
parameter MAX_COUNTER_VALUE = 5; // Must be withing counter borders from 0 to 2**COUNER_WIDTH-1

input logic clock;
input logic reset;

input logic count_en;
output logic [COUNTER_WIDTH-1:0] gray_out;
output logic [COUNTER_WIDTH-1:0] bin_out;

logic [COUNTER_WIDTH-1:0] counter;

always_ff @(posedge clock or posedge reset) begin
	if(reset) begin
		gray_out <= 0;
		bin_out <= 0;
		counter <= 1;
	end else begin
		if (count_en) begin 
			bin_out <= counter;
			counter <= (counter == MAX_COUNTER_VALUE-1) ? 0 : counter + 1;
			gray_out <= {counter[COUNTER_WIDTH-1],
							counter[COUNTER_WIDTH-2:0] ^ counter[COUNTER_WIDTH-1:1]};
		end
	end
end

endmodule