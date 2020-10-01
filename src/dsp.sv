// dsp.sv - Reed Foster
// dsp chain (just passthrough for now)

module dsp (
  input wire clk, reset,
  Axis_If.Master  dac_sample,
  Axis_If.Slave   adc_sample
);

assign dac_sample.data = adc_sample.data;
assign dac_sample.valid = adc_sample.valid;
assign adc_sample.ready = dac_sample.ready;

endmodule
