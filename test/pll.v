module pll (
    input  wire refclk,
    output wire outclk,
    output reg  pll_lock = 0
);

  assign outclk = refclk;

  always @(posedge refclk) begin
    pll_lock <= 1;
  end

endmodule
