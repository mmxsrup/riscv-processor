`timescale 1ns / 1ps

import type_pkg::*;


module tb_top;

	localparam STEP = 10;
	
	logic clk;
	logic rst_n;
	data_t icache_data;
	logic icache_valid;
	data_t icache_addr;
	logic icache_req;
	logic dcache_wvalid;
	data_t dcache_rdata;
	logic dcache_rvalid;
	addr_t dcache_addr;
	logic dcache_wreq;
	logic dcache_rreq;
	data_t dcache_wdata;
	byte_en_t dcache_byte_enable;

	core core (
		.clk(clk), .rst_n(rst_n),
		.icache_data(icache_data), .icache_valid(icache_valid), .icache_addr(icache_addr), .icache_req(icache_req),
		.dcache_wvalid(dcache_wvalid), .dcache_rdata(dcache_rdata), .dcache_rvalid(dcache_rvalid),
		.dcache_addr(dcache_addr), .dcache_wreq(dcache_wreq), .dcache_rreq(dcache_rreq), .dcache_wdata(dcache_wdata),
		.dcache_byte_enable(dcache_byte_enable)
	);


	cache cache (
		.clk(clk), .rst_n(rst_n),
		.icache_data(icache_data), .icache_valid(icache_valid), .icache_addr(icache_addr), .icache_req(icache_req),
		.dcache_wvalid(dcache_wvalid), .dcache_rdata(dcache_rdata), .dcache_rvalid(dcache_rvalid),
		.dcache_addr(dcache_addr), .dcache_wreq(dcache_wreq), .dcache_rreq(dcache_rreq), .dcache_wdata(dcache_wdata),
		.dcache_byte_enable(dcache_byte_enable)
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
