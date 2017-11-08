`timescale 1ns/1ns

module FIFO_5_lines (
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

localparam LINE_SIZE 	= 640;
localparam BUFF_SIZE 	= LINE_SIZE;

input logic clock_in;
input logic clock_out;
input logic reset;

input logic [7:0] data_in;
input logic write;

input logic read;
output logic [7:0] data_out;
output logic full, empty;

logic inner_full, inner_empty;
logic [7:0] inner_data_out;
logic [7:0] buff0 [0:BUFF_SIZE-1];
logic [7:0] buff1 [0:BUFF_SIZE-1];
logic [7:0] buff2 [0:BUFF_SIZE-1];
logic [7:0] buff3 [0:BUFF_SIZE-1];
logic [7:0] buff4 [0:BUFF_SIZE-1];
logic [2:0] head_gray, head_bin, tail_gray, tail_bin; // head and tail of buffer
logic [11:0] cur_px_wr, cur_px_rd;

logic [2:0] d_head_gray, dd_head_gray; // Two sync ff triggers for head pointer
logic [2:0] d_tail_gray, dd_tail_gray; // and for tail pointer

logic [2:0] temp0_full, temp1_full;
logic [2:0] temp_head_bin, temp_tail_bin;

assign full = inner_full;
assign empty = inner_empty;
assign data_out = inner_data_out;

always_ff @(posedge clock_in or posedge reset) begin : writing
	if(reset) begin
		cur_px_wr <= 0;
	end else begin
		if (write && inner_full == 0) begin 
			case (head_bin)
				0 : begin 
					buff0[cur_px_wr] <= data_in;
				end

				1 : begin 
					buff1[cur_px_wr] <= data_in;
				end
				
				2 : begin 
					buff2[cur_px_wr] <= data_in;
				end
				
				3 : begin 
					buff3[cur_px_wr] <= data_in;
				end
				
				4 : begin 
					buff4[cur_px_wr] <= data_in;
				end
			endcase

			if (cur_px_wr == BUFF_SIZE-1) begin 
				cur_px_wr <= 0;
			end else
				cur_px_wr <= cur_px_wr + 1;
		end
	end
end

always_ff @(posedge clock_out or posedge reset) begin : reading
	if(reset) begin
		cur_px_rd <= 0;
		inner_data_out <= 0;
	end else begin
		if (read != 1'b0 && inner_empty == 0) begin 
			case (tail_bin)
				0 : begin 
					inner_data_out <= buff0[cur_px_rd];
				end

				1 : begin 
					inner_data_out <= buff1[cur_px_rd];
				end
				
				2 : begin 
					inner_data_out <= buff2[cur_px_rd];
				end
				
				3 : begin 
					inner_data_out <= buff3[cur_px_rd];
				end
				
				4 : begin 
					inner_data_out <= buff4[cur_px_rd];
				end
			endcase
			
			if (cur_px_rd == BUFF_SIZE-1) begin 
				cur_px_rd <= 0;
			end else
				cur_px_rd <= cur_px_rd + 1;
		end else
			if (cur_px_rd == BUFF_SIZE-1)
				cur_px_rd <= 0;
	end
end

grayAndBinCounter outCounter (
	.clock 		(clock_out),
	.reset 		(reset),

	.count_en 	(cur_px_rd == BUFF_SIZE-1 && read),
	.gray_out 	(tail_gray),
	.bin_out	(tail_bin)
);

defparam outCounter.COUNTER_WIDTH = 3;
defparam outCounter.MAX_COUNTER_VALUE = 5;

grayAndBinCounter inCounter (
	.clock 		(clock_in),
	.reset 		(reset),

	.count_en 	(cur_px_wr == BUFF_SIZE-1 && write),
	.gray_out 	(head_gray),
	.bin_out	(head_bin)
);

defparam inCounter.COUNTER_WIDTH = 3;
defparam inCounter.MAX_COUNTER_VALUE = 5;

// Cross domain clock synchronization
// Tail from read clock -> write clock
always_ff @(posedge clock_in) begin
	d_tail_gray <= tail_gray;
	dd_tail_gray <= d_tail_gray;
end

// Head from write clock -> read clock
always_ff @(posedge clock_out) begin
	d_head_gray <= head_gray;
	dd_head_gray <= d_head_gray;
end

// Empty signal
always_ff @(posedge clock_out or posedge reset) begin
	if (reset)
		inner_empty <= 1;
	else
		// If tail and head are equal then buffer is empty
		if (dd_head_gray == tail_gray)
			inner_empty <= 1;
		else
			inner_empty <= 0;
end

// Full signal
always_comb begin 
	temp_head_bin = {head_gray[2], ^head_gray[2:1], ^head_gray[2:1] ^ head_gray[0]};
	temp_tail_bin = {dd_tail_gray[2], ^dd_tail_gray[2:1], ^dd_tail_gray[2:1] ^ dd_tail_gray[0]};
	if (temp_tail_bin > temp_head_bin) begin
		temp0_full = temp_tail_bin - temp_head_bin;
		temp1_full = 5 - temp0_full;
	end else begin
		temp0_full = temp_head_bin - temp_tail_bin;
		temp1_full = temp0_full;
	end
end

always_ff @(posedge clock_out or posedge reset) begin
	if (reset)
		inner_full <= 0;
	else
		// If number of elements in buffer (temp_full) equals 5-1 then buffer is full
		// number of elements in buffer = head - tail, but
		// if it's negative, we need to add 5 to it
		// First of all, we need to convert gray code into binary one
		if (temp1_full == 4)
			inner_full <= 1;
		else
			inner_full <= 0;
end

endmodule // FIFO_5_lines
/*
force clock_in 0 0, 1 10ns -r 20ns;
force reset 1 0, 0 10ns;
force data_in 0 0, 8'h11 30ns, 8'h22 50ns;
force write 0 0, 1 30ns -r 40ns;
force read 0 0
*/
