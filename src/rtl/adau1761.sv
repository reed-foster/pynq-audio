// adau1761.sv - Reed Foster
// top level ADAU1761 audio codec controller

module adau1761 (
  input wire clk, reset,
  // i2s interface
  input         sdata_i,
  output        sdata_o,
  input         bclk,  // bit clock
  input         lrclk, // left-right clock
  output        signal_out
  // mmio control
);

Axis_If #(.DWIDTH(2*24)) dac_sample(); // 48 bits for L/R
Axis_If #(.DWIDTH(2*24)) adc_sample();

i2s_serdes i2s_i (
  .clk,
  .reset,
  .sdata_i,
  .sdata_o,
  .bclk,
  .lrclk,
  .dac_sample,
  .adc_sample
);

logic [$clog2(100_000_000/500)-1:0] clock_div_count;
logic [23:0] signal;
assign signal_out = signal[0];

assign dac_sample.data[47:24] = signal;
assign dac_sample.data[23:0] = signal;
assign dac_sample.valid = 1'b1;
assign adc_sample.ready = 1'b1;

always @(posedge clk) begin
  if (reset) begin
    clock_div_count <= '0;
    signal <= '0;
  end else begin
    clock_div_count <= clock_div_count + 1'b1;
    if (clock_div_count > 100_000_000/500) begin
      clock_div_count <= '0;
      signal <= ~signal;
    end
  end
end

endmodule
