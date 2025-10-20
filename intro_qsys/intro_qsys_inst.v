	intro_qsys u0 (
		.altpll_0_c2_clk                 (<connected-to-altpll_0_c2_clk>),                 //            altpll_0_c2.clk
		.clk_clk                         (<connected-to-clk_clk>),                         //                    clk.clk
		.gpio_0_conduit_end_export       (<connected-to-gpio_0_conduit_end_export>),       //     gpio_0_conduit_end.export
		.gpio_lcd_0_conduit_end_export   (<connected-to-gpio_lcd_0_conduit_end_export>),   // gpio_lcd_0_conduit_end.export
		.reset_reset_n                   (<connected-to-reset_reset_n>),                   //                  reset.reset_n
		.sdram_controller_wire_addr      (<connected-to-sdram_controller_wire_addr>),      //  sdram_controller_wire.addr
		.sdram_controller_wire_ba        (<connected-to-sdram_controller_wire_ba>),        //                       .ba
		.sdram_controller_wire_cas_n     (<connected-to-sdram_controller_wire_cas_n>),     //                       .cas_n
		.sdram_controller_wire_cke       (<connected-to-sdram_controller_wire_cke>),       //                       .cke
		.sdram_controller_wire_cs_n      (<connected-to-sdram_controller_wire_cs_n>),      //                       .cs_n
		.sdram_controller_wire_dq        (<connected-to-sdram_controller_wire_dq>),        //                       .dq
		.sdram_controller_wire_dqm       (<connected-to-sdram_controller_wire_dqm>),       //                       .dqm
		.sdram_controller_wire_ras_n     (<connected-to-sdram_controller_wire_ras_n>),     //                       .ras_n
		.sdram_controller_wire_we_n      (<connected-to-sdram_controller_wire_we_n>),      //                       .we_n
		.lcd_dma_0_conduit_end_lcd_cs_n  (<connected-to-lcd_dma_0_conduit_end_lcd_cs_n>),  //  lcd_dma_0_conduit_end.lcd_cs_n
		.lcd_dma_0_conduit_end_lcd_d_c_n (<connected-to-lcd_dma_0_conduit_end_lcd_d_c_n>), //                       .lcd_d_c_n
		.lcd_dma_0_conduit_end_lcd_wr_n  (<connected-to-lcd_dma_0_conduit_end_lcd_wr_n>),  //                       .lcd_wr_n
		.lcd_dma_0_conduit_end_lcd_data  (<connected-to-lcd_dma_0_conduit_end_lcd_data>)   //                       .lcd_data
	);

