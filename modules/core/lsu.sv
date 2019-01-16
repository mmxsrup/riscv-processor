`timescale 1ns / 1ps

module lsu
	import type_pkg::*;
(
	input logic clk,
	input logic rst_n,

	// from execute
	input opcode_t opcode,
	input func3_t func3,
	input data_t alu_out,
	input data_t rs2,

	// // to dcache
	output logic valid,
	output addr_t addr,
	output data_t wdata,
	output byte_en_t byte_enable,
	// from dcache
	input logic ready,
	input data_t dcache_rdata,

	// to writeback
	output data_t rdata, // read data
	// to controller
	output logic done // load or store done
);


	parameter OP_STORE = 7'b0100011;
	parameter OP_LOAD  = 7'b0000011;
	parameter FUNC3_B = 3'b000; // sb, lb
	parameter FUNC3_H = 3'b001; // sh, lh
	parameter FUNC3_W = 3'b010; // sw, lw,
	parameter FUNC3_BU = 3'b100; // lbu
	parameter FUNC3_HU = 3'b101; // lhu


	assign valid = (opcode == OP_STORE | opcode == OP_LOAD);
	assign addr = alu_out;
	assign wdata = (opcode == OP_STORE) ? rs2 : 32'b0;
	assign byte_enable = (opcode == OP_LOAD) ? 4'b0000 :
						   (func3 == FUNC3_B || func3 == FUNC3_BU) ? 4'b0001 :
						   (func3 == FUNC3_H || func3 == FUNC3_HU) ? 4'b0011 :
						   (func3 == FUNC3_W) ? 4'b1111 : 4'b0000;

	always_comb begin
		case (func3)
			FUNC3_B  : rdata = { {25{dcache_rdata[7]}}, dcache_rdata[6 : 0] };
			FUNC3_H  : rdata = { {17{dcache_rdata[15]}}, dcache_rdata[14 : 0]};
			FUNC3_W  : rdata = dcache_rdata;
			FUNC3_BU : rdata = { 24'b0, dcache_rdata[7 : 0] };
			FUNC3_HU : rdata = { 16'b0, dcache_rdata[15 : 0]};
		endcase // func3
	end

	assign done = (valid && ready) | !valid;

endmodule // lsu
