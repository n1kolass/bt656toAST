`timescale 1ns/1ns

module bt656toAST_test (
	clock,
	reset,

	dout_data,
	dout_startofpacket,
	dout_ready,
	dout_endofpacket,
	dout_valid
);

localparam DOUT_DATA_WIDTH 	= 8;
localparam BT_DATA_WIDTH 	= 8;

input logic clock;
input logic reset;

input logic dout_ready;
output logic [DOUT_DATA_WIDTH-1:0] dout_data;
output logic dout_startofpacket;
output logic dout_endofpacket;
output logic dout_valid;

logic [BT_DATA_WIDTH-1:0] to_bt_data;
logic to_bt_clock;

logic [DOUT_DATA_WIDTH-1:0] to_dout_data;
logic to_dout_startofpacket;
logic to_dout_ready;
logic to_dout_endofpacket;
logic to_dout_valid;

assign
	dout_data = to_dout_data,
	dout_startofpacket = to_dout_startofpacket,
	to_dout_ready = dout_ready,
	dout_endofpacket = to_dout_endofpacket,
	dout_valid = to_dout_valid;

bt656toAST bt0 (
	.clock 				(clock),
	.reset 				(reset),
// BT.656 input
	.bt_data 			(to_bt_data),
	.bt_clock 			(to_bt_clock),
// Avalon ST output (source)
	.dout_data 			(to_dout_data),
	.dout_startofpacket (to_dout_startofpacket),
	.dout_ready 		(to_dout_ready),
	.dout_endofpacket 	(to_dout_endofpacket),
	.dout_valid 		(to_dout_valid)
);

bt656gen gen0 (
	.clock_ref 	(clock),
	.reset 		(reset),

	.clock 		(to_bt_clock),
	.data 		(to_bt_data)
);

endmodule

/*
force /bt656toAST_test/clock 0 0, 1 10ns -r 20ns
force /bt656toAST_test/reset 1 0, 0 10ns
force /bt656toAST_test/dout_ready 0
*/