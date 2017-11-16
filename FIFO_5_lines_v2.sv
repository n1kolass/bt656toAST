module FIFO_5_lines_v2 (
	reset,
	data,
	rdclk,
	rdreq,
	wrclk,
	wrreq,
	q,
	rdempty,
	wrfull
);

input logic reset;
input logic [7:0] data;
input logic rdclk;
input logic rdreq;
input logic wrclk;
input logic wrreq;
output logic [7:0] q;
output logic rdempty;
output logic wrfull;

logic [7:0] data_sig;
logic rdreq_sig;
logic wrreq_sig;
logic [7:0] q_sig;
logic rdempty_sig;
logic wrfull_sig;

fifo	fifo_inst (
	.data ( data_sig ),
	.rdclk ( rdclk),
	.rdreq ( rdreq_sig ),
	.wrclk ( wrclk ),
	.wrreq ( wrreq_sig ),
	.q ( q_sig ),
	.rdempty ( rdempty_sig ),
	.wrfull ( wrfull_sig )
);

logic [9:0] px_counter_rd, px_counter_wr;

always_ff @(posedge rdclk or posedge reset) begin
	if(reset) begin
		px_counter_rd <= 0;
	end else begin
		 <= ;
	end
end

always_ff @(posedge wrclk or posedge reset) begin
	if(reset) begin
		px_counter_wr <= 0;
	end else begin
		 <= ;
	end
end

endmodule