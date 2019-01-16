`timescale 1ns / 1ps

module regfile
	import type_pkg::*;
(
	input logic clk,
	input logic rst_n,

	// from controller
	input logic w_enable,

	// from decoder
	input reg_addr_t rs1_num,
	input reg_addr_t rs2_num,
	input reg_addr_t rd_num,

	// from alu
	input data_t rd_data,

	// to alu src mux
	output data_t rs1_data,
	output data_t rs2_data
);
	
	// 	general registers
	data_t datas[XLEN];

	initial begin
		for (integer i = 0; i < 32; i = i + 1) begin
			datas[i] = 32'h0;
		end
	end

	assign rs1_data = (rs1_num == 0) ? 32'h0 : datas[rs1_num];
	assign rs2_data = (rs2_num == 0) ? 32'h0 : datas[rs2_num];


	// write back
	always_ff @(posedge clk) begin
		if (~rst_n) begin
			for (int i = 0; i < 32; i++) begin
				datas[i] = 32'h0;
			end
		end else if (w_enable && rd_num != 0) begin
			datas[rd_num] <= rd_data;
		end
	end


endmodule // regfile
