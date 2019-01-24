module arbiter (
	input clk,
	input rst_n,
	axi_lite_if.slave in1, // from icache
	axi_if.slave in2, // from dcache
	axi_if.master out // to ram
);

	typedef enum logic [2 : 0] {IDLE, READ1, READ2, WRITE1, WRITE2} state_type;
	state_type state, next_state;
	logic [1 : 0] sel;

	assign out.araddr  = (sel == 1) ? in1.araddr  : (sel == 2) ? in2.araddr  : 0;
	assign out.arvalid = (sel == 1) ? in1.arvalid : (sel == 2) ? in2.arvalid : 0;
	assign out.arlen  = (sel == 2) ? in2.arlen : 0;
	assign out.arsize = (sel == 2) ? in2.arsize : 0;
	assign out.arburst = (sel == 2) ? in2.arburst : 0;
	assign out.rready  = (sel == 1) ? in1.rready  : (sel == 2) ? in2.rready  : 0;
	assign out.awaddr  = (sel == 1) ? in1.awaddr  : (sel == 2) ? in2.awaddr  : 0;
	assign out.awvalid = (sel == 1) ? in1.awvalid : (sel == 2) ? in2.awvalid : 0;
	assign out.awlen  = (sel == 2) ? in2.awlen : 0;
	assign out.awsize = (sel == 2) ? in2.awsize : 0;
	assign out.awburst = (sel == 2) ? in2.awburst : 0;
	assign out.wdata   = (sel == 1) ? in1.wdata   : (sel == 2) ? in2.wdata   : 0;
	assign out.wstrb   = (sel == 1) ? in1.wstrb   : (sel == 2) ? in2.wstrb   : 0;
	assign out.wvalid  = (sel == 1) ? in1.wvalid  : (sel == 2) ? in2.wvalid  : 0;
	assign out.wlast = (sel == 2) ? in2.wlast : 1;
	assign out.bready  = (sel == 1) ? in1.bready  : (sel == 2) ? in2.bready  : 0;

	assign in1.arready = (sel == 1) ? out.arready : 0;
	assign in2.arready = (sel == 2) ? out.arready : 0;
	assign in1.rdata   = (sel == 1) ? out.rdata   : 0;
	assign in2.rdata   = (sel == 2) ? out.rdata   : 0;
	assign in1.rresp   = (sel == 1) ? out.rresp   : 0;
	assign in2.rresp   = (sel == 2) ? out.rresp   : 0;
	assign in1.rvalid  = (sel == 1) ? out.rvalid  : 0;
	assign in2.rvalid  = (sel == 2) ? out.rvalid  : 0;
	assign in1.awready = (sel == 1) ? out.awready : 0;
	assign in2.awready = (sel == 2) ? out.awready : 0;
	assign in1.wready  = (sel == 1) ? out.wready  : 0;
	assign in2.wready  = (sel == 2) ? out.wready  : 0;
	assign in1.bresp   = (sel == 1) ? out.bresp   : 0;
	assign in2.bresp   = (sel == 2) ? out.bresp   : 0;
	assign in1.bvalid  = (sel == 1) ? out.bvalid  : 0;
	assign in2.bvalid  = (sel == 2) ? out.bvalid  : 0;


	always_comb begin
		if (state == IDLE) begin
			if (in1.arvalid || in1.awvalid) sel = 1;
			else if (in2.arvalid || in2.awvalid) sel = 2;
			else sel = 0;
		end
	end

	always_comb begin
		case (state)
			IDLE    :  next_state = (in1.arvalid) ? READ1 : (in2.arvalid) ? READ2 : (in1.awvalid) ? WRITE1 : (in2.awvalid) ? WRITE2 : IDLE;
			READ1   : next_state = (in1.rvalid && in1.rready) ? IDLE : READ1;
			READ2   : next_state = (in2.rvalid && in2.rready) ? IDLE : READ2;
			WRITE1  : next_state = (in1.bvalid && in1.bready) ? IDLE : WRITE1;
			WRITE2  : next_state = (in2.bvalid && in2.bready) ? IDLE : WRITE2;
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

endmodule
