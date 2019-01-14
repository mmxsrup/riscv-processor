package pc_mux_pkg;

	localparam SEL_PC_WIDTH = 3;

	localparam SEL_PC_NONE = 3'h0;
	localparam SEL_PC_ADD4 = 3'h1;
	localparam SEL_PC_JAL = 3'h2;
	localparam SEL_PC_JALR = 3'h3;
	localparam SEL_PC_MTVEC = 3'h4;
	localparam SEL_PC_MEPC = 3'h5;

endpackage
