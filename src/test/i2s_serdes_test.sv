module i2s_serdes_test ();

Axis_If #(.DWIDTH(48)) dac_sample();
Axis_If #(.DWIDTH(48)) adc_sample();

localparam CLK_RATE_HZ = 50_000_000;
localparam BCLK_RATE_HZ = 64*48_000;
localparam LRCLK_RATE_HZ = 48_000;

logic clk = 0;
logic bclk = 0;
logic lrclk = 0;
always #(0.5s/CLK_RATE_HZ) clk = ~clk;
always #(0.5s/BCLK_RATE_HZ) bclk = ~bclk;
always #(0.5s/LRCLK_RATE_HZ) lrclk = ~lrclk;

logic reset;
initial begin
  reset = 1;
  repeat (500) @(posedge clk);
  reset = 0;
  dac_sample.valid = 1;
  adc_sample.ready = 1;
end

// LFSR stuff for PRBS
// definitely not maximal, has a period of 54M. it's good enough though
localparam [47:0] LFSR_POLY = 48'h3A00_0050_0000;
logic [47:0] input_lfsr = 48'hB82E_DC58_BFFB; // just an arbitrary seed that's part of the 54M cycle
logic [47:0] output_lfsr = input_lfsr; // what we expect

// function to actually perform LFSR
function automatic logic[47:0] apply_lfsr(input logic[47:0] lfsr);
  return {^(lfsr & LFSR_POLY), lfsr[47:1]};
endfunction

assign dac_sample.data = input_lfsr;

int mismatch_count = 0;
int total_count = 0;

logic enabled = 0, enabled_d = 0, enabled_dd = 0;
logic lrclk_last = 0;
logic bclk_last = 0;
always_ff @(posedge clk) begin
  lrclk_last <= lrclk;
  bclk_last <= bclk;
  enabled_dd <= enabled_d;
  if (lrclk_last & (!lrclk)) begin
    enabled <= 1'b1;
    enabled_d <= enabled;
  end
end

always_ff @(posedge clk) begin
  if (!reset & enabled) begin
    if (dac_sample.ready) begin
      // send a new sample
      input_lfsr <= apply_lfsr(input_lfsr);
    end
    if (enabled_dd & adc_sample.valid) begin // wait for one lrclk cycle before checking data
      // compare output lfsr
      if (adc_sample.data !== output_lfsr) begin
        $display("mismatched data: expected %h, got %h", output_lfsr, adc_sample.data);
        mismatch_count <= mismatch_count + 1;
      end
      output_lfsr <= apply_lfsr(adc_sample.data);
      total_count <= total_count + 1;
    end
  end
end

logic [6:0] count = 0;
logic gate = 0;
always @(posedge clk) begin
  if (reset) begin
    count <= '0;
  end else begin
    if (lrclk_last != lrclk) begin
      count <= '0;
    end else if (bclk_last == 1'b0 && bclk == 1'b1) begin
      count <= count + 1'b1;
    end
    if (bclk_last == 1'b1 && bclk == 1'b0 && count >= 23) begin
      gate <= 1'b0;
    end else if (count <= 23) begin
      gate <= 1'b1;
    end
  end
end
logic bclk_gated;
assign bclk_gated = bclk & gate;

logic sdata;

i2s_serdes dut_i (
  .clk,
  .reset,
  .sdata_i(sdata),
  .sdata_o(sdata),
  .bclk(bclk_gated),
  .lrclk,
  .dac_sample,
  .adc_sample
);

initial begin
  while (total_count < 50) @(posedge clk);
  $finish;
end

endmodule
