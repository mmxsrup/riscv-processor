`timescale 1ns / 1ps

module pc_mux
	import type_pkg::*;
	import pc_mux_pkg::*;
(
	input data_t pc,	
	input data_t rs1, // from decoder
	input data_t imm, // from decoder
	input sel_pc_t pc_sel, // from decode
	input logic taken, // from br_cond
	input logic stall, // from controller
	input data_t mtvec,
	input data_t mepc,
	output data_t next_pc
);

	always_comb begin
			if (stall) begin // stall
			next_pc = pc;
		end else if (taken) begin // branch is taken
			next_pc = pc + imm;
		end else begin
			case (pc_sel)
				SEL_PC_JAL  : next_pc = pc + imm; // jump and link
				SEL_PC_JALR : next_pc = rs1 + imm; // jump and link register
				SEL_PC_ADD4 : next_pc = pc + 32'h4; // +4
				SEL_PC_MTVEC : next_pc = mtvec;
				SEL_PC_MEPC  : next_pc = mepc;
				SEL_PC_NONE : next_pc = 32'h0;
			endcase // pc_sel
		end
	end
	
	
endmodule // pc_mux
