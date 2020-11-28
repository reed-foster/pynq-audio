// adau1761.sv - Reed Foster
// top level ADAU1761 audio codec controller

module adau1761 (
  input wire clk, reset,
  input enabled,
  // i2s interface
  input         sdata_i,
  output        sdata_o,
  input         bclk,  // bit clock
  input         lrclk, // left-right clock
  // fm controls
  input [23:0]  fundamental,
  input [15:0]  harmonicity,
  input [15:0]  mod_index
);

Axis_If #(.DWIDTH(2*24)) dac_sample(); // 48 bits for L/R
Axis_If #(.DWIDTH(2*24)) adc_sample();

i2s_serdes i2s_i (
  .clk,
  .reset,
  .enabled,
  .sdata_i,
  .sdata_o,
  .bclk,
  .lrclk,
  .dac_sample,
  .adc_sample
);

// drive with fm synth
logic [23:0] signal;

assign dac_sample.data[47:24] = signal;
assign dac_sample.data[23:0] = signal;
assign dac_sample.valid = 1'b1;
assign adc_sample.ready = 1'b1;

fm synth (
  .clk,
  .reset,
  .fundamental,
  .harmonicity,
  .mod_index,
  .signal_out(signal)
);

endmodule
