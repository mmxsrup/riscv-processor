package alu_op_pkg;

	localparam ALU_OP_WIDTH = 4;

	localparam ALU_OP_ADD  = 4'h0;
	localparam ALU_OP_SUB  = 4'h1;
	localparam ALU_OP_AND  = 4'h2;
	localparam ALU_OP_OR   = 4'h3;
	localparam ALU_OP_XOR  = 4'h4;
	localparam ALU_OP_SLL  = 4'h5;
	localparam ALU_OP_SRA  = 4'h6;
	localparam ALU_OP_SRL  = 4'h7;
	localparam ALU_OP_SLT  = 4'h8;
	localparam ALU_OP_SLTU =4'h9;
	localparam ALU_OP_SEQ  = 4'hA;
	localparam ALU_OP_SNE  = 4'hB;
	localparam ALU_OP_SGE  = 4'hC;
	localparam ALU_OP_SGEU = 4'hD;
	localparam ALU_OP_NONE = 4'hE;

endpackage
