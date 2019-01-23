module ram
    import axi_pkg::*;
#(
	parameter DATA_WIDTH = 32,
	parameter DATA_SIZE  = 4096,
	parameter START_ADDR = 32'h80000000,
	parameter INIT_FILE  = ""
)(
	input logic clk,
	input logic rst_n,
	axi_if.slave s_axi
);

	typedef enum logic [2 : 0] {IDLE, RADDR, RDATA, WADDR, WDATA, WRESP} state_type;
	state_type state, next_state;

	logic [31 : 0] addr;
	logic [DATA_WIDTH - 1 : 0] rdata;
	len_t len_cnt;
	len_t len;
	burst_t burst;
	size_t size;

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
	assign s_axi.rlast = 1;

	// AW
	assign s_axi.awready = (state == WADDR) ? 1 : 0;

	// W
	assign s_axi.wready = (state == WDATA) ? 1 : 0;

	// B
	assign s_axi.bvalid = (state == WRESP) ? 1 : 0;
	assign s_axi.bresp  = RESP_OKAY;


	always_ff @(posedge clk) begin
		if (~rst_n) begin
			addr  <= 0;
			len   <= 0;
			size  <= 0;
			burst <= 0;
		end else begin
			case (state)
				RADDR : addr <= s_axi.araddr - START_ADDR;
				WADDR : begin
					addr  <= s_axi.awaddr - START_ADDR;
					len   <= s_axi.awlen;
					size  <= s_axi.awsize;
					burst <= s_axi.awburst;
				end
			endcase
		end
	end

	always_ff @(posedge clk) begin
		if(~rst_n) begin
			len_cnt <= 0;
		end else begin
			case (state)
				WADDR : begin
					if (s_axi.wvalid && s_axi.wready) begin
						if (burst == BURST_INCR) addr <= addr + 32'h4;
						len_cnt <= len_cnt + 1;
					end
				end
			endcase
		end
	end
	always_comb begin
		case (state)
			IDLE : next_state = (s_axi.arvalid) ? RADDR : (s_axi.awvalid) ? WADDR : IDLE;
			RADDR : if (s_axi.arvalid && s_axi.arready) next_state = RDATA;
			RDATA : if (s_axi.rvalid  && s_axi.rready && len == len_cnt) next_state = IDLE;
			WADDR : if (s_axi.awvalid && s_axi.awready) next_state = WDATA;
			WDATA : if (s_axi.wvalid  && s_axi.wready && s_axi.wlast) next_state = WRESP;
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
