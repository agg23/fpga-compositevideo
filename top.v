module top (
    input wire refclk,

    input wire button_a_n,
    input wire button_b_n,

    output wire [5:0] led,

    output reg output_450ohm = 0,
    output reg output_900ohm = 0
);

  wire clk;

  localparam CLK_SPEED = 85_500_000;

  ////////////////////////////////////////////////////////////////////////////////////////
  // Button Control

  reg render = 1;

  reg prev_button_b_n = 0;

  always @(posedge clk) begin
    prev_button_b_n <= button_b_n;

    if (~button_b_n && prev_button_b_n) begin
      render = ~render;
    end
  end

  ////////////////////////////////////////////////////////////////////////////////////////
  // Clock Divider

  reg [3:0] divider = 0;

  wire clk_en = divider == 4'h0;

  always @(posedge clk) begin
    divider <= divider + 4'h1;
  end

  ////////////////////////////////////////////////////////////////////////////////////////
  // Video Generation

  wire [3:0] pixel;

  wire hsync;
  wire vsync;
  wire hblank;
  wire vblank;

  wire [9:0] x;
  wire [9:0] y;

  counts counts (
      .clk(clk),
      .clk_en(clk_en),

      .x(x),
      .y(y),

      .hsync (hsync),
      .vsync (vsync),
      .hblank(hblank),
      .vblank(vblank)
  );

  always @(posedge clk) begin
    output_450ohm <= 0;
    output_900ohm <= 0;

    if (render) begin
      if (pixel > 4'd10) begin
        // Brightest
        output_450ohm <= 1;
        output_900ohm <= 1;
      end else if (pixel > 4'd5) begin
        // Middle
        output_450ohm <= 1;
        output_900ohm <= 0;
      end else begin
        // Darkest
        output_450ohm <= 0;
        output_900ohm <= 1;
      end

      if (vblank || hblank) begin
        // Default to black
        output_450ohm <= 0;
        output_900ohm <= 1;

        if (vsync || hsync) begin
          // Sync level
          output_450ohm <= 0;
          output_900ohm <= 0;
        end
      end
    end
  end

  ////////////////////////////////////////////////////////////////////////////////////////
  // RGB Data

  wire [15:0] address = y * 16'd256 + x;

  Gowin_SP ram (
      .clk(clk),
      .ce (1'b1),  // Clock enable
      .oce(1'b1),  // Output clock enable

      .ad  (address),
      .dout(pixel)
  );

  ////////////////////////////////////////////////////////////////////////////////////////
  // PLL

  Gowin_rPLL pll (
      .clkin (refclk),
      .clkout(clk)
      // .clkoutp(clk_mem_90deg)
  );

endmodule
