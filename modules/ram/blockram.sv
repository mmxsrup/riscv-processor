module blockram #(
	parameter DATA_WIDTH = 32,
	parameter DATA_SIZE  = 4096,
	parameter INIT_FILE  = ""
)(
	input  logic clk,
	input  logic rst_n,
	input  logic en,
	input  logic [DATA_WIDTH / 8 - 1 : 0] we,
	input  logic [$clog2(DATA_SIZE) - 1 : 0] addr,
	input  logic [DATA_WIDTH - 1 : 0] wdata,
	output logic [DATA_WIDTH - 1 : 0] rdata
);

	logic [DATA_WIDTH - 1 : 0] mem[DATA_SIZE];

	initial begin
		if (INIT_FILE == "") for (int i = 0; i < DATA_SIZE; i++) mem[i] = 0;
		else $readmemh(INIT_FILE, mem);
	end

	// Read
	/*
	always_ff @(posedge clk) begin
		if(~rst_n) begin
			rdata <= 0;
		end else begin
			if (~|we) rdata <= mem[addr];
		end
	end
	*/
	assign rdata = mem[addr];

	// Write
	always_ff @(posedge clk) begin
		if (en) begin
			for (int i = 0; i < $bits(we); i++) begin
				if (we[i]) mem[addr][8 * i +: 8] <= wdata[8 * i +: 8];
			end
		end
	end

endmodule
