module interconnect_bus (
	input clk,
	input rst_n,
	axi_lite_if.slave icache,
	axi_if.slave dcache,
	axi_if.master ram
);

	arbiter arbiter (
		.clk(clk), .rst_n(rst_n),
		.in1(icache), .in2(dcache),
		.out(ram)
	);

endmodule
