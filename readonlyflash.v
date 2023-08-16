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
    output reg  flash_sclk = 1,
    output reg  flash_cs = 1,
    output reg  flash_so = 0,
    input  wire flash_si,
    output reg  flash_reset
);

  reg [23:0] addr_buffer = 0;

  localparam STATE_NONE = 0;
  localparam STATE_WRITE_BYTE = 1;
  localparam STATE_COMMAND_COMPLETE = 2;
  localparam STATE_OUTPUT = 3;

  reg [1:0] state = STATE_NONE;

  assign busy = state != STATE_NONE;

  reg [4:0] bit_step = 0;
  reg [23:0] input_shifter = 0;

  reg [1:0] state_complete = 0;
  reg [4:0] bits_to_write = 0;

  reg [7:0] output_shifter = 0;

  reg queued_halt_rd = 0;

  always @(posedge clk) begin
    flash_sclk <= 1;

    read_ready <= 0;

    if (halt_rd) begin
      queued_halt_rd <= 1;
    end

    case (state)
      STATE_NONE: begin
        if (rd) begin
          state <= STATE_WRITE_BYTE;

          // Send read command
          input_shifter[7:0] <= 8'h03;
          state_complete <= STATE_COMMAND_COMPLETE;
          bits_to_write <= 5'h8;

          bit_step <= 0;

          // Prep for command starting
          flash_sclk <= 0;
          flash_cs <= 0;

          // Store current addr
          addr_buffer <= addr;
        end
      end
      STATE_WRITE_BYTE: begin
        // Tick clock
        flash_sclk <= ~flash_sclk;

        if (flash_sclk) begin
          // We just wrote bit, shift
          input_shifter <= {1'b0, input_shifter[23:1]};

          bit_step <= bit_step + 5'h1;

          if (bit_step == bits_to_write - 5'h1) begin
            // We finished this segment, move to next
            state <= state_complete;

            bit_step <= 0;
          end
        end else begin
          // Set shift bit
          flash_so <= input_shifter[0];
        end
      end
      STATE_COMMAND_COMPLETE: begin
        state <= STATE_WRITE_BYTE;

        // Hold clock low for next write
        flash_sclk <= 0;

        // Send address
        input_shifter <= addr_buffer;
        state_complete <= STATE_OUTPUT;
        bits_to_write <= 5'd24;
      end
      STATE_OUTPUT: begin
        // We should now start receiving data from the flash
        flash_sclk <= ~flash_sclk;

        if (flash_sclk) begin
          output_shifter <= {output_shifter[6:0], flash_si};

          bit_step <= bit_step + 5'h1;

          if (bit_step == 8'h7) begin
            // We've received the byte
            read_ready <= 1;
            q <= {output_shifter[6:0], flash_si};

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
