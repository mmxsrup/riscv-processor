module cachemem #(
	parameter DATA_WIDTH = 32,
	parameter DATA_SIZE = 4096,
	parameter INIT_FILE  = ""
)(
	input clk,
	input rst_n,
	input logic flash,
	input logic en,
	input  logic [DATA_WIDTH / 8 - 1 : 0] we,
	input logic allocate,
	input  logic [31 : 0] addr,
	input  logic [DATA_WIDTH - 1 : 0] wdata,
	output logic [DATA_WIDTH - 1 : 0] rdata,
	output hit,
	output dirty
);

	logic v [0 : DATA_SIZE - 1]; // valid
	logic d [0 : DATA_SIZE - 1]; // dirty bit
	logic [11 : 0] tag [0 : DATA_SIZE - 1];
	logic [31 : 0] mem [0 : DATA_SIZE - 1];

	initial begin
		if (INIT_FILE == "") begin
			for (int i = 0; i < DATA_SIZE; i++) begin
				v[i] = 0; d[i] = 0; tag[i] = 0; mem[i] = 0;
			end
		end else begin
			for (int i = 0; i < DATA_SIZE; i++) begin
				v[i] = 1; d[i] = 0; tag[i] = 0;
			end
			$readmemh(INIT_FILE, mem);
		end
	end

	logic [17 : 0] addr_tag;
	logic [11 : 0] addr_index;

	assign addr_tag = addr[31 : 14];
	assign addr_index = addr[13 : 2];
	assign hit = (en && tag[addr_index] == addr_tag && v[addr_index]);
	assign dirty = v[addr_index];

	// Read
	assign rdata = mem[addr_index];

	// Write
	always_ff @(posedge clk) begin
		if (~rst_n) begin
			if (INIT_FILE == "") begin
				for (int i = 0; i < DATA_SIZE; i++) begin
					v[i] = 0; d[i] = 0; tag[i] = 0; mem[i] = 0;
				end
			end else begin
				for (int i = 0; i < DATA_SIZE; i++) begin
					v[i] = 1; d[i] = 0; tag[i] = 0;
				end
				$readmemh(INIT_FILE, mem);
			end
		end else begin
			if (flash) begin
				for (int i = 0; i < DATA_SIZE; i++) begin
					v[i] = 0; d[i] = 0; tag[i] = 0; mem[i] = 0;
				end
			end else begin
				if (en && hit) begin
					for (int i = 0; i < $bits(we); i++) begin
						if (we[i]) begin
							mem[addr_index][8 * i +: 8] <= wdata[8 * i +: 8];
						end
					end
					d[addr_index] <= 1;
				end else if (en && allocate) begin
					for (int i = 0; i < $bits(we); i++) begin
						if (we[i]) begin
							mem[addr_index][8 * i +: 8] <= wdata[8 * i +: 8];
						end
					end
					d[addr_index] <= 0;
					v[addr_index] <= 1;
					tag[addr_index] <= addr_tag;
				end
			end
		end
	end

endmodule