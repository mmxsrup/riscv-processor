`timescale 1ns / 1ps

module fetch
	import type_pkg::*;
	import pc_mux_pkg::*;
(
	input logic clk,
	input logic rst_n,

	input addr_t pc,
	input logic stall,

	input data_t rs1,
	input data_t imm,
	input sel_pc_t pc_sel,

	input logic taken,

	input data_t mtvec,
	input data_t mepc,

	// to decode
	output data_t ir_code,
	// to control
	output addr_t next_pc,

	// from icache
	input data_t rdata,
	input logic ready,
	// to icache
	output logic valid,
	output addr_t addr
);

	parameter NOP = 32'b00000000_00000000_00000000_00010011;

	// from pc_mux
	wire [31 : 0] pc_mux_out;

	assign ir_code = (valid && ready) ? rdata : NOP;
	assign addr = pc;
	assign next_pc = (valid && ready) ? pc_mux_out : pc;


	pc_mux pc_mux (
		.pc(pc),
		.rs1(rs1), .imm(imm), .pc_sel(pc_sel),
		.taken(taken),
		.stall(stall),
		.mtvec(mtvec), .mepc(mepc),
		.next_pc(pc_mux_out)
	);

	always_ff @(posedge clk) begin
		if(~rst_n) begin
			valid <= 0;
		end else begin
			valid <= 1;
		end
	end

endmodule // fetch
