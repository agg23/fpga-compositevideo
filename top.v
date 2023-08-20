module top (
    input wire refclk,

    input wire button_a_n,
    input wire button_b_n,

    output wire [5:0] led,

    output reg output_270ohm = 0,
    output reg output_330ohm = 0,
    output reg output_470ohm = 0
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
    output_270ohm <= 0;
    output_330ohm <= 0;
    output_470ohm <= 0;

    if (render) begin
      if (pixel >= 4'd12) begin
        // Brightest, 1
        output_270ohm <= 1;
        output_330ohm <= 1;
      end else if (pixel >= 4'd9) begin
        // 0.87
        output_270ohm <= 1;
        output_470ohm <= 1;
      end else if (pixel >= 4'd6) begin
        // 0.76
        output_330ohm <= 1;
        output_470ohm <= 1;
      end else if (pixel >= 4'd4) begin
        // 0.55
        output_270ohm <= 1;
      end else if (pixel >= 4'd2) begin
        // 0.45
        output_330ohm <= 1;
      end else begin
        // Darkest, 0.32
        output_470ohm <= 1;
      end

      if (vblank || hblank) begin
        // Default to black
        output_270ohm <= 0;
        output_330ohm <= 0;
        output_470ohm <= 1;

        if (vsync || hsync) begin
          // Sync level
          output_470ohm <= 0;
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
