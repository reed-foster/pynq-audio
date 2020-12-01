// fundamental_bin_finder.sv - Reed Foster
// finds the fundamental bin
// currently only using harmonic product spectrum - may upgrade in the future
// to include peakiness and amplitude threshold tonality measures

module fundamental_bin_finder (
  input wire clk, reset,
  Axis_If.Slave fft_mag,
  Axis_If.Master dout
);

// always accept data from fft
assign fft_mag.ready = 1'b1;

// fork fft_mag data
Axis_If #(.DWIDTH(24)) hps_i_din ();
Axis_If #(.DWIDTH(48)) hps_i_dout ();
Axis_If #(.DWIDTH(48)) hps_i_max ();

assign hps_i_din.data = fft_mag.data[35:12];
assign hps_i_din.valid = fft_mag.valid;

harmonic_product_spectrum hps_i (
  .clk,
  .reset,
  .din(hps_i_din),
  .dout(hps_i_dout),
  .max(hps_i_max)
);

// always accept data from hps module
assign hps_i_dout.ready = 1'b1;
assign hps_i_max.ready = 1'b1;

// hold all hps and mag values for determining maxk
logic [47:0] mag_ram [32];
logic [47:0] hps_ram [32];
logic [9:0] mag_count;
logic [5:0] hps_count;
logic [47:0] mag_max, hps_max;
logic mag_max_valid, hps_max_valid;

logic [5:0] bin_count;
logic [4:0] maxk;
logic maxk_valid;
logic done;

always @(posedge clk) begin
  if (reset) begin
    mag_count     <= '0;
    hps_count     <= '0;
    mag_max       <= '0;
    hps_max       <= '0;
    mag_max_valid <= 1'b0;
    hps_max_valid <= 1'b0;
    done          <= 1'b0;
  end else begin
    if (fft_mag.valid) begin
      mag_count <= mag_count + 1'b1;
      // since we only care about first 32 bins, reset everything after a new frame finishes arriving
      if (mag_count == 10'h3ff) begin
        mag_max_valid <= 1'b0;
        hps_max_valid <= 1'b0;
        mag_count     <= '0;
        hps_count     <= '0;
        mag_max       <= '0;
        hps_max       <= '0;
        done          <= 1'b0;
      end else if (mag_count <= 6'h1f) begin
        // store magnitude data in buffer
        mag_ram[mag_count[4:0]] <= fft_mag.data;
        mag_count <= mag_count + 1'b1;
        if (fft_mag.data > mag_max) begin
          mag_max <= fft_mag.data;
        end
      end else begin
        mag_max_valid <= 1'b1;
      end
    end
    // store hps data in buffer
    if (hps_i_dout.valid) begin
      if (hps_count <= 6'h1f) begin
        hps_ram[hps_count[4:0]] <= hps_i_dout.data;
        hps_count <= hps_count + 1'b1;
      end
    end
    if (hps_i_max.valid) begin
      hps_max <= hps_i_max.data;
      hps_max_valid <= 1'b1;
    end
  end
end

always @(posedge clk) begin
  if (reset) begin
    bin_count   <= '0;
    maxk        <= '0;
    maxk_valid  <= 1'b0;
  end else if (!done) begin
    if (!maxk_valid) begin
      if (hps_max_valid && mag_max_valid) begin
        if (bin_count == 6'h1f) begin
          maxk_valid <= 1'b1; // no bins met the peak criteria; give up and return bin 0
        end else begin
          bin_count <= bin_count + 1'b1;
          if (bin_count >= 2) begin
            if (hps_ram[bin_count-2] >= (hps_max >> 9)) begin
              if (mag_ram[bin_count] > (mag_max >> 4)) begin
                // take the first bin which has a large enough magnitude
                maxk <= bin_count[4:0];
                maxk_valid <= 1'b1;
              end
            end
          end
        end
      end
    end else if (maxk_valid) begin // only pulse maxkvalid for 1 cycle
      maxk_valid <= 1'b0;
      bin_count <= '0;
      done <= 1'b1;
    end
  end
end

// get the maximum magnitude bin within 2 of the bin maxk
logic [4:0] left_bin, right_bin;
logic finding_max_mag;
logic [47:0] max;
logic [4:0] max_bin;
logic max_bin_valid;

assign dout.data = {5'b0, max_bin};
assign dout.valid = max_bin_valid;

always @(posedge clk) begin
  if (reset) begin
    left_bin  <= '0;
    right_bin <= '0;
    finding_max_mag <= 1'b0;
    max <= '0;
    max_bin_valid <= 1'b0;
  end else begin
    // if the peak bin is valid, start finding bin with max mag between peak-2 and peak + 2 (inclusive)
    if (maxk_valid) begin
      left_bin <= (maxk < 2) ? '0 : maxk - 2;
      right_bin <= (maxk > 29) ? 5'h1f : maxk + 2;
      finding_max_mag <= 1'b1;
    end else if (finding_max_mag) begin
      if (left_bin < right_bin) begin
        left_bin <= left_bin + 1'b1;
      end else if (left_bin == right_bin) begin
        max_bin_valid <= 1'b1;
      end
      if (mag_ram[left_bin] > max) begin
        max <= mag_ram[left_bin];
        max_bin <= left_bin;
      end
    end
    if (max_bin_valid && dout.ready) begin
      max_bin_valid <= '0;
      left_bin <= '0;
      right_bin <= '0;
      finding_max_mag <= '0;
      max <= '0;
    end
  end
end

endmodule
