// i2s_serdes.sv - Reed Foster
// i2s serializer/deserializer for ADAU1761 data interface

module i2s_serdes (
  input wire clk, reset,
  // i2s interface
  input         sdata_i,
  output logic  sdata_o,
  input         bclk,  // bit clock        (3.072MHz)
  input         lrclk, // left-right clock (48kHz)
  // i/o dsp stream interfaces
  Axis_If.Slave   dac_sample,
  Axis_If.Master  adc_sample
);

logic bclk_last = 0;
logic lrclk_last = 0;
always_ff @(posedge clk) begin
  bclk_last <= bclk; 
  lrclk_last <= lrclk;
end

logic enabled = 0;
logic [4:0] bit_counter = 0; // 5 bits to count up to 32
logic [47:0] shift_reg_in; // 48 bits to hold stereo 24-bit
logic [47:0] shift_reg_out;

// axi buffer
logic dac_sample_ready = 1'b1;
logic adc_sample_valid = 1'b1;
logic [47:0] dac_sample_data, adc_sample_data;

assign dac_sample.ready = dac_sample_ready;
assign adc_sample.valid = adc_sample_valid;

assign adc_sample.data = adc_sample_data;

// handle ready/valid
always_ff @(posedge clk) begin
  if (reset) begin
    dac_sample_ready <= 1'b1;
    adc_sample_valid <= 1'b1;
  end else begin
    if (dac_sample.valid && dac_sample.ready) begin
      dac_sample_ready <= 1'b0;
      dac_sample_data <= dac_sample.data;
    end
    if (adc_sample.valid && adc_sample.ready) begin
      adc_sample_valid <= 1'b0;
    end
    if (lrclk_last == 1'b1 && lrclk == 1'b0) begin
      // on falling edge of lrclk, we're starting a L/R sample pair
      shift_reg_out <= dac_sample_data;
      adc_sample_data <= shift_reg_in;
      dac_sample_ready <= 1'b1;
      adc_sample_valid <= 1'b1;
    end
  end
end

// shifting I2S data
always_ff @(posedge clk) begin
  if (reset) begin
    enabled <= 1b'0;
    bit_counter <= 1b'0;
  end else begin
    if (enabled) begin
      if (bclk_last == 1'b0 && bclk == 1'b1) begin
        // on rising edge, shift serial data in
        bit_counter <= bit_counter + 1'b1;
        if (bit_counter > 0 && bit_counter < 25) begin // for default I2S mode, wait one cycle before transferring MSB
          // shift in ADC data from ADAU1761
          shift_reg_in <= {shift_reg_in[46:0], sdata_i};
        end
      end else if (bclk_last == 1'b1 && bclk == 1'b0) begin
        // on falling edge, shift serial data out
        if (bit_counter > 0 && bit_counter < 25) begin
          // shift out DAC data to ADAU1761
          sdata_o <= shift_reg_out[47];
          shift_reg_out <= {shift_reg_out[46:0], 1'b0};
        end
      end
    end
    if (lrclk_last == 1'b1 && lrclk == 1'b0) begin
      enabled <= 1'b1;
      bit_counter <= '0;
    end
  end
end

endmodule
