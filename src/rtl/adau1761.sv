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
  input         dbg_capture,
  input         dbg_next,
  output [23:0] dbg_data
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

assign signal_in.data = adc_sample.data[23:0];
assign signal_in.valid = adc_sample.valid;
assign adc_sample.ready = 1'b1;

pitch_detect pdet_0 (
  .clk,
  .reset,
  .input_signal(signal_in),
  .pitch,
  .dbg_capture,
  .dbg_next,
  .dbg_data
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
