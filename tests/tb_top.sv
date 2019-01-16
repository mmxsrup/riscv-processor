`timescale 1ns / 1ps


module tb_top;
	import type_pkg::*;
	import pc_mux_pkg::*;

	localparam STEP = 10;
	
	logic clk;
	logic rst_n;

	logic icache_valid;
	addr_t icache_addr;
	logic icache_ready;
	data_t icache_rdata;

	logic dcache_valid;
	addr_t dcache_addr;
	data_t dcache_wdata;
	byte_en_t dcache_byte_enable;
	logic dcache_ready;
	data_t dcache_rdata;

	axi_lite_if m_axi0();
	axi_lite_if m_axi1();

	core core (
		.clk(clk), .rst_n(rst_n),
		.icache_valid(icache_valid), .icache_addr(icache_addr),
		.icache_ready(icache_ready), .icache_rdata(icache_rdata),
		.dcache_valid(dcache_valid), .dcache_addr(dcache_addr),
		.dcache_wdata(dcache_wdata), .dcache_byte_enable(dcache_byte_enable),
		.dcache_ready(dcache_ready), .dcache_rdata(dcache_rdata)
	);

	icache #(.INIT_FILE("data.mem")) icache (
		.clk(clk), .rst_n(rst_n),
		.valid(icache_valid), .addr(icache_addr),
		.ready(icache_ready), .rdata(icache_rdata),
		.m_axi(m_axi0)
	);

	dcache #(.INIT_FILE("data.mem")) dcahe (
		.clk(clk), .rst_n(rst_n),
		.valid(dcache_valid), .addr(dcache_addr), .wdata(dcache_wdata), .byte_enable(dcache_byte_enable),
		.ready(dcache_ready), .rdata(dcache_rdata),
		.m_axi(m_axi1)
	);

	always begin
		clk = 1; #(STEP / 2);
		clk = 0; #(STEP / 2);
	end

	initial begin
		rst_n = 1;
		#(STEP * 10) rst_n = 0;
		#(STEP * 10) rst_n = 1;

		#(STEP * 2000);

		$finish;
	end
	
endmodule

