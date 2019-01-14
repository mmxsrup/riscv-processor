`timescale 1ns / 1ps

import type_pkg::*;
import pc_mux_pkg::*;


module control (
	input logic clk,
	input logic rst_n,

	// from datapath
	input logic memory_done_i,
	input sel_pc_t pc_sel_i,
	input logic br_taken_i,
	input data_t ir_i,
	input addr_t next_pc_i,

	// to datapath
	output logic fetch_stall_o,
	output sel_pc_t pc_sel_o,
	output logic br_taken_o,
	output addr_t next_pc_o
);
	
	typedef enum logic {IDLE, RUN} state_type;
	state_type state;


	assign fetch_stall_o = (memory_done_i == 0) ? 1 : 0;
	assign pc_sel_o = (state != IDLE) ? pc_sel_i : SEL_PC_NONE;
	assign br_taken_o = br_taken_i;
	assign next_pc_o = (state != IDLE) ? next_pc_i : 32'h0;


	always @(posedge clk) begin
		if (~rst_n) begin
			state <= IDLE;
		end else begin
			case (state)
				IDLE : state <= RUN;
				RUN : state <= RUN;
				default : state <= IDLE;
			endcase // state
		end
	end // always @(posedge clk)


endmodule // control
