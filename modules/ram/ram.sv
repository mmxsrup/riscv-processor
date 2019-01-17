module ram #(
	parameter DATA_WIDTH = 32,
	parameter DATA_SIZE = 4096,
	parameter INIT_FILE  = ""
)(
	input logic clk,
	input logic rst_n,
	axi_lite_if.slave s_axi
);

	typedef enum logic [2 : 0] {IDLE, RADDR, RDATA, WADDR, WDATA, WRESP} state_type;
	state_type state, next_state;

	logic [31 : 0] addr;
	logic [DATA_WIDTH - 1 : 0] rdata;

	blockram #(.INIT_FILE(INIT_FILE)) blockram (
		.clk(clk), .rst_n(rst_n),
		.en((state == RDATA || state == WDATA) ? 1 : 0), .we((state == WDATA) ? s_axi.wstrb : 0),
		.addr(addr[$clog2(DATA_SIZE) - 1 + 2 : 2]), .wdata(s_axi.wdata), .rdata(rdata)
	);

	// AR
	assign s_axi.arready = (state == RADDR) ? 1 : 0;

	// R
	assign s_axi.rdata  = (state == RDATA) ? rdata : 0;
	assign s_axi.rresp  = RESP_OKAY;
	assign s_axi.rvalid = (state == RDATA) ? 1 : 0;

	// AW
	assign s_axi.awready = (state == WADDR) ? 1 : 0;

	// W
	assign s_axi.wready = (state == WDATA) ? 1 : 0;

	// B
	assign s_axi.bvalid = (state == WRESP) ? 1 : 0;
	assign s_axi.bresp  = RESP_OKAY;


	always_ff @(posedge clk) begin
		if (~rst_n) begin
			addr <= 0;
		end else begin
			case (state)
				RADDR : addr <= s_axi.araddr;
				WADDR : addr <= s_axi.awaddr;
			endcase
		end
	end

	always_comb begin
		case (state)
			IDLE : next_state = (s_axi.arvalid) ? RADDR : (s_axi.awvalid) ? WADDR : IDLE;
			RADDR : if (s_axi.arvalid && s_axi.arready) next_state = RDATA;
			RDATA : if (s_axi.rvalid  && s_axi.rready ) next_state = IDLE;
			WADDR : if (s_axi.awvalid && s_axi.awready) next_state = WDATA;
			WDATA : if (s_axi.wvalid  && s_axi.wready ) next_state = WRESP;
			WRESP : if (s_axi.bvalid  && s_axi.bready ) next_state = IDLE;
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
