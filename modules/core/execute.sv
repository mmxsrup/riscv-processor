`timescale 1ns / 1ps

import type_pkg::*;
import alu_op_pkg::*;
import src_a_mux_pkg::*;
import src_b_mux_pkg::*;


module execute (
	// from controller
	input addr_t pc,

	// from decoder
	input data_t imm,
	input alu_op_t alu_op_sel,
	input sel_src_a_t src_a_sel,
	input sel_src_b_t src_b_sel,

	// from regfile (decode_execute)
	input data_t rs1_data,
	input data_t rs2_data,

	// to write back
	output data_t alu_out
);
	

	data_t alu_src_a;
	data_t alu_src_b;


	src_a_mux src_a_mux (
		.pc(pc),
		.rs1_data(rs1_data),
		.imm(imm),
		.select(src_a_sel),
		.alu_src_a(alu_src_a)
	);

	src_b_mux src_b_mux (
		.rs2_data(rs2_data),
		.imm(imm),
		.select(src_b_sel),
		.alu_src_b(alu_src_b)
	);

	alu alu (
		.operator(alu_op_sel),
		.operand1(alu_src_a), .operand2(alu_src_b),
		.out(alu_out)
	);


endmodule // execute
