module top_tb;

  reg  clk = 0;

  wire test_output;
  wire output_450ohm;
  wire output_900ohm;

  top top_uut (
      .clk(clk),

      .test_output(test_output),

      .output_450ohm(output_450ohm),
      .output_900ohm(output_900ohm)
  );

  always begin
    #1 clk <= ~clk;
  end

  initial begin

  end

endmodule
