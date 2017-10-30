`timescale 1ns/1ns

module bt656gen (
	clock_ref,
	reset,

	clock,
	data
);

localparam DATA_WIDTH 	= 8;
localparam BLANK_WIDTH 	= 280;
localparam LINE_WIDTH 	= 720 * 2;
localparam HALF_HEIGHT 	= 288;
localparam BT_HEIGHT 	= 625;

input logic clock_ref;
input logic reset;
output logic clock;
output logic [DATA_WIDTH-1:0] data;

logic pre_clock;

logic is_blank;
logic [10:0] cur_line, cur_px;
logic is_cur_px_Y;
logic [4:0] frame_counter; // Every 24 frames change picture
logic frame_type; // 0 - one picture, 1 - another
enum {
	field0,
	field1
} cur_field;

CLK_26MHZ clk26(
	.ref_clock 	(clock_ref),
	.reset 		(reset),
	.CLK_26 	(pre_clock)
);

assign clock = pre_clock;

enum {
	s0_FF,
	s1_00,
	s2_00,
	s3_XY,
	s4_blank,
	s5_empty_line,
	s6_data_line
} state;

always_ff @(posedge pre_clock or posedge reset) begin
	if(reset) begin
		data <= 0;
		is_blank <= 1;
		is_cur_px_Y <= 0;
		cur_px <= 0;
		cur_line <= 22;
		cur_field <= field0;
		frame_counter <= 0;
		frame_type <= 0;
		state <= s4_blank;
	end else begin
		case (state)
		
			s0_FF : begin 
				data <= 8'hFF;
				state <= s1_00;
			end

			s1_00 : begin 
				data <= 8'h00;
				state <= s2_00;
			end

			s2_00 : begin 
				data <= 8'h00;
				state <= s3_XY;
			end

			s3_XY : begin 
				cur_px <= 0;
				is_cur_px_Y <= 0;
				data[DATA_WIDTH-1] <= 1'b1;
				data[3:0] <= 4'h0;
				if (is_blank) begin 
					data[4] <= 1'b1;
					state <= s4_blank;
					if (cur_line < 22) begin
						data[5] <= 1'b1;
					end else if (cur_line < 310) begin
						data[5] <= 1'b0;
					end else if (cur_line < 335) begin
						data[5] <= 1'b1;
					end else if (cur_line < 623) begin
						data[5] <= 1'b0;
					end else begin
						data[5] <= 1'b1;
					end
				end else begin 
					data[4] <= 1'b0;
					if (cur_line < 22) begin
						data[5] <= 1'b1;
						state <= s5_empty_line;
					end else if (cur_line < 310) begin
						data[5] <= 1'b0;
						state <= s6_data_line;
					end else if (cur_line < 335) begin
						data[5] <= 1'b1;
						state <= s5_empty_line;
					end else if (cur_line < 623) begin
						data[5] <= 1'b0;
						state <= s6_data_line;
					end else begin
						data[5] <= 1'b1;
						state <= s5_empty_line;
					end
				end
				data[6] <= (cur_field == field0) ? 1'b0 : 1'b1;
			end

			s4_blank : begin 
				if (is_cur_px_Y)
					data <= 8'h10;
				else
					data <= 8'h80;

				is_cur_px_Y <= ~is_cur_px_Y;

				if (cur_px == BLANK_WIDTH-1) begin 
					cur_px <= 0;
					is_blank <= 0;
					state <= s0_FF;
				end else
					cur_px <= cur_px + 1;
			end

			s5_empty_line : begin 
				data <= 8'h00;
				if (cur_px == LINE_WIDTH-1) begin 
					cur_px <= 0;
					is_blank <= 1;
					state <= s0_FF;
					if (cur_line == BT_HEIGHT-1) begin 
						cur_line <= 0;
						if (frame_counter == 5'b11111) begin 
							frame_type <= ~frame_type;
							frame_counter <= 0;
						end else
							frame_counter <= frame_counter + 1;
					end else begin
						cur_line <= cur_line + 1;
						if (cur_line == 311)
							cur_field <= field1;
						else if (cur_line == 0)
							cur_field <= field0;
					end
				end else
					cur_px <= cur_px + 1;
			end

			s6_data_line : begin 
				if (is_cur_px_Y)
					data <= (frame_type) ? cur_line[7:0] : 8'h00;
				else
					data <= 8'h99;

				is_cur_px_Y <= ~is_cur_px_Y;

				if (cur_px == LINE_WIDTH-1) begin 
					is_blank <= 1;
					cur_px <= 0;
					state <= s0_FF;
					cur_line <= cur_line + 1;
				end else
					cur_px <= cur_px + 1;
			end
		endcase
	end
end

endmodule