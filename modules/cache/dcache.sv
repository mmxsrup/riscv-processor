`timescale 1ns / 1ps

import ram_pkg::*;


module dcache #( // data cache
	parameter CACHE_SIZE = 4096
)(
	input clk,
	input rst_n,
	
	// from memory
	input [31 : 0] addr,
	input wreq, // write request
	input rreq, // read request
	input [31 : 0] wdata, // write data
	input [3 : 0] byte_enable,

	// to controller
	output wvalid,
	output reg [31 : 0] rdata,
	output rvalid,

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
	

	typedef enum logic [2 : 0] {IDLE, WRITE_BACK, WWAIT, ALLOCATE, RWAIT} state_type;
	state_type state;


	reg v [0 : CACHE_SIZE - 1]; // valid
	reg d [0 : CACHE_SIZE - 1]; // dirty bit
	reg [11 : 0] tag [0 : CACHE_SIZE - 1];
	reg [31 : 0] cache_data [0 : CACHE_SIZE - 1];


	wire [17 : 0] addr_tag;
	wire [11 : 0] addr_index;
	wire hit;

	initial begin
		for (int i = 0; i < CACHE_SIZE; i++) begin
			v[i] = 1;
			d[i] = 0;
			tag[i] = 0;
			// cache_data[i] = 0;
		end
		$readmemh("data.mem", cache_data);
	end

	assign addr_tag = addr[31 : 14];
	assign addr_index = addr[13 : 2];
	assign hit = (tag[addr_index] == addr_tag && v[addr_index]);

	assign wvalid = (wreq && hit) ? 1 : 0;
	assign rvalid = (rreq && hit) ? 1 : 0;

	always_comb begin
		if (hit && rreq) begin
			case (addr[1 : 0])
				2'b00 : rdata = cache_data[addr_index];
				2'b01 : rdata = {cache_data[addr_index + 1][7 :  0], cache_data[addr_index][31 :  8]};
				2'b10 : rdata = {cache_data[addr_index + 1][15 : 0], cache_data[addr_index][31 : 16]};
				2'b11 : rdata = {cache_data[addr_index + 1][23 : 0], cache_data[addr_index][31 : 24]};
			endcase // (addr[1 : 0])
		end else begin
			rdata = 32'b0;
		end
	end

	always_ff @(posedge clk) begin
		if (hit && wreq) begin
			case (addr[1 : 0])
				2'b00 : begin
					if (byte_enable[0]) cache_data[addr_index][ 7 :  0] <= wdata[7  :  0];
					if (byte_enable[1]) cache_data[addr_index][15 :  8]	 <= wdata[15 :  8];
					if (byte_enable[2]) cache_data[addr_index][23 : 16]	 <= wdata[23 : 16];
					if (byte_enable[3]) cache_data[addr_index][31 : 24]	 <= wdata[31 : 24];
				end
				2'b01 : begin
					if (byte_enable[0]) cache_data[addr_index    ][15 :  8]	 <= wdata[ 7 :  0];
					if (byte_enable[1]) cache_data[addr_index    ][23 : 16]	 <= wdata[15 :  8];
					if (byte_enable[2]) cache_data[addr_index    ][31 : 24]	 <= wdata[23 : 16];
					if (byte_enable[3]) cache_data[addr_index + 1][ 7 :  0]	 <= wdata[31 : 24];
				end
				2'b10 : begin
					if (byte_enable[0]) cache_data[addr_index    ][23 : 16]	 <= wdata[ 7 :  0];
					if (byte_enable[1]) cache_data[addr_index    ][31 : 24]	 <= wdata[15 :  8];
					if (byte_enable[2]) cache_data[addr_index + 1][ 7 :  0]	 <= wdata[23 : 16];
					if (byte_enable[3]) cache_data[addr_index + 1][15 :  8]	 <= wdata[31 : 24];
				end
				2'b11 : begin
					if (byte_enable[0]) cache_data[addr_index    ][31 : 24]	 <= wdata[ 7 :  0];
					if (byte_enable[1]) cache_data[addr_index + 1][ 7 :  0]	 <= wdata[15 :  8];
					if (byte_enable[2]) cache_data[addr_index + 1][15 :  8]	 <= wdata[23 : 16];
					if (byte_enable[3]) cache_data[addr_index + 1][23 : 16]	 <= wdata[31 : 24];
				end
			endcase // (addr[1 : 0])
		end
	end

	always_ff @(posedge clk) begin
		if (~rst_n) begin
			for (int i = 0; i < CACHE_SIZE; i++) begin
				d[i] <= 0;
			end
		end else begin
			if (hit && wreq) d[addr_index] <= 1;
		end
	end


	reg [2 : 0] wcnt_done;
	reg [2 : 0] rcnt_done;

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
			wcnt_done <= 0;
			rcnt_done <= 0;
		end else begin

			case (state)
				IDLE : begin
					ram_rready <= 0;
					wcnt_done <= 0;
					rcnt_done <= 0;
					if (!hit) begin // cache miss
						if (wreq || rreq) begin
							if (d[addr_index]) state <= WRITE_BACK;
							else state <= ALLOCATE;
						end
					end
				end
				WRITE_BACK : begin
					ram_awaddr <= {tag[addr_index], addr_index, 2'b00}; // write back addr
					ram_awlen  <= (addr[1 : 0] == 2'b00) ? 1 : 2;
					ram_awvalid <= 1;
					ram_wready <= 1;
					if (ram_awready) state <= WWAIT;
				end
				WWAIT : begin
					ram_awvalid <= 0;
					if (ram_wvalid) begin
						ram_wdata <= cache_data[addr_index + wcnt_done]; // write back data
						wcnt_done <= wcnt_done + 1;
						if (ram_wlast) state <= ALLOCATE;
					end
				end
				ALLOCATE : begin
					ram_wready <= 0;
					ram_araddr <= addr;
					ram_arlen  <= (addr[1 : 0] == 2'b00) ? 1 : 2;
					ram_arvalid <= 1;
					ram_rready <= 1;
					if (ram_arready) state <= RWAIT;
				end
				RWAIT : begin
					ram_arvalid <= 0;
					if (ram_rvalid) begin
						cache_data[addr_index + rcnt_done] <= ram_rdata;
						tag[addr_index + rcnt_done] <= addr_tag;
						v[addr_index + rcnt_done] <= 1;
						d[addr_index + rcnt_done] <= 0;
						rcnt_done <= rcnt_done + 1;
						if (ram_rlast) state <= IDLE;
					end
				end
				default : state <= IDLE;
			endcase // case (state)

		end
	end // always @(posedge clk)


endmodule // dcache
