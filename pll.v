module pll (
    input  wire refclk,
    output wire outclk,
    output wire pll_lock
);
  Gowin_rPLL pll0 (
      .clkout (outclk),    // main freq
      .clkfb  (1'b0),
      .clkin  (refclk),
      // .clkoutd_o(outclk),  // freq / SDIV
      .lock_o (pll_lock),
      .fdiv   (6'h0),
      .idiv   (6'd0),
      .reset  (1'b0),
      .reset_p(1'b0)
  );

  // These values were taken from the GOWIN IDE PLL generator
  defparam pll0.DEVICE = `PLL_DEVICE;
  defparam pll0.FCLKIN = `PLL_FCLKIN;
  defparam pll0.FBDIV_SEL = 50;
  defparam pll0.IDIV_SEL = 7;
  defparam pll0.ODIV_SEL = 4;
  defparam pll0.DYN_FBDIV_SEL = "false";
  defparam pll0.DYN_IDIV_SEL = "false";
  defparam pll0.DYN_ODIV_SEL = "false";
  defparam pll0.DYN_SDIV_SEL = 2;
  defparam pll0.PSDA_SEL = "0000";
  defparam pll0.CLKOUT_FT_DIR = 1'b1;
  defparam pll0.CLKOUTP_FT_DIR = 1'b1;
  defparam pll0.CLKOUT_DLY_STEP = 0;
  defparam pll0.CLKOUTP_DLY_STEP = 0;
  defparam pll0.CLKFB_SEL = "internal";
  defparam pll0.CLKOUT_BYPASS = "false";
  defparam pll0.CLKOUTP_BYPASS = "false";
  defparam pll0.CLKOUTD_BYPASS = "false";
  defparam pll0.CLKOUTD_SRC = "CLKOUT";
  defparam pll0.CLKOUTD3_SRC = "CLKOUT";

endmodule
