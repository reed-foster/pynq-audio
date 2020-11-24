// fm.sv - Reed Foster
// fm synthesizer

module fm (
  input wire clk, reset,
  logic [23:0] fundamental, // 14 bit integer part, 10 bit fractional part
  logic [15:0] harmonicity, // 3 bit integer part, 13 bit fractional part
  logic [15:0] mod_index, // 7 bit integer part, 9 bit fractional part
  Axis_If.Master signal_out
);

// signal path (number_ is quasistatic, signal~ is rapidly varying)
//  fundamental_ -> fc_
//  fundamental_ * harmonicity_ -> fm_
//    fm_ * mod_index_ -> D_
//      D_ * cycle(fm)~ + sig(fc)~ -> mix_freq~
//        cycle(mix_freq)~ -> output~

Axis_If #(.DWIDTH(24)) mixed_freq_axis();
Axis_If #(.DWIDTH(24)) mod_freq_axis();

// use the same dsp macros for the whole modulator (dsp48):
// fixed-point widths
//  A: 24-bit (don't ever use more than 24 bits)
//  B: 18-bit
//  C: 48-bit
//  P: 48-bit

// get Fm, quasistatic modulation frequency
logic [47:0] mod_freq; // modulation frequency
logic [47:0] mod_depth; // modulation depth
xbip_dsp48_macro_0 mult_0 ( 
  .clk,
  .A(fundamental), // 14.10 (14 bit integer, 10 bit fraction)
  .B({2'b0, harmonicity}), // 5.13
  .C('0),
  .P(mod_freq) // 25.23
);

logic [23:0] mod_sig_unit_amp;
assign mod_freq_axis.data = mod_freq[37:14]; // 15.9
assign mod_freq_axis.valid = 1'b1;
// generate dynamic modulation signal with frequency Fm
wavetable modulator (
  .clk,
  .reset,
  .freq(mod_freq_axis), // 15.9
  .data_out(mod_sig_unit_amp) // 0.24
);

// get D, depth of modulation from modulation index and Fm
xbip_dsp48_macro_0 mult_0 (
  .clk,
  .A(mod_freq[37:14]), // 15.9
  .B({2'b0, mod_index}), // 9.9
  .C('0),
  .P(mod_depth) // 30.18
);

// get mixed_freq, dynamic frequency of final osciallator
logic [47:0] mixed_freq;
xbip_dsp48_macro_0 mult (
  .clk,
  .A(mod_sig_unit_amp), // 0.24
  .B(mod_depth[29:12]), // 12.6
  .C({4'b0, fundamental, 20'b0}), // 18.30
  .P(mixed_freq) // 18.30
);

assign mixed_freq_axis.data = mixed_freq[44:21]; // 15.9
assign mixed_freq_axis.valid = 1'b1;
// generate output signal at dynamical frequency mixed_freq
wavetable mixer (
  .clk,
  .reset,
  .freq(mixed_freq_axis),
  .data_out(signal_out)
);

endmodule
