module counts (
    input wire clk,
    input wire clk_en,

    output reg [9:0] x = 0,
    output reg [9:0] y = 0,

    output wire hsync,
    output wire vsync,
    output wire hblank,
    output wire vblank,

    output wire de
);
  localparam DISPLAY_WIDTH = 10'd256;
  // Account for overscanned boarders
  localparam WIDTH = DISPLAY_WIDTH + 10'd26;
  localparam HEIGHT = 10'd240;

  localparam VBLANK_LEN = 10'd21;
  localparam HBLANK_LEN = 10'd59;

  ////////////////////////////////////////////////////////////////////////////////////////
  // Generated

  localparam MAX_X = WIDTH + HBLANK_LEN;
  localparam MAX_Y = HEIGHT + VBLANK_LEN;

  assign de = x < WIDTH && y < HEIGHT;

  assign vblank = y >= HEIGHT;
  assign hblank = x >= WIDTH;

  assign hsync = x >= WIDTH && x < WIDTH + 10'd25;

  assign vsync = y == HEIGHT + 10'h5 && x < DISPLAY_WIDTH + 10'd62;

  // Block is named so we can use a temp variable
  always @(posedge clk) begin : counts
    reg [9:0] next_x;
    reg [9:0] next_y;

    if (clk_en) begin
      next_x = x + 10'b1;
      next_y = y;

      if (next_x == MAX_X) begin
        next_x = 10'h0;
        next_y = y + 10'b1;

        if (next_y == MAX_Y) begin
          next_y = 10'h0;
        end
      end

      x <= next_x;
      y <= next_y;
    end
  end

endmodule
