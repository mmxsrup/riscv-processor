`timescale 1ns / 1ps

module decode
	import type_pkg::*;
	import alu_op_pkg::*;
	import src_a_mux_pkg::*;
	import src_b_mux_pkg::*;
	import pc_mux_pkg::*;
	import csr_addr_pkg::*;
(
	// from fetch
	input data_t code,
	input addr_t pc,
	// from regfile
	input data_t rs1_data,
	// from csr
	input data_t csr_rdata,

	// to alu etc..
	output reg_addr_t rs1_num,
	output reg_addr_t rs2_num,
	output reg_addr_t rd_num,
	output data_t imm,

	// to alu
	output alu_op_t alu_op_sel,
	// to src_a_mux
	output sel_src_a_t src_a_sel,
	// to src_b_mux
	output sel_src_b_t src_b_sel,
	// to fetch
	output sel_pc_t pc_sel,
	// to write back
	output logic wb_reg, // write back to reg

	// to csr
	output csr_addr_t csr_addr,
	output data_t csr_wdata,
	output logic csr_wb, // write back to csr

	output logic flash
);
	
	parameter TYPE_WIDTH = 3;
	parameter TYPE_NONE = 3'b000;
	parameter TYPE_R = 3'b001;
	parameter TYPE_I = 3'b010;
	parameter TYPE_S = 3'b011;
	parameter TYPE_B = 3'b100;
	parameter TYPE_U = 3'b101;
	parameter TYPE_J = 3'b110;


	logic [TYPE_WIDTH - 1 : 0] op_type;
	opcode_t opcode;
	func3_t func3;
	func7_t func7;

	assign opcode = code[6 : 0];
	assign func3 = code[14 : 12];
	assign func7 = code[31 : 25];


	// generate ir type
	always_comb begin
		case (code[6 : 5])
			2'b00 : begin
				if (code[4 : 2] == 3'b000 || code[4 : 2] == 3'b100 || code[4 : 2] == 3'b011) op_type = TYPE_I;
				else if (code[4 : 2] == 3'b101) op_type = TYPE_U;
				else op_type = TYPE_NONE;
			end
			2'b01: begin
				if (code[4 : 2] == 3'b100) op_type = TYPE_R;
				else if (code[4 : 2] == 3'b000) op_type = TYPE_S;
				else if (code[4 : 2] == 3'b101) op_type = TYPE_U;
				else op_type = TYPE_NONE;
			end
			2'b11: begin
				if (code[4 : 0] == 5'b10011 || code[4 : 0] == 5'b00111) op_type = TYPE_I;
				else if (code[4 : 0] == 5'b00011) op_type = TYPE_B;
				else if (code[4 : 0] == 5'b01111) op_type = TYPE_J;
				else op_type = TYPE_NONE;
			end
			default: op_type = TYPE_NONE;
		endcase
	end


	// generate imm value
	always_comb begin
		case (op_type)
			TYPE_I : imm = { {21{code[31]}}, code[30 : 20] };
			TYPE_S : imm = { {21{code[31]}}, code[30 : 25], code[11 : 7] };
			TYPE_B : imm = { {20{code[31]}}, code[7], code[30 : 25], code[11 : 8], 1'b0 };
			TYPE_U : imm = { code[31 : 12], 12'b0 };
			TYPE_J : imm = { {12{code[31]}}, code[19 : 12], code[20], code[30 : 21], 1'b0 };
			default : imm = 32'b0;
		endcase
	end


	// generate source and dest regisiter number
	assign rs1_num = (op_type == TYPE_U || op_type == TYPE_J) ? 5'b0 : code[19 : 15];
	assign rs2_num = (op_type == TYPE_I || op_type == TYPE_U || op_type == TYPE_J) ? 5'b0 : code[24 : 20];
	assign rd_num  = (op_type == TYPE_S || op_type == TYPE_B) ? 5'b0 : code[11 : 7];
	

	// generate alu_op_sel
	always_comb begin
		case (opcode)
			7'b0010011, 7'b0110011 : begin // OP, OP-IMM
				case (func3)
					3'b000 : begin
						if (code[31 : 25] == 7'b0100000 && opcode == 7'b0110011) alu_op_sel = ALU_OP_SUB;
						else alu_op_sel = ALU_OP_ADD;
					end
					3'b010 : alu_op_sel = ALU_OP_SLT;
					3'b011 : alu_op_sel = ALU_OP_SLTU;
					3'b100 : alu_op_sel = ALU_OP_XOR;
					3'b110 : alu_op_sel = ALU_OP_OR;
					3'b111 : alu_op_sel = ALU_OP_AND;
					3'b001 : alu_op_sel = ALU_OP_SLL;
					3'b101 : begin
						case (func7)
							7'b0000000 : alu_op_sel = ALU_OP_SRL;
							7'b0100000 : alu_op_sel = ALU_OP_SRA;
							default : alu_op_sel = ALU_OP_NONE;
						endcase // func7
					end
				endcase // func3
			end
			7'b1100011 : begin // BRANCH
				case (func3)
					3'b000 : alu_op_sel = ALU_OP_SEQ;
					3'b001 : alu_op_sel = ALU_OP_SNE;
					3'b100 : alu_op_sel = ALU_OP_SLT;
					3'b101 : alu_op_sel = ALU_OP_SGE;
					3'b110 : alu_op_sel = ALU_OP_SLTU;
					3'b111 : alu_op_sel = ALU_OP_SGEU;
					default : alu_op_sel = ALU_OP_NONE;
				endcase // func3
			end
			7'b0100011, 7'b0000011 : begin // STORE, LOAD
				alu_op_sel = ALU_OP_ADD;
			end
			7'b0110111, 7'b0010111, 7'b1101111, 7'b1100111 : begin // LUI, AUIPC, JAL, JALR
				alu_op_sel = ALU_OP_ADD;
			end
			default : alu_op_sel = ALU_OP_NONE;
		endcase // opcode
	end


	// generate src_a_sel
	always_comb begin
		case (op_type)
			TYPE_I, TYPE_R, TYPE_S : begin
				if (opcode == 7'b1100111) src_a_sel = SEL_SRC_A_PC; // JALR
				else src_a_sel = SEL_SRC_A_RS1;
			end
			TYPE_B : src_a_sel = SEL_SRC_A_RS1;
			TYPE_U : begin
				case (opcode)
					7'b0110111 : src_a_sel = SEL_SRC_A_IMM; // LUI
					7'b0010111 : src_a_sel = SEL_SRC_A_PC; // AUIPC
					default  : src_a_sel = SEL_SRC_A_NONE;
				endcase
			end
			TYPE_J : src_a_sel = SEL_SRC_A_PC;
			default : src_a_sel = SEL_SRC_A_NONE;
		endcase // type
	end // always @(*)


	// generate src_b_sel
	always_comb begin
		case (op_type)
			TYPE_I : begin
				if (opcode == 7'b1100111) src_b_sel = SEL_SRC_B_4; // JALR
				else src_b_sel = SEL_SRC_B_IMM;
			end
			TYPE_S : src_b_sel = SEL_SRC_B_IMM;
			TYPE_R, TYPE_B : src_b_sel = SEL_SRC_B_RS2;
			TYPE_U : begin
				case (opcode)
					7'b0110111 : src_b_sel = SEL_SRC_B_0; // LUI
					7'b0010111 : src_b_sel = SEL_SRC_B_IMM; // AUIPC
					default  : src_b_sel = SEL_SRC_B_NONE;
				endcase
			end
			TYPE_J : src_b_sel = SEL_SRC_B_4;
			default : src_b_sel = SEL_SRC_B_NONE;
		endcase // type
	end // always @(*)


	// generate pc_sel
	always_comb begin
		case (opcode)
			7'b1101111 : pc_sel = SEL_PC_JAL;
			7'b1100111 : pc_sel = SEL_PC_JALR;
			7'b1110011 : begin // System
				if (code[14 : 7] == 8'h0) begin
					if (code[31 : 20] == 12'h0) pc_sel = SEL_PC_MTVEC;
					else if (code[31 : 25] == 7'b0011000) pc_sel = SEL_PC_MEPC;
				end else begin
					pc_sel = SEL_PC_ADD4;
				end
			end
			default  : pc_sel = SEL_PC_ADD4;
		endcase // opcode
	end // always @(*)


	// generate write back signal
	assign wb_reg = (op_type == TYPE_I || op_type == TYPE_R || op_type == TYPE_U || op_type == TYPE_J) ? 1 : 0;


	wire [31 : 0] zimm;
	assign zimm = {27'b0, code[19 : 15]};

	// generate csr_wdata
	always_comb begin
		if (opcode == 7'b1110011) begin
			if (code[31 : 20] == 12'h0) begin // ECALL
				csr_wdata = 32'd11;
			end else begin
				case (func3)
					// csrrw rd,csr,rs1 t=CSRs[csr]; CSRs[csr]=x[rs1]; x[rd]=t
					3'b001 : csr_wdata = rs1_data;
					// csrrs rd,csr,rs1 t=CSRs[csr]; CSRs[csr]=t|x[rs1]; x[rd]=t
					3'b010 : csr_wdata = csr_rdata | rs1_data;
					// csrrc rd,csr,rs1 t=CSRs[csr]; CSRs[csr]=t&~x[rs1]; x[rd]=t
					3'b011 : csr_wdata = csr_rdata & ~rs1_data;
					// csrrwi rd,csr,zimm[4:0] x[rd]=CSRs[csr]; CSRs[csr]=zimm
					3'b101 : csr_wdata = zimm;
					// csrrsi rd,csr,rs1 t=CSRs[csr]; CSRs[csr]=t|zimm; x[rd]=t
					3'b110 : csr_wdata = csr_rdata | zimm;
					// csrrci rd,csr,zimm[4:0] t=CSRs[csr]; CSRs[csr]=t&~zimm; x[rd]=t
					3'b111 : csr_wdata = csr_rdata & ~zimm;
					default: csr_wdata = csr_rdata;
				endcase // (func3)
			end
		end else begin
			csr_wdata = 32'h0;
		end
	end

	// generate csr_addr
	always_comb begin
		if (opcode == 7'b1110011) begin
			if (code[31 : 20] == 12'h0) begin // ECALL
				csr_addr = CSR_ADDR_MCAUSE;
			end else begin
				csr_addr = code[31 : 20];
			end
		end else begin
			csr_addr = CSR_ADDR_NONE;
		end
	end

	// generate csr_wb
	always_comb begin
		if (opcode == 7'b1110011) begin
			case (func3)
				3'b001 : csr_wb = 1; // CSRRW
				3'b101 : csr_wb = 1; // CSRRWI
				3'b000 : begin
					if (code[31 : 20] == 12'h0) csr_wb = 1; // ECALL
					else csr_wb = 0;
				end
				default : csr_wb = 0;
			endcase // (func3)
		end else begin
			csr_wb = 0;
		end
	end

	assign flash = (func3 == 3'b001 && opcode == 7'b0001111) ? 1 : 0; // fence.i

endmodule // decode
