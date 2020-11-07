// i2s_serdes.sv - Reed Foster
// i2s serializer/deserializer for ADAU1761 data interface

module i2s_serdes #(
  parameter int BIT_DEPTH = 24
)(
  input wire clk, reset,
  input enabled,
  // i2s interface
  input         sdata_i,
  output logic  sdata_o,
  input         bclk,  // bit clock        (3.072MHz)
  input         lrclk, // left-right clock (48kHz)
  // i/o dsp stream interfaces
  Axis_If.Slave   dac_sample,
  Axis_If.Master  adc_sample
);

logic bclk_r, bclk_f, lrclk_r, lrclk_f;
rising_edge #(.PRE_FF_COUNT(1)) bclk_rising_edge_det (
  .clk,
  .in(bclk),
  .rising_edge(bclk_r),
  .falling_edge(bclk_f)
);

// delay lrclk detector by a cycle to prevent erroneous triggering of bclk
// events immediately after lrclk falling/rising edge
rising_edge #(.PRE_FF_COUNT(2)) lrclk_rising_edge_det (
  .clk,
  .in(lrclk),
  .rising_edge(lrclk_r),
  .falling_edge(lrclk_f)
);

// shift registers
logic [$clog2(BIT_DEPTH)-1:0] bit_counter = '0;
logic [2*BIT_DEPTH-1:0] shift_reg_in; // store two channels per sample
logic [2*BIT_DEPTH-1:0] shift_reg_out;
assign sdata_o = shift_reg_out[2*BIT_DEPTH-1];

// axi buffers
logic dac_sample_ready = 1'b1;
logic adc_sample_valid = 1'b0;
logic [47:0] dac_sample_data, adc_sample_data;

assign dac_sample.ready = dac_sample_ready;
assign adc_sample.valid = adc_sample_valid;
assign adc_sample.data = adc_sample_data;

// handle ready-valid logic, shift registers, and bit counter
always @(posedge clk) begin
  if (reset) begin
    bit_counter <= '0;
    shift_reg_in <= '0;
    shift_reg_out <= '0;
    dac_sample_data <= '0;
    adc_sample_data <= '0;
  end else if (enabled) begin
    // ready_valid logic
    if (dac_sample.ready && dac_sample.valid) begin
      dac_sample_ready <= 1'b0;
      dac_sample_data <= dac_sample.data;
    end
    if (adc_sample.ready && adc_sample.valid) begin
      adc_sample_valid <= 1'b0;
    end
    // update bit counter
    if (lrclk_r || lrclk_f) begin
      bit_counter <= '0;
    end else if (bclk_r) begin
      bit_counter <= bit_counter + 1'b1;
    end
    // handle shift registers
    if (lrclk_f) begin
      // load in dac_sample_data
      shift_reg_out <= dac_sample_data;
      dac_sample_ready <= 1'b1;
      // load out adc_sample_data
      adc_sample_data <= shift_reg_in;
      adc_sample_valid <= 1'b1;
    end else begin
      if (bclk_r && (bit_counter > 0 && bit_counter < 25)) begin
        shift_reg_in <= {shift_reg_in[2*BIT_DEPTH-2:0], sdata_i};
      end
      if (bclk_f && (bit_counter > 1 && bit_counter < 26)) begin
        shift_reg_out <= {shift_reg_out[2*BIT_DEPTH-2:0], 1'b0};
      end
    end
  end
end
endmodule
