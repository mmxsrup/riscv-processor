`timescale 1ns / 1ps

import ram_pkg::*;


module icache #(
	parameter CACHE_SIZE = 4096
) (
	input logic clk,
	input logic rst_n,
	
	// from fetch
	input [31 : 0] addr,
	input req,
	// to fetch
	output [31 : 0] data,
	output valid,

	// from ram and to ram
	// write
	output reg [AWIDTH - 1 : 0] ram_awaddr,
	output reg [LWIDTH - 1 : 0] ram_awlen,
	output reg ram_awvalid,
	input ram_awready,
	output reg [DWIDTH - 1 : 0] ram_wdata,
	input ram_wvalid,
	output reg ram_wready,
	input ram_wlast,
	// read
	output reg [AWIDTH - 1 : 0] ram_araddr,
	output reg [LWIDTH - 1 : 0] ram_arlen,
	output reg ram_arvalid,
	input ram_arready,
	input [DWIDTH - 1 : 0] ram_rdata,
	input ram_rvalid,
	output reg ram_rready,
	input ram_rlast
);
	

	typedef enum logic [1 : 0] {IDLE, ALLOCATE, RWAIT} state_type;
	state_type state;

	reg v [0 : CACHE_SIZE - 1];
	reg [11 : 0] tag [0 : CACHE_SIZE - 1];
	reg [31 : 0] cache_data [0 : CACHE_SIZE - 1];

	wire [17 : 0] addr_tag;
	wire [11 : 0] addr_index;
	wire hit;

	initial begin
		for (int i = 0; i < CACHE_SIZE; i++) begin
			v[i] = 1;
			tag[i] = 0;
		end
		$readmemh("data.mem", cache_data);
	end

	assign addr_tag = addr[31 : 14];
	assign addr_index = addr[13 : 2];
	assign hit = (tag[addr_index] == addr_tag && v[addr_index]);

	assign valid = hit;
	assign data = (hit) ? cache_data[addr_index] : 32'b0;


	always_ff @(posedge clk) begin
		if (~rst_n) begin
			state <= IDLE;
			ram_awaddr <= 32'h0;
			ram_awlen  <= 0;
			ram_awvalid <= 1'b0;
			ram_wdata <= 32'h0;
			ram_wready <= 1'b0;
			ram_araddr <= 32'b0;
			ram_arlen  <= 0;
			ram_arvalid <= 1'b0;
			ram_rready <= 1'b0;
		end else begin

			case (state)
				IDLE : begin
					ram_rready <= 0;
					if (!hit) begin // cache miss
						if (req) begin
							state <= ALLOCATE;
						end
					end
				end
				ALLOCATE : begin
					ram_wready <= 0;
					ram_araddr <= addr;
					ram_arlen  <= 1;
					ram_arvalid <= 1;
					ram_rready <= 1;
					if (ram_arready) state <= RWAIT;
				end
				RWAIT : begin
					ram_arvalid <= 0;
					if (ram_rvalid) begin
						cache_data[addr_index] <= ram_rdata;
						tag[addr_index] <= addr_tag;
						v[addr_index] <= 1;
						if (ram_rlast) state <= IDLE;
					end
				end
				default : state <= IDLE;
			endcase // case (state)

		end
	end // always @(posedge clk)


endmodule // icache
