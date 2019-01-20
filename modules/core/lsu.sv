 `timescale 1ns / 1ps

module lsu
	import type_pkg::*;
(
	input logic clk,
	input logic rst_n,

	// from execute
	input opcode_t opcode,
	input func3_t func3,
	input data_t alu_out,
	input data_t rs2,

	// // to dcache
	output logic valid,
	output addr_t addr,
	output data_t wdata,
	output byte_en_t byte_enable,
	// from dcache
	input logic ready,
	input data_t dcache_rdata,

	// to writeback
	output data_t rdata, // read data
	// to controller
	output logic done // load or store done
);


	parameter OP_STORE = 7'b0100011;
	parameter OP_LOAD  = 7'b0000011;
	parameter FUNC3_B = 3'b000; // sb, lb
	parameter FUNC3_H = 3'b001; // sh, lh
	parameter FUNC3_W = 3'b010; // sw, lw,
	parameter FUNC3_BU = 3'b100; // lbu
	parameter FUNC3_HU = 3'b101; // lhu

	typedef enum logic [1 : 0] {
		IDLE, LOW, HIGH, DONE
	} state_type;
	state_type state, next_state;
	data_t tmp_data;

	assign valid = (opcode == OP_STORE | opcode == OP_LOAD);
	assign addr = alu_out;
	assign wdata = (opcode == OP_STORE) ? rs2 : 32'b0;
	assign byte_enable = (opcode == OP_LOAD) ? 4'b0000 :
						   (func3 == FUNC3_B || func3 == FUNC3_BU) ? 4'b0001 :
						   (func3 == FUNC3_H || func3 == FUNC3_HU) ? 4'b0011 :
						   (func3 == FUNC3_W) ? 4'b1111 : 4'b0000;

	always_comb begin
		case (func3)
			FUNC3_B  : rdata = { {25{tmp_data[7]}}, tmp_data[6 : 0] };
			FUNC3_H  : rdata = { {17{tmp_data[15]}}, tmp_data[14 : 0]};
			FUNC3_W  : rdata = tmp_data;
			FUNC3_BU : rdata = { 24'b0, tmp_data[7 : 0] };
			FUNC3_HU : rdata = { 16'b0, tmp_data[15 : 0]};
		endcase // func3
	end

	assign done = (state == DONE && valid && ready) | !valid;

	always_ff @(posedge clk) begin
		if(~rst_n) begin
			tmp_data <= 0;
		end else begin
			if (state == LOW && ready) begin
				case (addr[1 : 0])
					2'b00 : tmp_data[0 +: 32] <= dcache_rdata[0  +: 32];
					2'b01 : tmp_data[0 +: 24] <= dcache_rdata[8  +: 24];
					2'b10 : tmp_data[0 +: 16] <= dcache_rdata[16 +: 16];
					2'b11 : tmp_data[0 +:  8] <= dcache_rdata[24 +:  8];
				endcase
			end else if (state == HIGH && ready) begin
				case (addr[1 : 0])
					2'b01 : tmp_data[24 +:  8] <= dcache_rdata[0 +:  8];
					2'b10 : tmp_data[16 +: 16] <= dcache_rdata[0 +: 16];
					2'b11 : tmp_data[8 +:  24] <= dcache_rdata[0 +: 24];
					default : tmp_data <= 0;
				endcase
			end
		end
	end

	always_comb begin
		case (state)
			IDLE : if (valid) next_state = LOW;
			LOW  : begin
				if (ready) begin
					next_state = (addr[1 : 0] == 2'b00) ? DONE : HIGH;
				end
			end
			HIGH : if (ready) next_state = DONE;
			DONE : next_state = IDLE;
			default : next_state = IDLE;
		endcase
	end

	always_ff @(posedge clk) begin
		if (~rst_n) begin
			state <= IDLE;
		end else begin
			state <= next_state;
		end
	end

endmodule // lsu
