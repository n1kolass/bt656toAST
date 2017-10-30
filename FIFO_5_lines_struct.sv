`timescale 1ns/1ns

module FIFO_5_lines_struct (
	clock_in,
	clock_out,
	reset,

	data_in,
	write,

	data_out,
	read,
	full,
	empty
);

output logic clock_in;
output logic clock_out;
output logic reset;

output logic [7:0] data_in;
output logic write;

output logic read;
output logic [7:0] data_out;
output logic full, empty;

logic clock_in_to;
logic clock_out_to;
logic reset_to;
logic [7:0] data_in_to;
logic write_to;
logic read_to;
logic full_to, empty_to;

assign 
	clock_in = clock_in_to,
	clock_out = clock_out_to,
	reset = reset_to,
	data_in = data_in_to,
	write = write_to,
	read = read_to,
	full = full_to,
	empty = empty_to;

FIFO_5_lines fifo5 (
	.clock_in 	(clock_in_to),
	.clock_out 	(clock_out_to),
	.reset 		(reset_to),

	.data_in 	(data_in_to),
	.write 		(write_to),

	.data_out 	(data_out),
	.read 		(read_to),
	.full 		(full_to),
	.empty 		(empty_to)
);

FIFO_5_lines_stim fifo5stim (
	.clock_in 	(clock_in_to),
	.clock_out 	(clock_out_to),
	.reset 		(reset_to),

	.data_in 	(data_in_to),
	.write 		(write_to),

	.read 		(read_to)
);

endmodule