// pitch_detect_test.sv - Reed Foster
// testbench for pitch detection module

module pitch_detect_test ();

Axis_If #(.DWIDTH(24)) input_signal ();
Axis_If #(.DWIDTH(24)) pitch ();

localparam CLK_RATE_HZ = 100_000_000;
logic clk = 0;
always #(0.5s/CLK_RATE_HZ) clk = ~clk;
logic reset = 0;

logic [10:0] sample_idx;
logic [23:0] samples [2048];

assign pitch.ready = 1'b1;

always @(posedge clk) begin
  if (reset) begin
    input_signal.data <= '0;
    sample_idx <= '0;
    input_signal.valid <= '0;
  end else begin
    sample_idx <= sample_idx + 1'b1;
    input_signal.data <= samples[sample_idx];
    input_signal.valid <= 1'b1;
  end
end

initial begin
  $readmemh("sample_timeseries.txt", samples);
  reset <= 1'b1;
  repeat (500) @(posedge clk);
  reset <= 1'b0;
  repeat (10000) @(posedge clk);
  $finish;
end

pitch_detect dut_i (
  .clk,
  .reset,
  .input_signal,
  .pitch
);

endmodule
