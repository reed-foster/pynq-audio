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
  input [15:0]  harmonicity,
  input [15:0]  mod_index,
  // debug
  input   [8:0] dbg_capture,
  input   [8:0] dbg_next,
  output [23:0] dbg_data_0,
  output [23:0] dbg_data_1,
  output [23:0] dbg_data_2,
  output [23:0] dbg_data_3,
  output [23:0] dbg_data_4,
  output [23:0] dbg_data_5,
  output [23:0] dbg_data_6,
  output [23:0] dbg_data_7,
  output [23:0] dbg_data_8
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
  .dbg_capture_0(dbg_capture[0]),
  .dbg_next_0(dbg_next[0]),
  .dbg_data_0(dbg_data_0),
  .dbg_capture_1(dbg_capture[1]),
  .dbg_next_1(dbg_next[1]),
  .dbg_data_1(dbg_data_1),
  .dbg_capture_2(dbg_capture[2]),
  .dbg_next_2(dbg_next[2]),
  .dbg_data_2(dbg_data_2),
  .dbg_capture_3(dbg_capture[3]),
  .dbg_next_3(dbg_next[3]),
  .dbg_data_3(dbg_data_3),
  .dbg_capture_4(dbg_capture[4]),
  .dbg_next_4(dbg_next[4]),
  .dbg_data_4(dbg_data_4),
  .dbg_capture_5(dbg_capture[5]),
  .dbg_next_5(dbg_next[5]),
  .dbg_data_5(dbg_data_5),
  .dbg_capture_6(dbg_capture[6]),
  .dbg_next_6(dbg_next[6]),
  .dbg_data_6(dbg_data_6),
  .dbg_capture_7(dbg_capture[7]),
  .dbg_next_7(dbg_next[7]),
  .dbg_data_7(dbg_data_7),
  .dbg_capture_8(dbg_capture[8]),
  .dbg_next_8(dbg_next[8]),
  .dbg_data_8(dbg_data_8)
);

endmodule
