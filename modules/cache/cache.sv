`timescale 1ns / 1ps

import ram_pkg::*;


module cache (
	input clk,
	input rst_n,

	output [31 : 0] icache_data,
	output icache_valid,
	input [31 : 0] icache_addr,
	input icache_req,

	output dcache_wvalid,
	output [31 : 0] dcache_rdata,
	output dcache_rvalid,
	input [31 : 0] dcache_addr,
	input dcache_wreq,
	input dcache_rreq,
	input [31 : 0] dcache_wdata,
	input [3 : 0] dcache_byte_enable,

	// from icache
	output [AWIDTH - 1 : 0] i_ram_awaddr,
	output [LWIDTH - 1 : 0] i_ram_awlen,
	output i_ram_awvalid,
	input i_ram_awready,
	output [DWIDTH - 1 : 0] i_ram_wdata,
	input i_ram_wvalid,
	output i_ram_wready,
	input i_ram_wlast,
	output [AWIDTH - 1 : 0] i_ram_araddr,
	output [LWIDTH - 1 : 0] i_ram_arlen,
	output i_ram_arvalid,
	input i_ram_arready,
	input [DWIDTH - 1 : 0] i_ram_rdata,
	input i_ram_rvalid,
	output i_ram_rready,
	input i_ram_rlast,

	// from dcache
	output [AWIDTH - 1 : 0] d_ram_awaddr,
	output [LWIDTH - 1 : 0] d_ram_awlen,
	output d_ram_awvalid,
	input d_ram_awready,
	output [DWIDTH - 1 : 0] d_ram_wdata,
	input d_ram_wvalid,
	output d_ram_wready,
	input d_ram_wlast,
	output [AWIDTH - 1 : 0] d_ram_araddr,
	output [LWIDTH - 1 : 0] d_ram_arlen,
	output d_ram_arvalid,
	input d_ram_arready,
	input [DWIDTH - 1 : 0] d_ram_rdata,
	input d_ram_rvalid,
	output d_ram_rready,
	input d_ram_rlast
);


	icache icache (
		.clk(clk), .rst_n(rst_n),
		.addr(icache_addr), .req(icache_req), .data(icache_data), .valid(icache_valid),
		.ram_awaddr(i_ram_awaddr), .ram_awlen(i_ram_awlen), .ram_awvalid(i_ram_awvalid), .ram_awready(i_ram_awready),
		.ram_wdata(i_ram_wdata), .ram_wvalid(i_ram_wvalid), .ram_wready(i_ram_wready), .ram_wlast(i_ram_wlast),
		.ram_araddr(i_ram_araddr), .ram_arlen(i_ram_arlen), .ram_arvalid(i_ram_arvalid), .ram_arready(i_ram_arready),
		.ram_rdata(i_ram_rdata), .ram_rvalid(i_ram_rvalid), .ram_rready(i_ram_rready), .ram_rlast(i_ram_rlast)
	);

	dcache dcache (
		.clk(clk), .rst_n(rst_n),
		.addr(dcache_addr), .wreq(dcache_wreq), .rreq(dcache_rreq), .wdata(dcache_wdata), .byte_enable(dcache_byte_enable),
		.wvalid(dcache_wvalid), .rdata(dcache_rdata), .rvalid(dcache_rvalid),
		.ram_awaddr(d_ram_awaddr), .ram_awlen(d_ram_awlen), .ram_awvalid(d_ram_awvalid), .ram_awready(d_ram_awready),
		.ram_wdata(d_ram_wdata), .ram_wvalid(d_ram_wvalid), .ram_wready(d_ram_wready), .ram_wlast(d_ram_wlast),
		.ram_araddr(d_ram_araddr), .ram_arlen(d_ram_arlen), .ram_arvalid(d_ram_arvalid), .ram_arready(d_ram_arready),
		.ram_rdata(d_ram_rdata), .ram_rvalid(d_ram_rvalid), .ram_rready(d_ram_rready), .ram_rlast(d_ram_rlast)
	);


endmodule // cache