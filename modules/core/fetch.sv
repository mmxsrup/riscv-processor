`timescale 1ns / 1ps

import type_pkg::*;
import pc_mux_pkg::*;


module fetch (
	input logic clk,
	input logic rst_n,

	input addr_t pc,
	input logic stall,

	input data_t rs1,
	input data_t imm,
	input sel_pc_t pc_sel,

	input logic taken,

	input data_t mtvec,
	input data_t mepc,

	// to decode
	output data_t ir_code,
	// to control
	output addr_t next_pc,

	// from icache
	input data_t icache_data,
	input logic icache_valid,
	// to icache
	output addr_t icache_addr,
	output logic icache_req
);

	parameter NOP = 32'b00000000_00000000_00000000_00010011;

	typedef enum logic [1 : 0] {IDLE, RUN, WAIT} state_type;
	state_type state;

	// from pc_mux
	wire [31 : 0] pc_mux_out;

	assign ir_code = (icache_valid) ? icache_data : NOP;
	assign icache_addr = pc;
	assign next_pc = (icache_valid) ? pc_mux_out : pc;
	assign icache_req = (state == RUN) ? 1'b1 : 1'b0;


	pc_mux pc_mux (
		.pc(pc),
		.rs1(rs1), .imm(imm), .pc_sel(pc_sel),
		.taken(taken),
		.stall(stall),
		.mtvec(mtvec), .mepc(mepc),
		.next_pc(pc_mux_out)
	);


	always_ff @(posedge clk) begin
		if (~rst_n) begin
			state <= IDLE;
		end else begin
			case (state)
				IDLE : state <= RUN;
				RUN : begin
					if (icache_valid) state <= RUN; // Cache HIT
					else state <= WAIT; // Cache MISS
				end
				WAIT : begin // TODO
					if (icache_valid) state <= RUN;
				end
				default : state <= RUN;
			endcase // case (state)
		end
	end // always @(posedge clk) 

endmodule // fetch
