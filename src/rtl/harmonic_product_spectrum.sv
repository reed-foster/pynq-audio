// harmonic_product_spectrum.sv - Reed Foster
// computes a modified HPS to help determine the bin of the fundamental
// modified to only include bins [2,33]

module harmonic_product_spectrum (
  input wire clk, reset,
  Axis_If.Slave din,
  Axis_If.Master dout
);

// only need 32 hps bins
logic [23:0] saved_bins_full [32]; // [bin 2, 3, 4, ... 33]
logic [23:0] saved_bins_downsampled [32]; // [bin 4, 6, 8, ... 66]

logic [9:0] input_count;
logic [4:0] output_count;
logic bins_valid;
logic done;

always @(posedge clk) begin
  if (reset) begin
    input_count <= '0;
    output_count <= '0;
    bins_valid <= 1'b0;
    din.ready <= 1'b1;
    dout.valid <= 1'b0;
    done <= '0;
  end else begin
    if (din.valid && din.ready) begin
      input_count <= input_count + 1'b1;
      // save bins into buffers
      if (input_count >= 2 && input_count <= 33) begin
        saved_bins_full[input_count-2] <= din.data;
      end
      if (input_count[0] == 0 && input_count >= 4 && input_count <= 66) begin
        saved_bins_downsampled[(input_count >> 1) - 2] <= din.data;
      end
      // done reading bins into buffers
      if (input_count == 66) begin
        bins_valid <= 1'b1;
      end else if (input_count == 10'h3ff && !done) begin
        din.ready <= 1'b0; // stall input until finished
      end
    end
    if (dout.ready && bins_valid) begin
      dout.data <= saved_bins_full[output_count]*saved_bins_downsampled[output_count];
      dout.valid <= 1'b1;
      output_count <= output_count + 1'b1;
      if (output_count == 5'h1f) begin
        bins_valid <= 1'b0;
        done <= 1'b1;
        din.ready <= 1'b1;
      end
    end
    if (!bins_valid && output_count == 0) begin
      // on the cycle after 32nd bin is clocked out, deassert valid
      dout.valid <= 1'b0;
    end
  end
end

endmodule
