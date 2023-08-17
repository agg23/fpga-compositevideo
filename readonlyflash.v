// This is expected to run at 2x the flash clock, so 110MHz is the max speed on Tang Nano 9k
// The stage transitions could be more optimized to save some cycles and thus increase throughput
module readonlyflash (
    input wire clk,

    input wire [23:0] addr,
    input wire rd,
    input wire halt_rd,

    output reg [7:0] q = 0,
    output reg read_ready = 0,

    output wire busy,

    // Flash Control
    output reg  flash_sclk = 0,
    output reg  flash_cs = 1,
    input  wire flash_so,
    output reg  flash_si = 0
    // output reg  flash_reset
);

  reg [23:0] addr_buffer = 0;

  localparam STATE_NONE = 0;
  localparam STATE_START_DELAY = 1;
  localparam STATE_WRITE_BYTE = 2;
  localparam STATE_COMMAND_COMPLETE = 3;
  localparam STATE_OUTPUT = 4;

  reg [2:0] state = STATE_NONE;

  assign busy = state != STATE_NONE;

  reg [4:0] bit_step = 0;
  reg [23:0] input_shifter = 0;

  reg [2:0] state_complete = 0;
  reg [4:0] bits_to_write = 0;

  reg [7:0] output_shifter = 0;

  reg queued_halt_rd = 0;

  always @(posedge clk) begin
    flash_sclk <= 0;

    read_ready <= 0;

    if (halt_rd) begin
      queued_halt_rd <= 1;
    end

    case (state)
      STATE_NONE: begin
        flash_cs <= 1;

        if (rd) begin
          state <= STATE_START_DELAY;

          flash_sclk <= 1;

          // Send read command
          input_shifter[23:16] <= 8'h03;
          state_complete <= STATE_COMMAND_COMPLETE;
          bits_to_write <= 5'h8;

          bit_step <= 0;

          // Prep for command starting
          // flash_sclk <= 0;
          flash_cs <= 0;

          // Store current addr
          addr_buffer <= addr;
        end
      end
      STATE_START_DELAY: begin
        state <= STATE_WRITE_BYTE;

        flash_sclk <= 0;

        flash_si <= input_shifter[0];
      end
      STATE_WRITE_BYTE: begin
        // Tick clock
        flash_sclk <= ~flash_sclk;

        if (flash_sclk) begin
          // We just wrote bit, shift
          input_shifter <= {input_shifter[22:0], 1'b0};
          flash_si <= input_shifter[22];

          bit_step <= bit_step + 5'h1;

          if (bit_step == bits_to_write - 5'h1) begin
            // We finished this segment, move to next
            state <= state_complete;

            bit_step <= 0;
          end
        end
      end
      STATE_COMMAND_COMPLETE: begin
        state <= STATE_WRITE_BYTE;

        // Hold clock low for next write
        flash_sclk <= 0;

        // Send address
        input_shifter <= addr_buffer;
        flash_si <= addr_buffer[0];
        state_complete <= STATE_OUTPUT;
        bits_to_write <= 5'd24;
      end
      STATE_OUTPUT: begin
        // We should now start receiving data from the flash
        flash_sclk <= ~flash_sclk;

        if (flash_sclk) begin
          output_shifter <= {output_shifter[6:0], flash_so};

          bit_step <= bit_step + 5'h1;

          if (bit_step == 8'h7) begin
            // We've received the byte
            read_ready <= 1;
            q <= {output_shifter[6:0], flash_so};

            if (queued_halt_rd || halt_rd) begin
              // End of read was requested
              state <= STATE_NONE;

              queued_halt_rd <= 0;
            end else begin
              // Read another byte
              bit_step <= 0;
            end
          end
        end
      end
    endcase
  end

endmodule
