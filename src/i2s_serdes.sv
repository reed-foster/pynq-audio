// i2s_serdes.sv - Reed Foster
// i2s serializer/deserializer for ADAU1761 data interface

module i2s_serdes (
  input wire clk, reset,
  // i2s interface
  input         sdata_i,
  output        sdata_o,
  output        bclk,  // bit clock
  output        lrclk, // left-right clock
  output [1:0]  codec_addr,
  // i/o dsp stream interfaces
  Axis_If.Slave   dac_sample,
  Axis_If.Master  adc_sample
);

endmodule
