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
  output [1:0]  codec_addr,
  // mmio control
  input [1:0]   harmonicity,
  input [15:0]  mod_index,
  // debug
  input         dbg_capture,
  input         dbg_next,
  output [23:0] dbg_data
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
  .harmonicity(harmonicity),
  .mod_index(mod_index),
  .dbg_capture(dbg_capture),
  .dbg_next(dbg_next),
  .dbg_data(dbg_data)
);

endmodule
