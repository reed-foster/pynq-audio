// pitch_detect.sv - Reed Foster
// spectrum-based pitch detector

module pitch_detect (
  input wire clk, reset,
  Axis_If.Slave input_signal,
  Axis_If.Master pitch
);

Axis_If #(.DWIDTH(24)) buffer_out;

// buffer
sample_buffer buffer (
  .clk,
  .reset,
  .sample_in(input_signal),
  .sample_out(buffer_out)
);

// fft
fft fft_i (
  .clk,
  .reset,
  .din(buffer_out),
  .dout()
);

endmodule
