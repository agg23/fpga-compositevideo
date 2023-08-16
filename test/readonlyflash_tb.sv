module readonlyflash_tb;

  reg clk = 0;

  reg [23:0] addr = 0;
  reg rd = 0;
  reg halt_rd = 0;

  wire [7:0] q;

  reg flash_si = 0;

  readonlyflash flash_uut (
      .clk(clk),

      .addr(addr),
      .rd(rd),
      .halt_rd(halt_rd),

      .q(q),

      .flash_si(flash_si)
  );

  always begin
    #1 clk <= ~clk;
  end

  reg [39:0] shifter = 40'hE2_A3_B6_F0_69;

  initial begin
    #10;

    rd   = 1;
    addr = 24'hF0_1893;
    // 1111_0000_0001_1000_1001_0011

    #2;

    rd = 0;

    @(posedge clk iff flash_uut.state == 3);

    for (int i = 0; i < 40; i += 1) begin
      flash_si = shifter[39];
      shifter  = {shifter[38:0], 1'b0};
      #4;
    end

    halt_rd  = 1;
    flash_si = 1;

    #2;

    halt_rd = 0;

    #2;

    flash_si = 0;
  end

endmodule
