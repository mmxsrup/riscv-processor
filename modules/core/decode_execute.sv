`timescale 1ns / 1ps

module decode_execute
	import type_pkg::*;
	import alu_op_pkg::*;
	import src_a_mux_pkg::*;
	import src_b_mux_pkg::*;
	import pc_mux_pkg::*;
(
	// from fetch
	input data_t ir,
	input addr_t pc,

	// from regfile
	input data_t rs1_data,
	input data_t rs2_data,

	// from csr_file
	input data_t csr_rdata,

	// to regfile
	output reg_addr_t rs1_num,
	output reg_addr_t rs2_num,

	// to memory_writeback
	output opcode_t opcode,
	output func3_t func3,
	output wb_reg, // write back to reg
	output reg_addr_t rd_num,
	output data_t rd_data,

	// to fetch
	output data_t imm,
	output sel_pc_t pc_sel,
	output br_taken,

	// to csr_file
	output csr_addr_t csr_addr,
	output data_t csr_wdata,
	output csr_wb,

	output logic flash
);
	
	parameter OP_BRANCH = 7'b1100011;

	data_t imm_w;
	data_t alu_out;
	alu_op_t alu_op_sel;
	sel_src_a_t src_a_sel;
	sel_src_b_t src_b_sel;

	assign opcode = ir[6 : 0];
	assign func3  = ir[14 : 12];

	assign br_taken = (opcode == OP_BRANCH && alu_out == 32'b1) ? 1 : 0;
	assign rd_data = (opcode == 7'b1110011) ? csr_rdata : alu_out;
	assign imm = imm_w;

	decode decode (
		.code(ir), .pc(pc), .rs1_data(rs1_data), .csr_rdata(csr_rdata),
		.rs1_num(rs1_num), .rs2_num(rs2_num), .rd_num(rd_num), .imm(imm_w),
		.alu_op_sel(alu_op_sel),
		.src_a_sel(src_a_sel), .src_b_sel(src_b_sel), .pc_sel(pc_sel),
		.wb_reg(wb_reg),
		.csr_addr(csr_addr), .csr_wdata(csr_wdata), .csr_wb(csr_wb),
		.flash(flash)
	);

	execute execute (
		.pc(pc), .imm(imm_w),
		.alu_op_sel(alu_op_sel), .src_a_sel(src_a_sel), .src_b_sel(src_b_sel),
		.rs1_data(rs1_data), .rs2_data(rs2_data),
		.alu_out(alu_out)
	);


endmodule // decode_execute
