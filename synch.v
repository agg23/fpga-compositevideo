module synch #(
    parameter WIDTH = 1
) (
    input wire [WIDTH-1:0] synch_in,
    output reg [WIDTH-1:0] synch_out,
    input wire clk
);

  reg [WIDTH-1:0] stage0;
  reg [WIDTH-1:0] stage1;

  always @(posedge clk) begin
    stage0 <= synch_in;
    stage1 <= stage0;
    synch_out <= stage1;
  end

endmodule
