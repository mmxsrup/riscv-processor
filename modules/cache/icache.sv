`timescale 1ns / 1ps

module icache #(
	parameter CACHE_SIZE = 4096,
	parameter INIT_FILE  = ""
)(
	input logic clk,
	input logic rst_n,
	
	// from lsu
	input logic valid,
	input logic [31 : 0] addr,

	// to lsu
	output logic ready,
	output logic [31 : 0] rdata,

	axi_lite_if.master m_axi
);

	typedef enum logic [3 : 0] {
		IDLE, ALLOCATE, RADDR, RDATA, WADDR, WDATA, WRESP
	} state_type;
	state_type state, next_state;

	logic [31 : 0] ram_rdata;
	logic [31 : 0] rdata;
	logic hit;

	assign ready = (state == IDLE) ? 1 : 0;
	assign ram_rdata = (state == RDATA) ? m_axi.rdata : 0;

	// AR
	assign m_axi.araddr  = (state == RADDR) ? addr : 32'h0;
	assign m_axi.arvalid = (state == RADDR) ? 1 : 0;

	// Rgit log
	assign m_axi.rready = (state == RDATA) ? 1 : 0;

	// AW
	assign m_axi.awvalid = (state == WADDR) ? 1 : 0;
	assign m_axi.awaddr  = (state == WADDR) ? addr : 32'h0;

	// W
	assign m_axi.wvalid = (state == WDATA) ? 1 : 0;
	assign m_axi.wdata  = (state == WDATA) ? rdata : 32'h0;
	assign m_axi.wstrb  = 4'b0000;

	// B
	assign m_axi.bready = (state == WRESP) ? 1 : 0;


	cachemem #(.INIT_FILE(INIT_FILE)) cachemem (
		.clk(clk), .rst_n(rst_n),
		.en(valid), .we(4'b0000), .allocate((state == ALLOCATE) ? 1'b1 : 1'b0),
		.addr(addr), .wdata((state == ALLOCATE) ? ram_rdata : 0), .rdata(rdata),
		.hit(hit)
	);


	always_comb begin
		case (state)
			IDLE : next_state = (!hit && valid) ? ALLOCATE : IDLE;
			ALLOCATE : next_state = IDLE;
			RADDR : if (m_axi.arvalid && m_axi.arready) next_state = RDATA;
			RDATA : if (m_axi.rvalid  && m_axi.rready ) next_state = ALLOCATE;
			WADDR : if (m_axi.awvalid && m_axi.awready) next_state = WDATA;
			WDATA : if (m_axi.wvalid  && m_axi.wready ) next_state = WRESP;
			WRESP : if (m_axi.bvalid  && m_axi.bready ) next_state = RADDR;
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
