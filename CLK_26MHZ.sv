`timescale 1ns/1ns

module CLK_26MHZ (
	input ref_clock,
	input reset,
	output CLK_26
);

logic [2:0] counter;
logic preCLK_26;

assign CLK_26 = preCLK_26;

always_ff @(posedge ref_clock or posedge reset) begin
	if(reset) begin
		preCLK_26 <= 0;
		counter <= 0;
	end else begin
		if (counter == 4) begin 
			preCLK_26 <= ~preCLK_26;
			counter <= 0;
		end else
			counter <= counter + 1;
	end
end

endmodule