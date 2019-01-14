`timescale 1ns / 1ps

import type_pkg::*;
import pc_mux_pkg::*;


module datapath (
	input logic clk,
	input logic rst_n,

	// from controller
	input c_fetch_stall,
	input sel_pc_t c_pc_sel,
	input c_br_taken,
	input addr_t c_next_pc,

	// to controller
	output memory_done,
	output sel_pc_t pc_sel,
	output br_taken,
	output data_t ir,
	output addr_t next_pc,

	input data_t icache_data,
	input icache_valid,
	output addr_t icache_addr,
	output icache_req,

	input dcache_wvalid,
	input data_t dcache_rdata,
	input dcache_rvalid,
	output addr_t dcache_addr,
	output dcache_wreq,
	output dcache_rreq,
	output data_t dcache_wdata,
	output byte_en_t dcache_byte_enable
);
		
	reg_addr_t rs1_num;
	reg_addr_t rs2_num;
	data_t rs1_data;
	data_t rs2_data;
	// wire [4 : 0] wb_rd_num;
	data_t wb_rd_data;
	logic wb_enable;
	csr_addr_t csr_addr;
	data_t csr_rdata;
	data_t csr_wdata;
	logic csr_wb;
	data_t mtvec;
	data_t mepc;

	// from fetch to decode_execute
	data_t F_DE_ir_w;

	data_t DE_F_imm;

	// from decode_execute to memory_writeback
	opcode_t DE_MW_opcode_w;
	func3_t DE_MW_func3_w;
	logic DE_MW_wb_reg_w;
	reg_addr_t DE_MW_rd_num_w;
	data_t DE_MW_rd_data_w;

	data_t dcache_out;

	data_t pc;

	initial begin
		pc = 32'h0;
	end

	regfile regfile (
		.clk(clk), .rst_n(rst_n),
		.w_enable(wb_enable),
		.rs1_num(rs1_num), .rs2_num(rs2_num), .rd_num(DE_MW_rd_num_w),
		.rd_data(wb_rd_data), .rs1_data(rs1_data), .rs2_data(rs2_data)
	);

	csr_file csr_file (
		.clk(clk), .rst_n(rst_n),
		.w_enable(csr_wb),
		.addr(csr_addr), .wdata(csr_wdata),
		.rdata(csr_rdata),
		.mtvec(mtvec), .mepc(mepc)
	);


	// Fetch Stage (1st Stage)	
	fetch fetch (
		.clk(clk), .rst_n(rst_n),
		.pc(pc),
		.stall(c_fetch_stall), // from controller
		.rs1(rs1_data), // from regfile
		.imm(DE_F_imm), .pc_sel(c_pc_sel), .taken(c_br_taken), // from decode_execute
		.mtvec(mtvec), .mepc(mepc), // from csr_file
		.ir_code(F_DE_ir_w), .next_pc(next_pc),
		.icache_data(icache_data), .icache_valid(icache_valid),
		.icache_addr(icache_addr), .icache_req(icache_req)
	);


	// Decode and Execute Stage (2nd Stage)
	decode_execute decode_execute (
		.ir(F_DE_ir_w), .pc(pc),
		.rs1_data(rs1_data), .rs2_data(rs2_data), // from regfile
		.csr_rdata(csr_rdata), // from csr_file
		.rs1_num(rs1_num), .rs2_num(rs2_num), // to regfile
		.opcode(DE_MW_opcode_w), .func3(DE_MW_func3_w),
		.wb_reg(DE_MW_wb_reg_w), .rd_num(DE_MW_rd_num_w), .rd_data(DE_MW_rd_data_w),
		.imm(DE_F_imm), .pc_sel(pc_sel), .br_taken(br_taken), // to fetch
		.csr_addr(csr_addr), .csr_wdata(csr_wdata), .csr_wb(csr_wb) // to csr_file
	);


	lsu lsu (
		.clk(clk), .rst_n(rst_n),
		.opcode(DE_MW_opcode_w), .func3(DE_MW_func3_w), .alu_out(DE_MW_rd_data_w), .rs2(rs2_data),
		.dcache_addr(dcache_addr), .dcache_wreq(dcache_wreq), .dcache_rreq(dcache_rreq), .dcache_wdata(dcache_wdata), .dcache_byte_enable(dcache_byte_enable),
		.dcache_wvalid(dcache_wvalid), .dcache_rdata(dcache_rdata), .dcache_rvalid(dcache_rvalid),
		.rdata(dcache_out), .done(memory_done)
	);


	writeback writeback (
		.opcode(DE_MW_opcode_w),
		.alu_out(DE_MW_rd_data_w), .wb_reg(DE_MW_wb_reg_w),
		.dcache_out(dcache_out), .done(memory_done),
		.wb_rd_data(wb_rd_data), .wb_enable(wb_enable)
	);


	always @(posedge clk) begin
		if(~rst_n) begin
			pc <= 32'h0;
		end else begin
			pc <= c_next_pc;
		end
	end


endmodule // datapath
