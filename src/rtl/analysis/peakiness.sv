// peakiness.sv - Reed Foster
// gives tonal measure of peakiness

module peakiness (
  input wire clk, reset,
  Axis_If.Slave din,
  Axis_If.Master dout
);

logic [23:0] din_prev [5];
logic [24:0] numerator;
logic numerator_valid [5];

always @(posedge clk) begin
  if (din.valid) begin
    for (genvar i = 1; i < 5; i += 1) begin
      din_prev[i] <= din_prev[i-1];
      numerator_valid[i] <= numerator_valid[i-1]; // ? I don't think this is right
    end
    din_prev[0] <= din.data;
  end
  numerator <= din_prev[0] + din_prev[4];
  denominator <= din_prev[2];
  numerator_valid <= din.valid

div_gen_0 divider (
  // 25 bit dividend
  // 24 bit divisor
  // 25.2 bit quotient
  .aclk(clk),
  .s_axis_divisor_tdata(numerator),
  .s_axis_divisor_tready(),
  .s_axis_divisor_tvalid(),
  .s_axis_dividend_tdata(denominator),
  .s_axis_dividend_tready(),
  .s_axis_dividend_tvalid(),
  .m_axis_dout_tdata(),
  .m_axis_dout_tready(),
  .m_axis_dout_tvalid()
);

endmodule
