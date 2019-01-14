package csr_addr_pkg;

	localparam CSR_ADDR_WIDTH = 12;
	
	localparam CSR_ADDR_MTVEC  = 12'h305;
	localparam CSR_ADDR_MEPC   = 12'h341;
	localparam CSR_ADDR_MCAUSE = 12'h342;
	localparam CSR_ADDR_NONE   = 12'hfff;

endpackage