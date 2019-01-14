package type_pkg;

	import pc_mux_pkg::SEL_PC_WIDTH;
	import src_a_mux_pkg::SEL_SRC_A_WIDTH;
	import src_b_mux_pkg::SEL_SRC_B_WIDTH;
	import alu_op_pkg::ALU_OP_WIDTH;
	import csr_addr_pkg::CSR_ADDR_WIDTH;

	// User Config Parameter
	localparam XLEN = 32;


	typedef logic [XLEN - 1 : 0] addr_t;
	typedef logic [XLEN - 1 : 0] data_t;

	typedef logic [SEL_PC_WIDTH - 1 : 0] sel_pc_t;
	typedef logic [SEL_SRC_A_WIDTH - 1 : 0] sel_src_a_t;
	typedef logic [SEL_SRC_B_WIDTH - 1 : 0] sel_src_b_t;
	typedef logic [ALU_OP_WIDTH - 1 : 0] alu_op_t;
	typedef logic [$clog2(XLEN) - 1 : 0] reg_addr_t;
	typedef logic [CSR_ADDR_WIDTH - 1 : 0] csr_addr_t;

	typedef logic [6 : 0] opcode_t;
	typedef logic [6 : 0] func7_t;
	typedef logic [2 : 0] func3_t;
	typedef logic [XLEN / 4 : 0] byte_en_t;


endpackage
