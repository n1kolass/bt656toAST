`timescale 1ns/1ns

module bt656toAST (
	clock,
	reset,
// BT.656 input
	bt_data,
	bt_clock,
// Avalon ST output (source)
	dout_data,
	dout_startofpacket,
	dout_ready,
	dout_endofpacket,
	dout_valid
);

localparam BT_DATA_WIDTH 	= 8;
localparam DOUT_DATA_WIDTH 	= 8;

localparam LINE_WIDTH 		= 720;
localparam BT_LINE_WIDTH 	= LINE_WIDTH * 2;

localparam HALF_HEIGHT 		= 288; 
localparam BLANK_WIDTH 		= 280;

input logic clock;
input logic reset;

input logic [BT_DATA_WIDTH-1:0] bt_data;
input logic bt_clock;

input logic dout_ready;
output logic [DOUT_DATA_WIDTH-1:0] dout_data;
output logic dout_startofpacket;
output logic dout_endofpacket;
output logic dout_valid;

logic wr_req, rd_req;
logic [DOUT_DATA_WIDTH-1:0] pre_dout_data, fifo_dout_data;
logic inner_full, inner_empty;

// bt_input
logic [8:0] skip_counter;
logic [11:0] px_counter; // Counts pixels in bt line
// AST output
logic [11:0] cur_px, cur_line;
logic [3:0] ctrl_px_counter;
logic [3:0] wait_empty_counter;

logic sync; // We are ready to receive data from the beggining of F0 field
logic [7:0] sync_byte; // Each bit of this byte is corresponding to the part of video data in BT.656 format
/*

  blank 			   data
----------------------------------------
    0   |               1              | empty lines (1-22)
----------------------------------------
        |                              |
    2   |               3              | data lines  (23-310)
        |                              |
----------------------------------------
    0   |               1              | empty lines (311-312)
----------------------------------------
    4   |               5              | empty lines (313 - 335)
----------------------------------------
        |                              |
    6   |               7              | data lines  (336-623)
        |                              |
----------------------------------------
    4   |               5              | empty lines (624-625)
----------------------------------------
*/

enum {
	field0,
	field1
} cur_field;

FIFO_5_lines fifo5lines (
	.clock_in 	(bt_clock),
	.clock_out 	(clock),
	.reset 		(reset),

	.data_in 	(bt_data),
	.write 		(wr_req),

	.data_out 	(fifo_dout_data),
	.read 		(rd_req),
	.full 		(inner_full),
	.empty 		(inner_empty)
);

enum {
	s0_FF,
	s1_00,
	s2_00,
	s3_XY_detection,
	s4_blank_10_80,
	s5_recieve_data,
	s6_skip_data
} state_bt_input;

always_ff @(posedge bt_clock or posedge reset) begin : bt_input
	if(reset) begin
		skip_counter <= 0;
		px_counter <= 0;
		wr_req <= 0;
		state_bt_input <= s0_FF;
		sync <= 0;
		sync_byte <= 0;
	end else begin
		case (state_bt_input)
			
			s0_FF : begin 
				if (bt_data == 8'hFF) begin 
					state_bt_input <= s1_00;
				end
			end

			s1_00 : begin 
				if (bt_data == 8'h00) begin 
					state_bt_input <= s2_00;
				end
			end

			s2_00 : begin 
				if (bt_data == 8'h00) begin 
					state_bt_input <= s3_XY_detection;
				end
			end

			s3_XY_detection : begin 
				if (sync == 1) begin
					if (bt_data[4]) begin// H = 1 
						state_bt_input <= s4_blank_10_80;
						skip_counter <= 0;
					end else if (bt_data[5]) begin // H = 0, V = 1
						state_bt_input <= s6_skip_data;
						px_counter <= 0;
					end else // H = 0, V = 0
						// if FIFO is currently full, just skip the line and go to s6_skip_data
						if (inner_full) begin
							px_counter <= 0;
							state_bt_input <= s6_skip_data;
						end else begin
							px_counter <= 0;
							wr_req <= 1;
							state_bt_input <= s5_recieve_data;
						end
				end else begin 
					case (bt_data[6:4]) // F,V,H
						3'b011: begin // (0)
							sync_byte[0] <= 1;
							if (sync_byte[3:2] == 2'b00) 
								sync <= 1;
							state_bt_input <= s4_blank_10_80;
						end
						3'b010: begin // (1)
							sync_byte[1] <= 1;
							if (sync_byte[3:2] == 2'b00) 
								sync <= 1;
							state_bt_input <= s6_skip_data;
						end
						3'b001: begin // (2)
							sync_byte[2] <= 1;
							state_bt_input <= s4_blank_10_80;
						end
						3'b000: begin // (3)
							sync_byte[3] <= 1;
							state_bt_input <= s6_skip_data;
						end
						3'b111: begin // (4)
							sync_byte[4] <= 1;
							if (sync_byte[7:6] == 2'b11)
								sync <= 1;
							state_bt_input <= s4_blank_10_80;
						end
						3'b110: begin // (5)
							sync_byte[5] <= 1;
							if (sync_byte[7:6] == 2'b11)
								sync <= 1;
							state_bt_input <= s6_skip_data;
						end
						3'b101: begin // (6)
							sync_byte[6] <= 1;
							state_bt_input <= s4_blank_10_80;
						end
						3'b100: begin // (7)
							sync_byte[7] <= 1;
							state_bt_input <= s6_skip_data;
						end
					endcase
				end
			end

			s4_blank_10_80 : begin 
				if (skip_counter == BLANK_WIDTH-1)
					state_bt_input <= s0_FF;
				else
					skip_counter <= skip_counter + 1;
			end

			s5_recieve_data : begin 
				if (px_counter == BT_LINE_WIDTH-1) begin
					px_counter <= 0;
					state_bt_input <= s0_FF;
					wr_req <= 0;
				end else
					px_counter <= px_counter + 1;
			end

			s6_skip_data : begin 
				if (px_counter == BT_LINE_WIDTH-1) begin 
					px_counter <= 0;
					state_bt_input <= s0_FF;
				end else
					px_counter <= px_counter + 1;
			end

		endcase
	end
end

assign dout_data = rd_req ? fifo_dout_data : pre_dout_data;

enum {
	s0_ctrl_packet_init,
	s1_ctrl_packet_transmission,
	s2_begin_video_packet,
	s3_video_packet_transmission,
	s4_wait_for_empty
} state_AST_output;

always_ff @(posedge clock or posedge reset) begin : AST_output
	if(reset) begin
		cur_px <= 0;
		cur_line <= 0;
		ctrl_px_counter <= 0;
		state_AST_output <= s0_ctrl_packet_init;
		pre_dout_data <= 0;
		dout_startofpacket <= 0;
		dout_endofpacket <= 0;
		dout_valid <= 0;
		cur_field <= field0;
		wait_empty_counter <= 0;
		rd_req <= 0;
	end else begin

		case (state_AST_output)

			s0_ctrl_packet_init : begin 
				dout_endofpacket <= 0;
				if (dout_ready) begin
					dout_valid <= 1;
					dout_startofpacket <= 1;
					pre_dout_data <= 8'h0F;
					ctrl_px_counter <= 1;
					state_AST_output <= s1_ctrl_packet_transmission;
				end
			end

			s1_ctrl_packet_transmission : begin 
				if (dout_ready) begin 
					dout_valid <= 1;
					case ( ctrl_px_counter )

						1 : begin
							dout_startofpacket <= 0;
							pre_dout_data <= {4'h0, BT_LINE_WIDTH[15:12]};
						end 

						2 : begin
							pre_dout_data <= {4'h0, BT_LINE_WIDTH[11:8]};
						end 

						3 : begin
							pre_dout_data <= {4'h0, BT_LINE_WIDTH[7:4]};
						end 

						4 : begin
							pre_dout_data <= {4'h0, BT_LINE_WIDTH[3:0]};
						end 

						5 : begin
							pre_dout_data <= {4'h0, HALF_HEIGHT[15:12]};
						end 

						6 : begin
							pre_dout_data <= {4'h0, HALF_HEIGHT[11:8]};
						end 

						7 : begin
							pre_dout_data <= {4'h0, HALF_HEIGHT[7:4]};
						end 

						8 : begin
							pre_dout_data <= {4'h0, HALF_HEIGHT[3:0]};
						end 

						9 : begin 
							if (cur_field == field0) begin
								pre_dout_data <= 4'b1011; // Interlaced F0 field, pairing don’t care
								cur_field <= field1;
							end else begin 
								pre_dout_data <= 4'b1111; // Interlaced F1 field, pairing don’t care
								cur_field <= field0;
							end
							dout_endofpacket <= 1'b1;
							state_AST_output <= s2_begin_video_packet;
						end 
						
					endcase
					ctrl_px_counter <= ctrl_px_counter + 1;
				end else
					dout_valid <= 0;
			end

			s2_begin_video_packet : begin 
				dout_endofpacket <= 0;
				if (dout_ready && inner_empty == 0) begin 
					dout_valid <= 1;
					dout_startofpacket <= 1;
					pre_dout_data <= 8'h00;
					cur_px <= 0;
					cur_line <= 0;
					rd_req <= 1;
					state_AST_output <= s3_video_packet_transmission;
				end else
					dout_valid <= 0;
			end

			s3_video_packet_transmission : begin 
				if (dout_ready && inner_empty == 0) begin 
					pre_dout_data <= fifo_dout_data;
					if (cur_px == 0)
						dout_startofpacket <= 0;
					dout_valid <= 1;
					rd_req <= 1;
					if (cur_px == BT_LINE_WIDTH-1) begin 
						if (cur_line == HALF_HEIGHT-1) begin 
							cur_line <= 0;
							dout_endofpacket <= 1;
							state_AST_output <= s0_ctrl_packet_init;
						end else begin
							cur_line <= cur_line + 1;
							cur_px <= 0;
							// Empty signal from buffer comes with delay, so
							// we need to wait a bit for it to come
							rd_req <= 0;
							dout_valid <= 0;
							state_AST_output <= s4_wait_for_empty; 
							wait_empty_counter <= 0;
						end
					end else
						cur_px <= cur_px + 1;
				end else begin 
					dout_valid <= 0;
					rd_req <= 0;
				end
			end

			s4_wait_for_empty : begin 
				if (wait_empty_counter == 4'hF) begin
					state_AST_output <= s3_video_packet_transmission;
					wait_empty_counter <= 0;
				end else
					wait_empty_counter <= wait_empty_counter + 1;
			end
		endcase
	end
end

endmodule