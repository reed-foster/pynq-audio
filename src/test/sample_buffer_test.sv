// sample_buffer_test.sv - Reed Foster
// testbench for sample buffer

module sample_buffer_test ();

Axis_If #(.DWIDTH(24)) din();
Axis_If #(.DWIDTH(24)) dout();

localparam CLK_RATE_HZ = 100_000_000;

logic clk = 0;
always #(0.5s/CLK_RATE_HZ) clk = ~clk;
logic reset = 0;

assign dout.ready = 1'b1;
assign din.valid = 1'b1;

always @(posedge clk) begin
  if (reset) begin
    din.data <= '0;
  end else if (din.valid && din.ready) begin
    din.data <= din.data + 1'b1;
  end
end

initial begin
  reset <= 1;
  repeat (500) @(negedge clk);
  reset <= 0;
  repeat (10000) @(posedge clk);
  $finish;
end

sample_buffer dut_i (
  .clk,
  .reset,
  .din,
  .dout
);

endmodule
