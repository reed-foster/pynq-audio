// fundamental_bin_finder_test.sv - Reed Foster
// testbench for fundamental bin finder

module fundamental_bin_finder_test ();

Axis_If #(.DWIDTH(48)) fft_mag ();
Axis_If #(.DWIDTH(10)) dout ();

localparam CLK_RATE_HZ = 100_000_000;

logic clk = 0;
always #(0.5s/CLK_RATE_HZ) clk = ~clk;
logic reset = 0;

assign dout.ready = 1'b1;

logic [10:0] sample_idx;
logic [47:0] samples [2048];

always @(posedge clk) begin
  if (reset) begin
    fft_mag.data <= '0;
    sample_idx <= 1'b0;
    fft_mag.valid <= 1'b0;
  end else begin
    sample_idx <= sample_idx + 1'b1;
    fft_mag.data <= samples[sample_idx] + $urandom_range(1<<13, (1<<20) - 1);
    fft_mag.valid <= 1'b1;
  end
end

initial begin
  $readmemh("sample_fft.txt", samples);
  reset <= '1;
  repeat (400) @(posedge clk);
  reset <= '0;
  repeat (4000) @(posedge clk);
  $finish;
end

fundamental_bin_finder dut_i (
  .clk,
  .reset,
  .fft_mag,
  .dout
);

endmodule
