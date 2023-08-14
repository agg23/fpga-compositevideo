module top (
    input wire clk,

    input wire button_a_n,
    input wire button_b_n,

    output wire [5:0] led,

    output reg test_output,

    output reg output_450ohm,
    output reg output_900ohm
);

  // function integer rtoi(input integer x);
  //   return x;
  // endfunction

  // `define CEIL(x) ((rtoi(x) > x) ? rtoi(x) : rtoi(x) + 1)


  localparam CLK_SPEED = 27_000_000;

  // Lengths are specified in nanoseconds
  localparam HSYNC_LENGTH = 4_700;

  localparam VSYNC_LENGTH = 58_856;

  localparam PIXEL_COUNT = 256;

  // Generated values
  localparam PERIOD = 1_000_000_000.0 / CLK_SPEED;

  localparam HSYNC_CYCLE_LENGTH = $rtoi($ceil(HSYNC_LENGTH / PERIOD));
  localparam VSYNC_CYCLE_LENGTH = $rtoi($ceil(VSYNC_LENGTH / PERIOD));

  localparam PIXEL_LENGTH = $rtoi($ceil(PIXEL_COUNT / PERIOD));

  localparam STATE_VSYNC = 0;
  localparam STATE_VSYNC_CLEANUP = 1;
  localparam STATE_HSYNC = 2;
  localparam STATE_RENDER = 3;

  reg [ 1:0] state = STATE_HSYNC;

  reg [ 8:0] scanline = 0;
  reg [ 7:0] pixel = 0;
  reg [ 3:0] pixel_cycles = 0;

  reg [24:0] line_duration_counter = 0;

  task new_scanline();
    if (scanline == 9'd247) begin
      // VSync
      state <= STATE_VSYNC;
    end else begin
      state <= STATE_HSYNC;
    end

    line_duration_counter <= 0;
  endtask

  always @(posedge clk) begin
    line_duration_counter <= line_duration_counter + 25'h1;

    case (state)
      STATE_VSYNC: begin
        output_450ohm <= 0;
        output_900ohm <= 0;

        if (line_duration_counter == VSYNC_CYCLE_LENGTH[24:0]) begin
          // Enter render
          state <= STATE_VSYNC_CLEANUP;

          line_duration_counter <= 0;
        end
      end
      STATE_VSYNC_CLEANUP: begin
        output_450ohm <= 0;
        output_900ohm <= 1;

        if (line_duration_counter == HSYNC_CYCLE_LENGTH[24:0]) begin
          // Start new line
          new_scanline();
        end
      end
      STATE_HSYNC: begin
        output_450ohm <= 0;
        output_900ohm <= 0;

        if (line_duration_counter == HSYNC_CYCLE_LENGTH[24:0]) begin
          // Enter render
          state <= STATE_RENDER;

          line_duration_counter <= 0;
        end
      end
      STATE_RENDER: begin
        output_450ohm <= 0;
        output_900ohm <= 1;

        pixel_cycles  <= pixel_cycles + 4'h1;

        if (pixel_cycles == PIXEL_LENGTH[3:0]) begin
          pixel_cycles <= 0;

          pixel <= pixel + 8'h1;

          if (pixel == 8'hFF) begin
            // Start new line
            new_scanline();
          end
        end
      end
    endcase
  end

  reg [24:0] counter = 0;

  always @(posedge clk) begin
    if (counter > 0) begin
      counter <= counter - 25'h1;
    end else begin
      counter <= CLK_SPEED;
      // counter <= 25'd100;

      test_output <= ~test_output;
    end
  end

  initial begin
    $display("PERIOD: %d", $rtoi(PERIOD));

    $display("HSYNC_CYCLE_LENGTH: %d", HSYNC_CYCLE_LENGTH);
    $display("VSYNC_CYCLE_LENGTH: %d", VSYNC_CYCLE_LENGTH);

    $display("PIXEL_LENGTH: %d", PIXEL_LENGTH);
  end

endmodule
