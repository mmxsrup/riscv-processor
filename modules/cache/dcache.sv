`timescale 1ns / 1ps


module dcache
    import axi_pkg::*;
#(
	parameter CACHE_SIZE = 4096,
	parameter INIT_FILE  = ""
)(
	input logic clk,
	input logic rst_n,
	input logic flash,

	// from lsu
	input logic valid,
	input logic [31 : 0] addr,
	input logic [31 : 0] wdata,
	input logic [3 : 0] byte_enable,

	// to lsu
	output logic ready,
	output logic [31 : 0] rdata,

	axi_if.master m_axi
);

	typedef enum logic [3 : 0] {
		IDLE, WRITEBACK, ALLOCATE, RADDR, RDATA, WADDR, WDATA, WRESP, FLASH
	} state_type;
	state_type state, next_state;

	logic [31 : 0] ram_rdata;
	logic [31 : 0] rdata;
	logic hit, dirty;
	len_t flash_cnt; // TODO

	assign ready = (state == IDLE && hit) ? 1 : 0;

	always_ff @(posedge clk) begin
		if(~rst_n) begin
			ram_rdata <= 0;
		end else begin
			if (state == RDATA) ram_rdata <= m_axi.rdata;
		end
	end

	// AR
	assign m_axi.araddr  = (state == RADDR) ? addr : 32'h0;
	assign m_axi.arvalid = (state == RADDR) ? 1 : 0;
	assign m_axi.arlen = 0;
	assign m_axi.arsize = SIZE_4_BYTE;
	assign m_axi.arburst = BURST_INCR;

	// R
	assign m_axi.rready = (state == RDATA) ? 1 : 0;

	// AW
	assign m_axi.awaddr  = (state == WADDR) ? addr : 32'h0;
	assign m_axi.awvalid = (state == WADDR) ? 1 : 0;
	assign m_axi.awlen = (flash) ? CACHE_SIZE - 1 : 0;
	assign m_axi.awsize = SIZE_4_BYTE;
	assign m_axi.awburst = BURST_INCR;

	// W
	assign m_axi.wdata  = (state == WDATA) ? rdata : 32'h0;
	assign m_axi.wstrb  = (flash) ? 4'b1111 : byte_enable;
	assign m_axi.wvalid = (state == WDATA) ? 1 : 0;
	assign m_axi.wlast = (state == WDATA && (flash_cnt == CACHE_SIZE - 1 || !flash)) ? 1 : 0;

	// B
	assign m_axi.bready = (state == WRESP) ? 1 : 0;


	cachemem #(.INIT_FILE(INIT_FILE)) cachemem (
		.clk(clk), .rst_n(rst_n), .flash(1'b0),
		.en(valid), .we((state == ALLOCATE) ? 4'b1111 : byte_enable),
		.allocate((state == ALLOCATE) ? 1'b1 : 1'b0),
		.addr((flash) ? (flash_cnt << 2) : addr), .wdata((state == ALLOCATE) ? ram_rdata : wdata), .rdata(rdata),
		.hit(hit), .dirty(dirty)
	);


	always_ff @(posedge clk) begin
		if(~rst_n) begin
			flash_cnt <= 0;
		end else begin
			if (state == WDATA && m_axi.wvalid && m_axi.wready)
				flash_cnt <= flash_cnt + 1;
			else
				flash_cnt <= 0;
		end
	end

	always_comb begin
		case (state)
			IDLE : next_state = (flash) ? FLASH :
								  (!hit && dirty && valid) ? WRITEBACK :
								  (!hit && valid) ? RADDR : IDLE;
			WRITEBACK : next_state = WADDR;
			ALLOCATE : next_state = IDLE;
			RADDR : if (m_axi.arvalid && m_axi.arready) next_state = RDATA;
			RDATA : if (m_axi.rvalid  && m_axi.rready ) next_state = ALLOCATE;
			WADDR : if (m_axi.awvalid && m_axi.awready) next_state = WDATA;
			WDATA : if (m_axi.wvalid  && m_axi.wready && m_axi.wlast) next_state = WRESP;
			WRESP : if (m_axi.bvalid  && m_axi.bready ) next_state = RADDR;
			FLASH : next_state = WADDR;
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

endmodule // dcache
