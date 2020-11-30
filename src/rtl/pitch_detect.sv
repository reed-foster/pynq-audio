// pitch_detect.sv - Reed Foster
// spectrum-based pitch detector

module pitch_detect (
  input wire clk, reset,
  Axis_If.Slave input_signal,
  Axis_If.Master pitch
);

// buffer
Axis_If #(.DWIDTH(24)) buffer_out;
sample_buffer buffer (
  .clk,
  .reset,
  .sample_in(input_signal),
  .sample_out(buffer_out)
);

// fft
Axis_If #(.DWIDTH(24)) fft_bins;
fft fft_i (
  .clk,
  .reset,
  .din(buffer_out),
  .dout(fft_bins)
);

Axis_If #(.DWIDTH(48)) fft_mag;
always @(posedge clk) begin
  fft_mag.data <= fft_bins.data[47:24]*fft_bins.data[47:24] + fft_bins.data[23:0]*fft_bins.data[23:0];
  fft_mag.valid <= fft_bins.valid;
end

Axis_If #(.DWIDTH(24)) fbin_i_dout
fundamental_bin_finder fbin_i (
  .clk,
  .reset,
  .fft_mag,
  .dout(fbin_i_dout)
);
   
// phase vocoder
endmodule
