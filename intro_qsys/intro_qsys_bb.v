
module intro_qsys (
	altpll_0_c2_clk,
	clk_clk,
	gpio_0_conduit_end_export,
	gpio_lcd_0_conduit_end_export,
	reset_reset_n,
	sdram_controller_wire_addr,
	sdram_controller_wire_ba,
	sdram_controller_wire_cas_n,
	sdram_controller_wire_cke,
	sdram_controller_wire_cs_n,
	sdram_controller_wire_dq,
	sdram_controller_wire_dqm,
	sdram_controller_wire_ras_n,
	sdram_controller_wire_we_n,
	lcd_0_conduit_end_d_c_n,
	lcd_0_conduit_end_write_n,
	lcd_0_conduit_end_databus);	

	output		altpll_0_c2_clk;
	input		clk_clk;
	inout	[31:0]	gpio_0_conduit_end_export;
	inout	[7:0]	gpio_lcd_0_conduit_end_export;
	input		reset_reset_n;
	output	[11:0]	sdram_controller_wire_addr;
	output	[1:0]	sdram_controller_wire_ba;
	output		sdram_controller_wire_cas_n;
	output		sdram_controller_wire_cke;
	output		sdram_controller_wire_cs_n;
	inout	[15:0]	sdram_controller_wire_dq;
	output	[1:0]	sdram_controller_wire_dqm;
	output		sdram_controller_wire_ras_n;
	output		sdram_controller_wire_we_n;
	output		lcd_0_conduit_end_d_c_n;
	output		lcd_0_conduit_end_write_n;
	output	[15:0]	lcd_0_conduit_end_databus;
endmodule
