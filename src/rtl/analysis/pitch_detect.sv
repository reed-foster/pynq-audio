// pitch_detect.sv - Reed Foster
// spectrum-based pitch detector

module pitch_detect (
  input wire clk, reset,
  Axis_If.Slave input_signal,
  Axis_If.Master pitch,
  // debug
  input         dbg_capture,
  input         dbg_next,
  output [23:0] dbg_data
);

// buffer
Axis_If #(.DWIDTH(24)) buffer_out ();
sample_buffer buffer (
  .clk,
  .reset,
  .din(input_signal),
  .dout(buffer_out)
);

// fft
Axis_If #(.DWIDTH(48)) fft_bins ();
fft fft_i (
  .clk,
  .reset,
  .din(buffer_out),
  .dout(fft_bins)
);

// always accept fft_data
assign fft_bins.ready = 1'b1;

// calculate magnitude of FFT data
Axis_If #(.DWIDTH(48)) fft_mag ();

logic [35:0] re2, im2;
xbip_dsp48_macro_1 re_mag2 (
  .clk,
  .A(fft_bins.data[47:30]),
  .B(fft_bins.data[47:30]),
  .P(re2)
);

xbip_dsp48_macro_1 im_mag2 (
  .clk,
  .A(fft_bins.data[23:6]),
  .B(fft_bins.data[23:6]),
  .P(im2)
);

logic [3:0] valid;
integer i;
always @(posedge clk) begin
  valid[0] <= fft_bins.valid;
  for (i = 1; i < 4; i++) begin
    valid[i] <= valid[i-1];
  end
  fft_mag.data <= {11'b0, re2 + im2};
  fft_mag.valid <= valid[3];
end

Axis_If #(.DWIDTH(5)) fbin_i_dout ();
assign fbin_i_dout.ready = pitch.ready;
fundamental_bin_finder fbin_i (
  .clk,
  .reset,
  .fft_mag,
  .dout(fbin_i_dout)
);

// phase vocoder

// cordic
logic phase_valid;
logic [23:0] phase;

cordic_1 phase_calc (
  .aclk(clk),
  .s_axis_cartesian_tdata(fft_bins.data),
  .s_axis_cartesian_tvalid(fft_bins.valid),
  .m_axis_dout_tdata(phase), // phase output in scaled radians [-1, 1]
  .m_axis_dout_tvalid(phase_valid)
);

// counter for buffer index
logic [9:0] sample_count;

// buffer signals
logic ping_pong_sel = 0; // when 0, write to phase_buf_0, phase_buf_1 has old data
logic buf_valid; // goes high when buffer finishes filling
logic [23:0] last_phase, current_phase;
logic [23:0] phase_buf_0 [32]; // fundamental will only ever be in first 32 bins, so only save those
logic [23:0] phase_buf_1 [32];

logic [4:0] fbin_data;
logic fbin_data_valid;
always @(posedge clk) begin
  if (reset) begin
    fbin_data <= '0;
    fbin_data_valid <= 1'b0;
  end else begin
    if (sample_count == 10'h3ff) begin
      fbin_data_valid <= 1'b0;
    end else if (fbin_i_dout.valid) begin
      fbin_data <= fbin_i_dout.data;
      fbin_data_valid <= 1'b1;
    end
  end
end

always @(posedge clk) begin
  if (reset) begin
    sample_count <= '0;
    buf_valid <= 1'b0;
    ping_pong_sel <= 1'b0;
    current_phase <= '0;
    last_phase <= '0;
  end else begin
    if (phase_valid) begin
      sample_count <= sample_count + 1'b1;
    end
    if (sample_count >= 32) begin
      buf_valid <= 1'b1;
    end else begin
      if (ping_pong_sel) begin
        phase_buf_1[sample_count] <= phase;
      end else begin
        phase_buf_0[sample_count] <= phase;
      end
    end
    if (buf_valid && fbin_data_valid) begin
      last_phase <= ping_pong_sel ? phase_buf_0[fbin_data] : phase_buf_1[fbin_data];
      current_phase <= ping_pong_sel ? phase_buf_1[fbin_data] : phase_buf_0[fbin_data];
    end
    if (sample_count == 10'h3ff) begin
      ping_pong_sel <= ~ping_pong_sel;
      buf_valid <= 1'b0;
    end
  end
end

logic [2:0] fundamental_valid;
integer j;
always @(posedge clk) begin
  if (reset) begin
    fundamental_valid <= '0;
  end else begin
    fundamental_valid[0] <= fbin_i_dout.valid;
    for (j = 1; j < 3; j++) begin
      fundamental_valid[j] <= fundamental_valid[j-1];
    end
  end
end

// min_n = round(last_phase_2pi - current_phase_2pi + step_size/dft_size*maxk)
// fundamental = (current_phase_2pi - last_phase_2pi + min_n)/(step_size/f_s)
// phase is in format 3.21
// fbin_data is in format 5.0
logic [26:0] min_n; // 6.21
logic [23:0] delta_phase, neg_delta_phase; // 3.21
assign delta_phase = last_phase - current_phase;
assign neg_delta_phase = current_phase - last_phase;
logic [23:0] fundamental; // 14.10
localparam [37:0] f_ratio = 38'h2ee; // 35.3
logic [5:0] min_n_rounded;
always @(posedge clk) begin
  min_n <= ({{3{delta_phase[23]}}, delta_phase} + ({fbin_data, 21'b0} >> 1));
  min_n_rounded <= min_n[20] ? min_n[26:21] + 1'b1 : min_n[26:21];
  fundamental <= (({{3{neg_delta_phase[23]}}, neg_delta_phase} + {min_n_rounded, 21'b0}) * f_ratio) >> 14;
end

assign pitch.valid = fundamental_valid[5];
assign pitch.data = fundamental;

debug #(.DWIDTH(5)) dbg_0 (
  .clk,
  .reset,
  .data_in_valid(fbin_i_dout.valid),
  .data_in(fbin_i_dout.data),
  .data_out(dbg_data),
  .capture(dbg_capture),
  .next(dbg_next)
);

endmodule
