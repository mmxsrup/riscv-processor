`timescale 1ns / 1ps

module src_a_mux
	import type_pkg::*;
	import src_a_mux_pkg::*;
(
	// from control
	input addr_t pc,
	// from regfile
	input data_t rs1_data,
	// from decode
	input data_t imm,
	input sel_src_a_t select,

	// to alu
	output data_t alu_src_a
);

	always_comb begin
		case (select)
			SEL_SRC_A_PC  : alu_src_a = pc;
			SEL_SRC_A_RS1 : alu_src_a = rs1_data;
			SEL_SRC_A_IMM : alu_src_a = imm;
			default : alu_src_a = 32'b0;
		endcase
	end


endmodule // src_a_mux
