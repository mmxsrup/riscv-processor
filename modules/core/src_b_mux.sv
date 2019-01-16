`timescale 1ns / 1ps

module src_b_mux
	import type_pkg::*;
	import src_b_mux_pkg::*;
(
	// from regfile
	input data_t rs2_data,
	// from decoder
	input data_t imm,
	input sel_src_b_t select,

	// to alu
	output data_t alu_src_b
);

	always_comb begin
		case (select)
			SEL_SRC_B_RS2 : alu_src_b = rs2_data;
			SEL_SRC_B_IMM : alu_src_b = imm;
			SEL_SRC_B_0 : alu_src_b = 32'h0;
			SEL_SRC_B_4 : alu_src_b = 32'h4;
			default : alu_src_b = 32'b0;
		endcase
	end


endmodule // src_b_mux
