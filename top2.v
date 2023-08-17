module top2 (
    input wire refclk,

    input wire button_a_n,
    input wire button_b_n,

    output wire [5:0] led,

    output reg test_output = 0,

    output reg output_450ohm = 0,
    output reg output_900ohm = 0,

    output wire uart_tx,
    input  wire uart_rx,

    // Flash Control
    output wire flash_sclk,
    output wire flash_cs,
    input  wire flash_so,
    output wire flash_si,

    // PSRAM Control
    // These ports are magically inferred and do not appear in the constraints file
    output wire [1:0] O_psram_ck,
    output wire [1:0] O_psram_ck_n,  // This must appear even though it's unused
    inout wire [1:0] IO_psram_rwds,
    inout wire [15:0] IO_psram_dq,
    output wire [1:0] O_psram_reset_n,
    output wire [1:0] O_psram_cs_n
);

  localparam CLK_SPEED = 85_500_000;
  localparam BAUDRATE = 115200;

  wire clk_sys;
  wire clk_mem_90deg;

  // assign reset_n = button_b_n;
  reg reset_n = 0;

  reg [7:0] reset_counter = 0;

  always @(posedge clk_sys) begin
    if (reset_counter == 8'hFF) begin
      reset_n <= 1;
    end else begin
      reset_counter <= reset_counter + 8'h1;
    end
  end

  ////////////////////////////////////////////////////////////////////////////////////////
  // PSRAM

  assign O_psram_reset_n = reset_n;

  reg psram_rd = 0;
  reg psram_wr = 0;

  reg [20:0] psram_rd_addr = 0;
  reg [20:0] psram_wr_addr = 0;

  wire [15:0] psram_q;
  wire psram_busy;

  PsramController #(
      .FREQ(CLK_SPEED),
      .LATENCY(4)
  ) psram (
      .clk  (clk_sys),
      .clk_p(clk_mem_90deg),

      .resetn(reset_n),

      .read (psram_rd),
      .write(psram_wr),

      .addr({psram_wr ? psram_wr_addr : psram_rd_addr, 1'b0}),
      .din (fifo_q),
      .dout(psram_q),

      .busy(psram_busy),

      // PSRAM Control
      .O_psram_ck(O_psram_ck),
      .IO_psram_rwds(IO_psram_rwds),
      .IO_psram_dq(IO_psram_dq),
      .O_psram_cs_n(O_psram_cs_n)
  );

  ////////////////////////////////////////////////////////////////////////////////////////
  // Flash

  reg [23:0] flash_addr = 0;

  reg flash_rd = 0;
  reg flash_halt = 0;

  wire [7:0] flash_byte;
  wire read_ready;
  wire flash_busy;

  readonlyflash flash (
      .clk(clk_sys),

      .addr(flash_addr),
      .rd(flash_rd),
      .halt_rd(flash_halt),

      .q(flash_byte),
      .read_ready(read_ready),

      .busy(flash_busy),

      // Flash Control
      .flash_sclk(flash_sclk),
      .flash_cs  (flash_cs),
      .flash_so  (flash_so),
      .flash_si  (flash_si)
  );

  reg fifo_rd = 0;

  wire [15:0] fifo_q;
  wire fifo_almost_empty;
  wire fifo_almost_full;
  wire fifo_empty;

  fifo fifo (
      .WrClk(clk_sys),
      .RdClk(clk_sys),

      // .WrReset(WrReset_i),
      // .RdReset(RdReset_i),

      .Data(flash_byte),
      .WrEn(read_ready),

      .RdEn(fifo_rd),
      .Q(fifo_q),

      .Almost_Empty(fifo_almost_empty),
      .Almost_Full(fifo_almost_full),
      .Empty(fifo_empty)
      // .Full(Full_o)  //output Full
  );

  reg wait_for_fifo_drain = 0;
  reg flash_complete = 0;

  assign led[0] = ~flash_complete;

  reg start_flash = 0;
  reg prev_button_b_n = 0;

  // Read from flash into FIFO
  always @(posedge clk_sys) begin
    flash_rd <= 0;
    flash_halt <= 0;

    prev_button_b_n <= button_b_n;

    if (~button_b_n && prev_button_b_n) begin
      start_flash <= 1;
    end

    if (start_flash && ~fifo_almost_full && ~flash_busy && ~wait_for_fifo_drain && ~flash_complete) begin
      // Start initial read
      flash_rd <= 1;
    end

    if (fifo_almost_empty) begin
      // We can now start loading data again
      wait_for_fifo_drain <= 0;
    end

    if (fifo_almost_full && flash_busy) begin
      // We need to halt this read
      flash_halt <= 1;

      wait_for_fifo_drain <= 1;
    end

    if (read_ready) begin
      // We've received a byte, increment local addr
      // Byte will automatically feed into FIFO
      flash_addr <= flash_addr + 1'b1;

      if (flash_addr >= 24'hF000) begin
        // We've read all the data
        flash_complete <= 1;

        flash_halt <= 1;
      end
    end
  end

  // Transfer from FIFO to PSRAM
  always @(posedge clk_sys) begin
    fifo_rd  <= 0;
    psram_wr <= 0;

    if (psram_wr) begin
      // Increment address
      psram_wr_addr <= psram_wr_addr + 1'b1;
    end

    if (fifo_rd) begin
      // Received data
      psram_wr <= 1;
    end else if (~fifo_empty && ~psram_busy) begin
      // Start read from fifo
      fifo_rd <= 1;
    end
  end

  reg demo = 0;

  assign led[1] = ~demo;

  reg prev_psram_busy = 0;
  reg prev_button_a_n = 0;
  reg prev_tx_busy = 0;

  reg transmit = 0;

  // Demo reading out from PSRAM
  always @(posedge clk_sys) begin
    prev_button_a_n <= button_a_n;
    prev_psram_busy <= psram_busy;
    prev_tx_busy <= tx_busy;

    psram_rd <= 0;
    transmit <= 0;

    if (~button_a_n && prev_button_a_n) begin
      demo <= 1;

      psram_rd <= 1;
    end

    if (demo) begin
      // if (~psram_busy) begin
      //   psram_rd <= 1;
      // end

      if (~psram_busy && prev_psram_busy) begin
        // Completed read
        transmit <= 1;
      end

      if (~tx_busy && prev_tx_busy) begin
        // Finished write, request next word
        psram_rd <= 1;
      end

      if (psram_rd) begin
        psram_rd_addr <= psram_rd_addr + 1'b1;
      end
    end
  end

  // wire tx_rd = ~tx_busy && prev_tx_busy;

  // reg prev_rx_finished_byte = 0;
  // reg prev_tx_busy = 0;

  // reg prev_button = 0;

  // always @(posedge clk_sys) begin
  //   prev_rx_finished_byte <= rx_finished_byte;
  //   prev_tx_busy <= tx_busy;
  //   prev_button <= button_b_n;

  //   flash_rd <= 0;

  //   // if ((rx_finished_byte && ~prev_rx_finished_byte) || (~tx_busy && prev_tx_busy)) begin
  //   if (rx_finished_byte && ~prev_rx_finished_byte) begin
  //     flash_rd <= 1;

  //     addr <= 24'h0;
  //   end else if (~tx_busy && prev_tx_busy) begin
  //     flash_rd <= 1;

  //     addr <= addr + 24'h1;
  //   end
  // end

  ////////////////////////////////////////////////////////////////////////////////////////
  // UART

  wire [7:0] rx_data;
  wire rx_finished_byte;

  uart_tx #(
      .CLK_HZ(CLK_SPEED),
      .BAUD  (BAUDRATE)
  ) uart_transmitter (
      .clk (clk_sys),
      .nrst(reset_n),

      .tx_data(psram_q[7:0]),
      .tx_start(transmit),
      .tx_busy(tx_busy),
      .txd(uart_tx)
  );

  wire uart_rx_s;

  synch uart_s (
      uart_rx,
      uart_rx_s,
      clk_sys
  );

  uart_rx #(
      .CLK_HZ(CLK_SPEED),
      .BAUD  (BAUDRATE)
  ) uart_receiver (
      .clk (clk_sys),
      .nrst(reset_n),

      .rx_data(rx_data),
      .rx_done(rx_finished_byte),
      .rxd(uart_rx_s)
  );

  ////////////////////////////////////////////////////////////////////////////////////////
  // PLL

  Gowin_rPLL pll (
      .clkin  (refclk),
      .clkout (clk_sys),
      .clkoutp(clk_mem_90deg)
  );

endmodule
