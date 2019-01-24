`timescale 1ns / 1ps

module icache #(
	parameter CACHE_SIZE = 128,
	parameter INIT_FILE  = ""
)(
	input logic clk,
	input logic rst_n,
	input logic flash,
	
	// from lsu
	input logic valid,
	input logic [31 : 0] addr,

	// to lsu
	output logic ready,
	output logic [31 : 0] rdata,

	axi_lite_if.master m_axi
);

	typedef enum logic [1 : 0] {
		IDLE, RADDR, RDATA, ALLOCATE
	} state_type;
	state_type state, next_state;

	logic [31 : 0] ram_rdata;
	logic [31 : 0] rdata;
	logic hit;

	assign ready = (hit) ? 1 : 0;
	assign ram_rdata = (state == RDATA) ? m_axi.rdata : ram_rdata;

	// AR
	assign m_axi.araddr  = (state == RADDR) ? addr : 32'h0;
	assign m_axi.arvalid = (state == RADDR) ? 1 : 0;

	// R
	assign m_axi.rready = (state == RDATA) ? 1 : 0;

	// AW
	assign m_axi.awvalid = 0;
	assign m_axi.awaddr  = 32'h0;

	// W
	assign m_axi.wvalid = 0;
	assign m_axi.wdata  = 32'h0;
	assign m_axi.wstrb  = 4'b0000;

	// B
	assign m_axi.bready = 0;


	cachemem #(.INIT_FILE(INIT_FILE)) cachemem (
		.clk(clk), .rst_n(rst_n), .flash(flash),
		.en(valid), .we((state == ALLOCATE) ? 4'b1111 : 4'b0000),
		.allocate((state == ALLOCATE) ? 1'b1 : 1'b0),
		.addr(addr), .wdata((state == ALLOCATE) ? ram_rdata : 0), .rdata(rdata),
		.hit(hit)
	);


	always_comb begin
		case (state)
			IDLE : next_state = (!hit && valid) ? RADDR : IDLE;
			RADDR : if (m_axi.arvalid && m_axi.arready) next_state = RDATA;
			RDATA : if (m_axi.rvalid  && m_axi.rready ) next_state = ALLOCATE;
			ALLOCATE : next_state = IDLE;
			default : next_state = IDLE;
		endcase
	end

	always_ff @(posedge clk) begin
		if (~rst_n) begin
			state <= IDLE;
		end else begin
			state <= next_state;
		end
	end

endmodule // icache
