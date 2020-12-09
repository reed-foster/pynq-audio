// harmonic_product_spectrum.sv - Reed Foster
// computes a modified HPS to help determine the bin of the fundamental
// modified to only include bins [2,33]

module harmonic_product_spectrum (
  input wire clk, reset,
  Axis_If.Slave din,
  Axis_If.Master dout,
  Axis_If.Master max
);

assign din.ready = 1'b1; // assume we'll have a limited amout of backpressure

// only need 32 hps bins
logic [23:0] saved_bins_full [32]; // [bin 2, 3, 4, ... 33]
logic [23:0] saved_bins_downsampled [32]; // [bin 4, 6, 8, ... 66]

logic [9:0] input_count;
logic [5:0] output_count;
logic bins_valid;

logic [47:0] product;
logic [42:0] upper_product, lower_product;
logic [23:0] full_bin, downsampled_bin;

assign dout.data = product;

always @(posedge clk) begin
  full_bin <= saved_bins_full[output_count];
  downsampled_bin <= saved_bins_downsampled[output_count];
  product <= {upper_product, 17'b0} + lower_product;
end

xbip_dsp48_macro_2 upper (
  .clk,
  .A({1'b0, full_bin}),
  .B({11'b0, downsampled_bin[23:17]}),
  .P(upper_product)
);

xbip_dsp48_macro_2 lower (
  .clk,
  .A({1'b0, full_bin}),
  .B({1'b0, downsampled_bin[16:0]}),
  .P(lower_product)
);

logic [5:0] max_valid;
logic [5:0] dout_valid;
assign max.valid = max_valid[5];
assign dout.valid = dout_valid[5];
integer i;
always @(posedge clk) begin
  if (reset) begin
    input_count <= '0;
    output_count <= '0;
    bins_valid <= 1'b0;
    max_valid <= '0;
    dout_valid <= '0;
    max.data <= '0;
  end else begin
    for (i = 1; i < 6; i++) begin
      max_valid[i] <= max_valid[i-1];
      dout_valid[i] <= dout_valid[i-1];
    end
    // save data into buffers
    if (din.valid && din.ready) begin
      if (input_count == 10'h3ff) begin
        // reset counters
        input_count <= '0;
        output_count <= '0;
        bins_valid <= 1'b0;
        max.data <= '0;
        max_valid[0] <= '0;
      end else begin
        input_count <= input_count + 1'b1;
        // save unmodified copy of spectrum
        if (input_count >= 2 && input_count <= 33) begin
          saved_bins_full[input_count-2] <= din.data;
        end
        // save 2x undersampled copy of spectrum
        if (input_count[0] == 0 && input_count >= 4 && input_count <= 66) begin
          saved_bins_downsampled[(input_count >> 1) - 2] <= din.data;
        end
        // done reading bins into buffers
        if (input_count == 66) begin
          bins_valid <= 1'b1;
        end
      end
    end
    // buffers are ready, start calculating products
    if (dout.ready && bins_valid) begin
      if (output_count <= 6'h1f + 5) begin
        output_count <= output_count + 1'b1;
        dout_valid[0] <= 1'b1;
        if (product > max.data) begin
          max.data <= product;
        end
        if (output_count == 6'h1f + 1) begin
          // max.data is now valid
          max_valid[0] <= 1'b1;
        end
      end
      if (output_count > 6'h1f) begin
        // finished reading out all 32 products
        dout_valid[0] <= 1'b0;
        bins_valid <= 1'b0;
      end
    end
    if (max_valid[5] && max.ready) begin
      max_valid <= '0;
    end
  end
end

endmodule
