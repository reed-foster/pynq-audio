// adau1761.sv - Reed Foster
// top level ADAU1761 audio codec controller

module adau1761 (
  input wire clk, reset,
  input enabled,
  // i2s interface
  input         sdata_i,
  output        sdata_o,
  input         bclk,  // bit clock
  input         lrclk // left-right clock
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

// drive with square wave
logic [$clog2(48_000*100_000_000/3000)-1:0] clock_div_count;
logic [23:0] signal = 24'h800000;

assign dac_sample.data[47:24] = signal;
assign dac_sample.data[23:0] = signal;
assign dac_sample.valid = 1'b1;
assign adc_sample.ready = 1'b1;

always @(posedge clk) begin
  if (reset) begin
    clock_div_count <= '0;
    signal <= 24'h800000;
  end else begin
    clock_div_count <= clock_div_count + 1'b1;
    if (clock_div_count > 48_000*100_000_000/3000) begin
      clock_div_count <= '0;
      signal <= ~signal;
    end
  end
end

endmodule
