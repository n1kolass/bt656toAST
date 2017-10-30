`timescale 1ns/1ns

module FIFO_5_lines_stim (
	clock_in,
	clock_out,
	reset,

	data_in,
	write,

	read
);

localparam LINE_SIZE 	= 20;

output logic clock_in;
output logic clock_out;
output logic reset;

output logic [7:0] data_in;
output logic write;

output logic read;

logic [7:0] to_output;
logic read_allow;

initial begin 
	clock_in = 1'b0;
	forever #10 clock_in = ~clock_in;
end

initial begin 
	clock_out = 1'b0;
	forever #8 clock_out = ~clock_out;
end

initial begin 
	reset = 1'b1;
	read_allow = 1'b0;
	#10 reset = 1'b0;
	#990 read_allow = 1'b1;
	#400 read_allow = 1'b0;
	#1000 read_allow = 1'b1;
	#400 read_allow = 1'b0;
	#100 read_allow = 1'b1;
end

assign data_in = to_output;
assign write = clock_in;
assign read = (read_allow) ? clock_out : 0;

always_ff @(posedge clock_in or posedge reset) begin
	if(reset) begin
		to_output <= 0;
	end else if (clock_in) begin
		if (to_output < 8'hFF)
			to_output <= to_output + 1;
		else
			to_output <= 0;
	end
end


endmodule