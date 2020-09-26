// adau1761.sv - Reed Foster
// top level ADAU1761 audio codec controller

module adau1761 (
  input wire clk, reset,
  // i2s interface
  input         sdata_i,
  output        sdata_o,
  output        bclk,  // bit clock
  output        lrclk, // left-right clock
  output [1:0]  codec_addr,
  // i2c interface

);

Axis_if #(.DWIDTH(24)) dac_sample();
Axis_if #(.DWIDTH(24)) adc_sample();

i2s_serdes i2s_i (
  .clk,
  .reset,
  .sdata_i,
  .sdata_o,
  .bclk,
  .lrclk,
  .codec_addr,
  .dac_sample,
  .adc_sample
);

dsp dsp_i (
  .clk,
  .reset,
  .dac_sample,
  .adc_sample
);

endmodule
