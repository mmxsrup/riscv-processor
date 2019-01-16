`timescale 1ns / 1ps

module core
	import type_pkg::*;
	import pc_mux_pkg::*;
(
	input logic clk,
	input logic rst_n,

	input data_t icache_rdata,
	input logic icache_ready,
	output logic icache_valid,
	output addr_t icache_addr,

	input logic dcache_ready,
	input data_t dcache_rdata,
	output logic dcache_valid,
	output addr_t dcache_addr,
	output data_t dcache_wdata,
	output byte_en_t dcache_byte_enable
);


	// from datapath to control
	logic D_C_memory_done;
	sel_pc_t D_C_pc_sel;
	logic D_C_br_taken;
	data_t D_C_ir;
	addr_t D_C_next_pc;

	// from control to datapath
	logic C_D_fetch_stall;
	sel_pc_t C_D_pc_sel;
	logic C_D_br_taken;
	addr_t C_D_next_pc;


	control control (
		.clk(clk), .rst_n(rst_n),
		.memory_done_i(D_C_memory_done), .pc_sel_i(D_C_pc_sel),
		.br_taken_i(D_C_br_taken), .ir_i(D_C_ir), .next_pc_i(D_C_next_pc),
		.fetch_stall_o(C_D_fetch_stall), .pc_sel_o(C_D_pc_sel),
		.br_taken_o(C_D_br_taken), .next_pc_o(C_D_next_pc)
	);


	datapath datapath (
		.clk(clk), .rst_n(rst_n),
		.c_fetch_stall(C_D_fetch_stall), .c_pc_sel(C_D_pc_sel),
		.c_br_taken(C_D_br_taken), .c_next_pc(C_D_next_pc),
		.memory_done(D_C_memory_done), .pc_sel(D_C_pc_sel), .br_taken(D_C_br_taken),
		.ir(D_C_ir), .next_pc(D_C_next_pc),
		.icache_rdata(icache_rdata), .icache_ready(icache_ready),
		.icache_valid(icache_valid), .icache_addr(icache_addr),
		.dcache_valid(dcache_valid), .dcache_addr(dcache_addr),
		.dcache_wdata(dcache_wdata), .dcache_byte_enable(dcache_byte_enable),
		.dcache_ready(dcache_ready), .dcache_rdata(dcache_rdata)
	);


endmodule // core
