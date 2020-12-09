// sample_buffer_test.sv - Reed Foster
// testbench for sample buffer

module sample_buffer_test ();

Axis_If #(.DWIDTH(24)) input_samp();
Axis_If #(.DWIDTH(24)) buffer_out();
Axis_If #(.DWIDTH(48)) fft_bins();

localparam CLK_RATE_HZ = 100_000_000;

logic clk = 0;
always #(0.5s/CLK_RATE_HZ) clk = ~clk;
logic reset = 0;

assign input_samp.valid = 1'b1;

always @(posedge clk) begin
  if (reset) begin
    input_samp.data <= '0;
  end else if (input_samp.valid && input_samp.ready) begin
    input_samp.data <= input_samp.data + 1'b1;
  end
end

initial begin
  reset <= 1;
  repeat (500) @(posedge clk);
  reset <= 0;
  repeat (10000) @(posedge clk);
  $finish;
end

sample_buffer dut_i (
  .clk,
  .reset,
  .din(input_samp),
  .dout(buffer_out)
);

fft downstream (
  .clk,
  .reset,
  .din(buffer_out),
  .dout(fft_bins)
);

endmodule
