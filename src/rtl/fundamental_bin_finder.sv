// fundamental_bin_finder.sv - Reed Foster
// finds the fundamental bin

module fundamental_bin_finder (
  input wire clk, reset,
  Axis_If.Slave fft_mag,
  Axis_If.Master dout
);

// fork fft_mag data
Axis_If #(.DWIDTH(24)) hps_i_din;
Axis_If #(.DWIDTH(24)) peaks_i_din;
Axis_If #(.DWIDTH(24)) amthresh_i_din;
logic all_ready;
assign all_ready = hps_i_din.ready & peaks_i_din.ready & amthresh_i_din.ready;
assign fft_bins.ready = all_ready;
always @(posedge clk) begin
  hps_i_din.data        <= fft_mag[47:24];
  peaks_i_din.data      <= fft_mag[47:24];
  amthresh_i_din.data   <= fft_mag[47:24];
  hps_i_din.valid       <= fft_mag.valid & all_ready; // only initiate a transfer if all 3 modules are ready for it
  peaks_i_din.valid     <= fft_mag.valid & all_ready;
  amthresh_i_din.valid  <= fft_mag.valid & all_ready;
end

Axis_If #(.DWIDTH(24)) hps_i_dout;
harmonic_product_spectrum hps_i (
  .clk,
  .reset,
  .din(hps_i_din),
  .dout(hps_i_dout)
);

Axis_If #(.DWIDTH(24)) peaks_i_dout;
peakiness peaks_i (
  .clk,
  .reset,
  .din(peaks_i_din),
  .dout(peaks_i_dout)
);

Axis_If #(.DWIDTH(24)) amthresh_i_dout;
amplitude_threshold amthresh_i (
  .clk,
  .reset,
  .din(amthresh_i_din),
  .dout(amthresh_i_dout)
);

logic salience_hps_valid;
assign salience_hps_valid = hps_i_dout.valid & peaks_i_dout.valid & amthresh_i_dout.valid;
assign hps_i_dout.ready = salience_hps_valid;
assign peaks_i_dout.ready = salience_hps_valid;
assign amthresh_i_dout.ready = salience_hps_valid;

// find max bin
// only look at first 32 bins
// counter for maxk
logic [4:0] bin_count;
// counters for finding max mag and max salience*hps product
logic [4:0] raw_mag_count, salience_count;
logic [4:0] maxk;
logic maxk_valid;
// hold max mag and max salience*hps product
logic [47:0] max_raw_mag;
logic [63:0] max_salience_hps;
logic max_raw_mag_valid, max_salience_hps_valid;
// hold all salience*hps and mag values for determining maxk
logic [47:0] mag_ram [32];
logic [63:0] salience_ram [32];

always @(posedge clk) begin
  if (reset) begin
    bin_count               <= '0;
    raw_mag_count           <= '0; 
    salience_count          <= '0; 
    maxk                    <= '0;
    maxk_valid              <= 1'b0;
    max_raw_mag             <= '0;
    max_salience_hps        <= '0;
    max_raw_mag_valid       <= 1'b0;
    max_salience_hps_valid  <= 1'b0;
  end else begin
    if (!max_raw_mag_valid) begin
      if (fft_mag.valid) begin
        mag_ram[raw_mag_count] <= fft_mag;
        if (fft_mag > max_raw_mag) begin
          max_raw_mag <= fft_mag;
        end
        raw_mag_count <= raw_mag_count + 1'b1;
        if (raw_mag_count == 5'h1f) begin
          max_raw_mag_valid <= 1'b1;
        end
      end
    end else if (!max_salience_hps_valid) begin
      if (salience_hps_valid) begin
        salience_ram[salience_count] <= salience_hps;
        if (salience_hps > max_salience_hps) begin
          max_salience_hps <= salience_hps;
        end
        salience_count <= salience_count + 1'b1;
        if (salience_count == 5'h1f) begin
          max_salience_hps_valid <= 1'b1;
        end
      end
    end else if (!maxk_valid) begin
      // else if chain ensures that max_salience_hps and max_raw_mag are valid
      if (salience_ram[bin_count] < (max_salience_hps >> 10)) begin
        bin_count <= bin_count + 1'b1;
      end else if (mag_ram[bin_count] > (max_raw_mag >> 8)) begin
        maxk <= bin_count;
        maxk_valid <= 1'b1;
      end
    end
  end
end

endmodule
