// wavetable.sv - Reed Foster
// arbitrary frequency sinewave generator

module wavetable #(
  parameter int f_sample = 48_000,
  parameter int f_clock = 100_000_000
)(
  input wire clk, reset,
  Axis_If.Slave freq,
  Axis_If.Master data_out
);

// freq.data is only 24 bits, but the phase_factor is extended to 48 bits
// freq.data is represented as 15-bit integer part (up to 32kHz), 9-bit fractional part
assign freq.ready = 1'b1;
logic [47:0] phase_factor = '0;
always @(posedge clk) begin
  if (reset) begin
    phase_factor <= '0;
  end else if (freq.valid) begin
    // delta_phase_per_cyc = num_unique_phases*f_tone/f_clock
    // there are 2**22 unique values that phasor can take on
    // shift left by 46 bits to account for 2**22 unique values
    //   and add an extra 24 fractional bits
    // shift right by 9 bits to account for 9 fractional bits in
    //   freq.data
    phase_factor <= (freq.data*((48'b1<<46)/f_clock))>>9;
  end
end

logic [47:0] phasor = '0; // phasor is stored as 3-bit integer, 45-bit fraction (3Q45)
always @(posedge clk) begin
  if (reset) begin
    phasor <= '0;
  end else begin
    automatic logic [47:0] next_phase = phasor + phase_factor;
    // if next phase would be greater than 1, wrap phase to -1
    // 1 in 3Q45 = 48'h2000_0000_0000
    // -1 in 3Q45 = 48'he000_0000_0000
    if (next_phase[47] == 0 && next_phase[46:0] > 48'h2000_0000_0000) begin
      phasor <= 48'he000_0000_0000;
    end else begin
      phasor <= phasor + phase_factor;
    end
  end
end

logic [47:0] sin_cos_data;
assign data_out.data = sin_cos_data[47:23];

// calculate sin/cos of phase
cordic_0 phase_calc (
  .aclk(clk),
  .s_axis_phase_tvalid(1'b1),
  .s_axis_phase_tdata(phasor[47:24]), // discard 24 least-significant fractional bits
  .m_axis_dout_tvalid(data_out.valid),
  .m_axis_dout_tdata(sin_cos_data)
);

endmodule
