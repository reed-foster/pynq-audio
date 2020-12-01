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
assign product = saved_bins_full[output_count]*saved_bins_downsampled[output_count];

always @(posedge clk) begin
  if (reset) begin
    input_count <= '0;
    output_count <= '0;
    bins_valid <= 1'b0;
    dout.valid <= 1'b0;
    max.valid <= 1'b0;
    max.data <= '0;
  end else begin
    // save data into buffers
    if (din.valid && din.ready) begin
      if (input_count == 10'h3ff) begin
        // reset counters
        input_count <= '0;
        output_count <= '0;
        bins_valid <= 1'b0;
        max.data <= '0;
        max.valid <= '0;
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
      if (output_count <= 6'h1f) begin
        output_count <= output_count + 1'b1;
        dout.data <= product;
        dout.valid <= 1'b1;
        if (product > max.data) begin
          max.data <= product;
        end
        if (output_count == 6'h1f) begin
          // max.data is now valid
          max.valid <= 1'b1;
        end
      end else begin
        // finished reading out all 32 products
        dout.valid <= 1'b0;
        bins_valid <= 1'b0;
      end
    end
    if (max.valid && max.ready) begin
      max.valid <= 1'b0;
    end
  end
end

endmodule
