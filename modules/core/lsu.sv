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

	data_t tmp_rdata, tmp_wdata;
	byte_en_t tmp_byte_enable;

	assign valid = (opcode == OP_STORE || opcode == OP_LOAD) && (state == LOW || state == HIGH);
	// always_ff @(posedge clk) begin
	// 	if(~rst_n) begin
	// 		valid <= 0;
	// 	end else begin
	// 		valid <= (opcode == OP_STORE || opcode == OP_LOAD);
	// 	end
	// end

	// assign addr = (state == HIGH) ? alu_out + 32'h4 : alu_out;
	assign addr = (state == LOW) ? ((alu_out >> 2) << 2) : (state == HIGH) ? (((alu_out + 32'h4) >> 2) << 2) : 0;
	assign wdata = (opcode == OP_STORE) ? tmp_wdata : 32'b0;
	assign byte_enable = tmp_byte_enable;

	always_comb begin
		case (func3)
			FUNC3_B  : rdata = { {25{tmp_rdata[7]}}, tmp_rdata[6 : 0] };
			FUNC3_H  : rdata = { {17{tmp_rdata[15]}}, tmp_rdata[14 : 0]};
			FUNC3_W  : rdata = tmp_rdata;
			FUNC3_BU : rdata = { 24'b0, tmp_rdata[7 : 0] };
			FUNC3_HU : rdata = { 16'b0, tmp_rdata[15 : 0]};
		endcase // func3
	end

	assign done = (state == DONE) | (opcode != OP_STORE && opcode != OP_LOAD);

	always_ff @(posedge clk) begin
		if(~rst_n) begin
			tmp_rdata <= 0;
		end else begin
			if (opcode == OP_LOAD) begin
				if (state == LOW && ready) begin
					case (alu_out[1 : 0])
						2'b00 : tmp_rdata[0 +: 32] <= dcache_rdata[0  +: 32];
						2'b01 : tmp_rdata[0 +: 24] <= dcache_rdata[8  +: 24];
						2'b10 : tmp_rdata[0 +: 16] <= dcache_rdata[16 +: 16];
						2'b11 : tmp_rdata[0 +:  8] <= dcache_rdata[24 +:  8];
					endcase
				end else if (state == HIGH && ready) begin
					case (alu_out[1 : 0])
						2'b01 : tmp_rdata[24 +:  8] <= dcache_rdata[0 +:  8];
						2'b10 : tmp_rdata[16 +: 16] <= dcache_rdata[0 +: 16];
						2'b11 : tmp_rdata[8 +:  24] <= dcache_rdata[0 +: 24];
						default : tmp_rdata <= 0;
					endcase
				end
			end else begin
				tmp_rdata <= 0;
			end
		end
	end

	always_comb begin
		if (opcode == OP_STORE) begin
			if (state == LOW) begin
				case (alu_out[1 : 0])
					2'b00 : tmp_wdata[0  +: 32] <= rs2[0 +: 32];
					2'b01 : tmp_wdata[8  +: 24] <= rs2[0 +: 24];
					2'b10 : tmp_wdata[16 +: 16] <= rs2[0 +: 16];
					2'b11 : tmp_wdata[24 +:  8] <= rs2[0 +:  8];
				endcase
			end else if (state == HIGH) begin
				case (alu_out[1 : 0])
					2'b01 : tmp_wdata[0 +:  8] <= rs2[24 +: 8];
					2'b10 : tmp_wdata[0 +: 16] <= rs2[16 +: 16];
					2'b11 : tmp_wdata[0 +: 24] <= rs2[8  +: 24];
					default : tmp_wdata <= 0;
				endcase
			end
		end else begin
			tmp_wdata <= 0;
		end
	end

	always_comb begin
		if (opcode == OP_STORE) begin
			if (state == LOW) begin
				case (alu_out[1 : 0])
					2'b00 : tmp_byte_enable <= 4'b1111;
					2'b01 : tmp_byte_enable <= 4'b1110;
					2'b10 : tmp_byte_enable <= 4'b1100;
					2'b11 : tmp_byte_enable <= 4'b1000;
				endcase
			end else if (state == HIGH) begin
				case (alu_out[1 : 0])
					2'b01 : tmp_byte_enable <= 4'b0001;
					2'b10 : tmp_byte_enable <= 4'b0011;
					2'b11 : tmp_byte_enable <= 4'b0111;
					default : tmp_byte_enable <= 4'b0000;
				endcase
			end else begin
				tmp_byte_enable <= 4'b0000;
			end
		end else begin
			tmp_byte_enable <= 4'b0000;
		end
	end


	always_comb begin
		case (state)
			IDLE : if (opcode == OP_STORE || opcode == OP_LOAD) next_state = LOW;
			LOW  : begin
				if (ready) begin
					next_state = (alu_out[1 : 0] == 2'b00) ? DONE : HIGH;
				end else if (opcode != OP_STORE && opcode != OP_LOAD) begin // TODO
					next_state = IDLE;
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
