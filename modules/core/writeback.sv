`timescale 1ns / 1ps

module writeback
	import type_pkg::*;
(
	input opcode_t opcode,

	// from decode_execute
	input data_t alu_out,
	input logic wb_reg,

	// from memory
	input data_t dcache_out,
	input logic done,

	// to regfile
	output data_t wb_rd_data,
	output logic wb_enable
);

	localparam OP_LOAD = 7'b0000011;

	assign wb_enable = (done) ? wb_reg : 0;

	always_comb begin
		if (wb_enable) begin
			if (opcode == OP_LOAD) wb_rd_data = dcache_out;
			else wb_rd_data = alu_out;
		end else begin
			wb_rd_data = 32'h0;
		end
	end

endmodule // writeback
