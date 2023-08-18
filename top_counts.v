module top (
    input wire refclk,

    input wire button_a_n,
    input wire button_b_n,

    output wire [5:0] led,

    output reg test_output = 0,

    output reg output_450ohm = 0,
    output reg output_900ohm = 0,

    output reg [3:0] debug = 0
);

  wire clk;

  // function integer rtoi(input integer x);
  //   return x;
  // endfunction

  // `define CEIL(x) ((rtoi(x) > x) ? rtoi(x) : rtoi(x) + 1)

  // assign led[0] = button_b_n;

  localparam CLK_SPEED = 85_500_000;

  // Lengths are specified in nanoseconds
  localparam HSYNC_LENGTH = 4_700;

  localparam VSYNC_LENGTH = 58_856;

  localparam LINE_LENGTH = VSYNC_LENGTH + HSYNC_LENGTH;

  // localparam PIXEL_COUNT = 256;

  // Generated values
  localparam PERIOD = 1_000_000_000.0 / CLK_SPEED;

  localparam HSYNC_CYCLE_LENGTH = $rtoi($ceil(HSYNC_LENGTH / PERIOD));
  localparam VSYNC_CYCLE_LENGTH = $rtoi($ceil(VSYNC_LENGTH / PERIOD));

  // localparam PIXEL_LENGTH = $rtoi($ceil(LINE_LENGTH / PIXEL_COUNT / PERIOD));
  // localparam PIXEL_LENGTH = 16;

  // localparam STATE_VSYNC = 0;
  // localparam STATE_VSYNC_CLEANUP = 1;
  // localparam STATE_HSYNC = 2;
  // localparam STATE_RENDER = 3;

  // reg [1:0] state = STATE_HSYNC;

  // reg [8:0] scanline = 0;
  // reg [7:0] pixel = 0;
  // reg [5:0] pixel_cycles = 0;

  // reg [24:0] line_duration_counter = 0;

  // reg even_pixel = 0;

  // reg line_even_start = 0;
  // reg [3:0] x_square_pixel = 0;
  // reg [3:0] y_square_pixel = 0;

  // task new_scanline(input reg y_even_start);
  //   begin
  //     if (scanline == 9'd247) begin
  //       // VSync
  //       state <= STATE_VSYNC;

  //       x_square_pixel <= 0;
  //       y_square_pixel <= 0;
  //     end else begin
  //       state <= STATE_HSYNC;
  //     end

  //     line_duration_counter <= 0;
  //     pixel <= 0;
  //     even_pixel <= y_even_start;
  //     line_even_start <= y_even_start;

  //     if (scanline == 9'd261) begin
  //       scanline <= 0;
  //     end else begin
  //       scanline <= scanline + 9'h1;
  //     end
  //   end
  // endtask

  reg render = 1;

  reg prev_button_b_n = 0;

  always @(posedge clk) begin
    prev_button_b_n <= button_b_n;

    if (~button_b_n && prev_button_b_n) begin
      render = ~render;
    end
  end

  // Divider

  reg [3:0] divider = 0;

  wire clk_en = divider == 4'h0;

  always @(posedge clk) begin
    divider <= divider + 4'h1;
  end

  wire hsync;
  wire vsync;
  wire hblank;
  wire vblank;
  wire vsync_black;

  wire [9:0] x;

  counts counts (
      .clk(clk),
      .clk_en(clk_en),

      .x(x),
      .y(y),

      .hsync (hsync),
      .vsync (vsync),
      .hblank(hblank),
      .vblank(vblank)
      // .vsync_black(vsync_black),
  );

  wire [9:0] divided = x / 10;

  always @(posedge clk) begin
    output_450ohm <= 0;
    output_900ohm <= 0;

    if (render) begin
      output_450ohm <= divided[0];
      output_900ohm <= 1;

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

    // if (x > 10'd200) begin
    //   output_450ohm <= 1;
    //   output_900ohm <= 1;
    // end

    // debug <= {3'b0, clk_en};
    // debug <= x[3:0];
  end

  // Block is named so we can use a temp variable
  // always @(posedge clk) begin : main
  //   reg next_even;

  //   line_duration_counter <= line_duration_counter + 25'h1;

  //   case (state)
  //     STATE_VSYNC: begin
  //       output_450ohm <= 0;
  //       output_900ohm <= 0;

  //       if (line_duration_counter == VSYNC_CYCLE_LENGTH[24:0]) begin
  //         // Enter render
  //         state <= STATE_VSYNC_CLEANUP;

  //         line_duration_counter <= 0;
  //       end
  //     end
  //     STATE_VSYNC_CLEANUP: begin
  //       output_450ohm <= 0;
  //       output_900ohm <= 1;

  //       if (line_duration_counter == HSYNC_CYCLE_LENGTH[24:0]) begin
  //         // Start new line
  //         new_scanline(line_even_start);
  //       end
  //     end
  //     STATE_HSYNC: begin
  //       output_450ohm <= 0;
  //       output_900ohm <= 0;

  //       if (line_duration_counter == HSYNC_CYCLE_LENGTH[24:0]) begin
  //         // Enter render
  //         state <= STATE_RENDER;

  //         x_square_pixel <= 4'h0;

  //         pixel_cycles <= 6'h0;
  //         pixel <= 8'h0;

  //         line_duration_counter <= 0;
  //       end
  //     end
  //     STATE_RENDER: begin
  //       output_450ohm <= even_pixel;
  //       output_900ohm <= 1;

  //       pixel_cycles  <= pixel_cycles + 6'h1;

  //       if (line_duration_counter == VSYNC_CYCLE_LENGTH[24:0]) begin
  //         // Start new line
  //         next_even = line_even_start;

  //         y_square_pixel <= y_square_pixel + 4'h1;

  //         if (y_square_pixel == 4'hF) begin
  //           y_square_pixel <= 4'h0;

  //           next_even = ~line_even_start;
  //         end

  //         new_scanline(next_even);
  //       end else if (pixel_cycles == PIXEL_LENGTH[5:0] - 6'h1) begin
  //         pixel_cycles <= 0;

  //         pixel <= pixel + 8'h1;

  //         x_square_pixel <= x_square_pixel + 4'h1;

  //         if (x_square_pixel == 4'hF) begin
  //           x_square_pixel <= 4'h0;

  //           even_pixel <= ~even_pixel;
  //         end
  //       end

  //       // if (scanline[0] && line_duration_counter == 24'h1) begin
  //       //   output_450ohm <= 1;
  //       // end else if (~scanline[0] && line_duration_counter == 24'h1) begin
  //       //   output_450ohm <= 0;
  //       // end else begin
  //       //   if (pixel_cycles == 4'h6) begin
  //       //     output_450ohm <= ~output_450ohm;

  //       //     pixel_cycles  <= 4'h0;
  //       //   end else begin
  //       //     pixel_cycles <= pixel_cycles + 4'h1;
  //       //   end
  //       // end

  //       // if (line_duration_counter == VSYNC_CYCLE_LENGTH[24:0]) begin
  //       //   // Enter render
  //       //   new_scanline();
  //       // end

  //       // pixel_cycles  <= pixel_cycles + 4'h1;

  //       // if (pixel_cycles == PIXEL_LENGTH[3:0]) begin
  //       //   pixel_cycles <= 0;

  //       //   pixel <= pixel + 8'h1;

  //       //   if (pixel == 8'hFF) begin
  //       //     // Start new line
  //       //     new_scanline();
  //       //   end
  //       // end
  //     end
  //   endcase
  // end

  reg [24:0] counter = 0;

  // always @(posedge clk) begin
  //   if (counter > 0) begin
  //     counter <= counter - 25'h1;
  //   end else begin
  //     // counter <= CLK_SPEED;
  //     counter <= 25'd1000;

  //     test_output <= ~test_output;
  //   end
  // end

  // initial begin
  //   $display("PERIOD: %d", $rtoi(PERIOD));

  //   $display("HSYNC_CYCLE_LENGTH: %d", HSYNC_CYCLE_LENGTH);
  //   $display("VSYNC_CYCLE_LENGTH: %d", VSYNC_CYCLE_LENGTH);

  //   $display("PIXEL_LENGTH: %d", PIXEL_LENGTH);
  // end

  ////////////////////////////////////////////////////////////////////////////////////////
  // PLL

  pll pll (
      .refclk(refclk),
      .outclk(clk)
      // .pll_lock(pll_lock)
  );

endmodule
