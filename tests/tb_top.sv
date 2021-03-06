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
	logic icache_flash;

	logic dcache_valid;
	addr_t dcache_addr;
	data_t dcache_wdata;
	byte_en_t dcache_byte_enable;
	logic dcache_ready;
	data_t dcache_rdata;
	logic dcache_flash;

	axi_lite_if axi1();
	axi_if axi2();
	axi_if axi3();

	core core (
		.clk(clk), .rst_n(rst_n),
		.icache_valid(icache_valid), .icache_addr(icache_addr),
		.icache_ready(icache_ready), .icache_rdata(icache_rdata),
		.icache_flash(icache_flash),
		.dcache_valid(dcache_valid), .dcache_addr(dcache_addr),
		.dcache_wdata(dcache_wdata), .dcache_byte_enable(dcache_byte_enable),
		.dcache_ready(dcache_ready), .dcache_rdata(dcache_rdata),
		.dcache_flash(dcache_flash)
	);

	icache icache (
		.clk(clk), .rst_n(rst_n), .flash(1'b0),
		.valid(icache_valid), .addr(icache_addr),
		.ready(icache_ready), .rdata(icache_rdata),
		.m_axi(axi1)
	);

	dcache dcache (
		.clk(clk), .rst_n(rst_n), .flash(1'b0),
		.valid(dcache_valid), .addr(dcache_addr), .wdata(dcache_wdata), .byte_enable(dcache_byte_enable),
		.ready(dcache_ready), .rdata(dcache_rdata),
		.m_axi(axi2)
	);

	interconnect_bus interconnect_bus (
		.clk(clk), .rst_n(rst_n),
		.icache(axi1), .dcache(axi2), .ram(axi3)
	);
	
	ram #(.INIT_FILE("data.mem")) ram (
		.clk(clk), .rst_n(rst_n),
		.s_axi(axi3)
	);

	always begin
		clk = 1; #(STEP / 2);
		clk = 0; #(STEP / 2);
	end

    int fd;
    logic [31 : 0] ret;
	initial begin
		rst_n = 1;
		#(STEP * 10) rst_n = 0;
		#(STEP * 10) rst_n = 1;

		#(STEP * 3000);

		ret = dcache.cachemem.mem[1024];
		fd = $fopen("./testlog.txt", "a+");
		if (ret == 32'h1) begin
			$display("Sucess");
			$fwrite(fd, "Sucess\n");
		end else begin
			$display("Error %h", ret);
			$fwrite(fd, "Error %h\n", ret);
		end
		
		#(STEP * 10)

		$finish;
	end
	
endmodule

