`timescale 1ns / 1ps

module alu
	import type_pkg::*;
	import alu_op_pkg::*;
(
	input alu_op_t operator,
	input data_t operand1,
	input data_t operand2,

	output data_t out
);
	
	localparam SHAMT_WIDTH = 5;

	wire [SHAMT_WIDTH - 1 : 0] shamt;

	assign shamt = operand2[SHAMT_WIDTH - 1 : 0];

	always_comb begin
		case (operator)
			ALU_OP_ADD  :  out = operand1 + operand2;
			ALU_OP_SUB  :  out = operand1 - operand2;
			ALU_OP_AND  :  out = operand1 & operand2;
			ALU_OP_OR   :  out = operand1 | operand2;
			ALU_OP_XOR  :  out = operand1 ^ operand2;
			ALU_OP_SLL  :  out = operand1 << shamt;
			ALU_OP_SRA  :  out = $signed(operand1) >>> shamt;
			ALU_OP_SRL  :  out = operand1 >> shamt;
			ALU_OP_SLT  :  out = ($signed(operand1) < $signed(operand2)) ? 32'b1 : 32'b0;
			ALU_OP_SLTU :  out = (operand1 < operand2) ? 32'b1 : 32'b0;
			ALU_OP_SEQ  :  out = (operand1 == operand2) ? 32'b1 : 32'b0;
			ALU_OP_SNE  :  out = (operand1 != operand2) ? 32'b1 : 32'b0;
			ALU_OP_SGE  :  out = ($signed(operand1) >= $signed(operand2)) ? 32'b1 : 32'b0;
			ALU_OP_SGEU :  out = (operand1 >= operand2) ? 32'b1 : 32'b0;
			default: out = 0;
		endcase 
	end


endmodule // alu
