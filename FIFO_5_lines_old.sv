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

localparam LINE_SIZE 	= 20;

input logic clock_in;
input logic clock_out;
input logic reset;

input logic [7:0] data_in;
input logic write;

input logic read;
output logic [7:0] data_out;
output logic [4:0] full, empty;

logic [4:0] inner_full, inner_empty;
logic [7:0] inner_data_out;
logic [7:0] buff0 [0:LINE_SIZE-1];
logic [7:0] buff1 [0:LINE_SIZE-1];
logic [7:0] buff2 [0:LINE_SIZE-1];
logic [7:0] buff3 [0:LINE_SIZE-1];
logic [7:0] buff4 [0:LINE_SIZE-1];
logic [2:0] cur_line_wr, cur_line_rd;
logic [11:0] cur_px_wr, cur_px_rd;

assign full = inner_full;
assign empty = inner_empty;
assign data_out = inner_data_out;

always_ff @(posedge clock_in or posedge reset) begin
	if(reset) begin
		cur_line_wr <= 0;
		cur_px_wr <= 0;
		inner_full <= 0;
	end else begin
		if (write && inner_empty[cur_line_wr] == 1) begin 
			case (cur_line_wr)
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

			if (cur_px_wr == LINE_SIZE-1) begin 
				cur_px_wr <= 0;
				inner_full[cur_line_wr] <= 1;
				if (cur_line_wr == 4)
					cur_line_wr <= 0;
				else
					cur_line_wr <= cur_line_wr + 1;
			end else
				cur_px_wr <= cur_px_wr + 1;

			if (inner_empty) begin 
				if (inner_empty[0])
					inner_full <= 0;
				if (inner_empty[1])
					inner_full <= 0;
				if (inner_empty[2])
					inner_full <= 0;
				if (inner_empty[3])
					inner_full <= 0;
				if (inner_empty[4])
					inner_full <= 0;
			end 
		end
	end
end

always_ff @(posedge clock_out or posedge reset) begin
	if(reset) begin
		cur_line_rd <= 0;
		cur_px_rd <= 0;
		inner_data_out <= 0;
		inner_empty <= 5'b11111;
	end else begin
		if (read != 1'b0 && full != 5'b00000) begin 
			case (cur_line_rd)
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
			
			if (cur_px_rd == LINE_SIZE-1) begin 
				cur_px_rd <= 0;
				inner_empty[cur_line_rd] <= 1;
				if (cur_line_rd == 4)
					cur_line_rd <= 0;
				else
					cur_line_rd <= cur_line_rd + 1;
			end else
				cur_px_rd <= cur_px_rd + 1;

			if (inner_full) begin 
				if (inner_full[0])
					inner_empty <= 0;
				if (inner_full[1])
					inner_empty <= 0;
				if (inner_full[2])
					inner_empty <= 0;
				if (inner_full[3])
					inner_empty <= 0;
				if (inner_full[4])
					inner_empty <= 0;
			end
		end
	end
end

endmodule

/*
force clock_in 0 0, 1 10ns -r 20ns;
force reset 1 0, 0 10ns;
force data_in 0 0, 8'h11 30ns, 8'h22 50ns;
force write 0 0, 1 30ns -r 40ns;
force read 0 0
*/
