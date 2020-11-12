// wavetable_test.sv - Reed Foster
// test for sinewave generator

module wavetable_test ();

Axis_If #(.DWIDTH(24)) freq();
Axis_If #(.DWIDTH(24)) data_out();

localparam CLK_RATE_HZ = 100_000_000;
logic clk = 0;
logic clk_slow = 0;
always #(0.5s/CLK_RATE_HZ) clk = ~clk;
always #(100*0.5s/CLK_RATE_HZ) clk_slow = ~clk_slow;

logic reset;
initial begin
  reset = 1;
  repeat (500) @(posedge clk);
  reset = 0;
  freq.valid = 1;
  repeat (1_000_000_000) @(posedge clk); // 10 seconds
  $finish;
end

always @(posedge clk_slow) begin
  if (reset) begin
    freq.data = 24'b0;
  end else begin
    freq.data <= freq.data + 24'b1_000000000; // increase by 1Hz every 1us
  end
end

wavetable dut_i (
  .clk,
  .reset,
  .freq,
  .data_out
);


endmodule
