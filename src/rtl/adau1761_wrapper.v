// adau1761_wrapper.v - Reed Foster
// verilog wrapper so module can be used in Vivado block design

module adau1761_wrapper (
  input wire clk, reset_n,
  input enabled,
  // i2s interface
  input         sdata_i,
  output        sdata_o,
  input         bclk,  // bit clock
  input         lrclk, // left-right clock
  output [1:0]  codec_addr
);

assign codec_addr = 2'b11;

adau1761 device (
  .clk(clk),
  .reset(~reset_n),
  .enabled(enabled),
  .sdata_i(sdata_i),
  .sdata_o(sdata_o),
  .bclk(bclk),
  .lrclk(lrclk),
);

endmodule
