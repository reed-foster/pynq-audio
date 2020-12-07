// pitch_detect_test.sv - Reed Foster
// testbench for pitch detection module

module pitch_detect_test ();

Axis_If #(.DWIDTH(24)) input_signal ();
Axis_If #(.DWIDTH(24)) pitch ();

localparam CLK_RATE_HZ = 100_000_000;
logic clk = 0;
always begin
  clk <= 1'b1;
  #(0.5s/CLK_RATE_HZ) clk <= 1'b0;
  #(0.5s/CLK_RATE_HZ);
end
logic reset = 0;

logic [9:0] sample_idx;
logic [23:0] samples [2048];

assign pitch.ready = 1'b1;

always @(posedge clk) begin
  if (reset) begin
    input_signal.data <= '0;
    sample_idx <= '0;
    input_signal.valid <= '0;
  end else begin
    if (input_signal.ready) begin
      sample_idx <= sample_idx + 1'b1;
    end
    input_signal.data <= samples[sample_idx + 1024];
    input_signal.valid <= 1'b1;
  end
end

logic dbg_capture, dbg_next;
logic [143:0] dbg_data;

initial begin
  $readmemh("sawtooth_timeseries.txt", samples);
  reset <= 1'b1;
  dbg_capture <= 1'b0;
  dbg_next <= 1'b0;
  repeat (500) @(posedge clk);
  reset <= 1'b0;
  repeat (20000) @(posedge clk);
  dbg_capture <= 1'b1;
  repeat (10000) @(posedge clk);
  repeat (4096) begin
    dbg_next <= 1'b1;
    @(posedge clk);
    dbg_next <= 1'b0;
    @(posedge clk);
  end
  repeat (40000) @(posedge clk);
  $finish;
end

pitch_detect dut_i (
  .clk,
  .reset,
  .input_signal,
  .pitch,
  .dbg_capture,
  .dbg_next,
  .dbg_data
);

endmodule
