`timescale 1ns / 1ps

import type_pkg::*;
import csr_addr_pkg::*;


module csr_file #(
	localparam CSR_SIZE = 4096
)(
	input logic clk,
	input logic rst_n,

	input logic w_enable,

	csr_addr_t addr,
	input data_t wdata,
	output data_t rdata,

	output data_t mtvec,
	output data_t mepc
);


	data_t csrs[CSR_SIZE];

	assign rdata = csrs[addr];
	assign mtvec = csrs[CSR_ADDR_MTVEC];
	assign mepc  = csrs[CSR_ADDR_MEPC];


	initial begin
		for (int i = 0; i < CSR_SIZE; i = i + 1) begin
			csrs[i] = 32'h0;
		end
	end

	// write back
	always_ff @(posedge clk) begin
		if (~rst_n) begin
			for (int i = 0; i < CSR_SIZE; i++) begin
				csrs[i] = 32'h0;
			end
		end else if (w_enable) begin
			csrs[addr] <= wdata;
		end
	end


endmodule // csr_file
