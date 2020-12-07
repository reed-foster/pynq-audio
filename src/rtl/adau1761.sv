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
  input [15:0]  harmonicity,
  input [15:0]  mod_index,
  // debug
  input   dbg_capture_0,
  input   dbg_next_0,
  output [23:0] dbg_data_0,
  input   dbg_capture_1,
  input   dbg_next_1,
  output [23:0] dbg_data_1,
  input   dbg_capture_2,
  input   dbg_next_2,
  output [23:0] dbg_data_2,
  input   dbg_capture_3,
  input   dbg_next_3,
  output [23:0] dbg_data_3,
  input   dbg_capture_4,
  input   dbg_next_4,
  output [23:0] dbg_data_4,
  input   dbg_capture_5,
  input   dbg_next_5,
  output [23:0] dbg_data_5,
  input   dbg_capture_6,
  input   dbg_next_6,
  output [23:0] dbg_data_6,
  input   dbg_capture_7,
  input   dbg_next_7,
  output [23:0] dbg_data_7,
  input   dbg_capture_8,
  input   dbg_next_8,
  output [23:0] dbg_data_8
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
Axis_If #(.DWIDTH(24)) signal_out();
Axis_If #(.DWIDTH(24)) signal_in();
Axis_If #(.DWIDTH(24)) pitch();

logic [23:0] fundamental;

assign pitch.ready = 1'b1;
always @(posedge clk) begin
  if (reset) begin
    fundamental <= '0;
  end else begin
    if (pitch.valid) begin
      fundamental <= pitch.data;
    end
  end
end

assign dac_sample.data[47:24] = signal_out.data;
assign dac_sample.data[23:0] = signal_out.data;
assign dac_sample.valid = signal_out.valid;
assign signal_out.ready = dac_sample.ready;

assign signal_in.data = adc_sample.data[23:0];
assign signal_in.valid = adc_sample.valid;
assign adc_sample.ready = 1'b1;

pitch_detect pdet_0 (
  .clk,
  .reset,
  .input_signal(signal_in),
  .pitch,
  .dbg_capture_0,
  .dbg_next_0,
  .dbg_data_0,
  .dbg_capture_1,
  .dbg_next_1,
  .dbg_data_1,
  .dbg_capture_2,
  .dbg_next_2,
  .dbg_data_2,
  .dbg_capture_3,
  .dbg_next_3,
  .dbg_data_3,
  .dbg_capture_4,
  .dbg_next_4,
  .dbg_data_4,
  .dbg_capture_5,
  .dbg_next_5,
  .dbg_data_5,
  .dbg_capture_6,
  .dbg_next_6,
  .dbg_data_6,
  .dbg_capture_7,
  .dbg_next_7,
  .dbg_data_7,
  .dbg_capture_8,
  .dbg_next_8,
  .dbg_data_8
);

fm fm_synth_0 (
  .clk,
  .reset,
  .fundamental,
  .harmonicity,
  .mod_index,
  .signal_out
);

endmodule
