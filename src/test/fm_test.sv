// fm_test.sv - Reed Foster
// test for fm synthesizer

module fm_test ();

Axis_If #(.DWIDTH(24)) signal_out();

localparam CLK_RATE_HZ = 100_000_000;

logic clk = 0;
always #(0.5s/CLK_RATE_HZ) clk = ~clk;
logic reset = 0;
logic [23:0] fundamental;
logic [15:0] harmonicity;
logic [15:0] mod_index;

initial begin
  reset = 1;
  fundamental = '0;
  harmonicity = '0;
  mod_index = '0;
  repeat (500) @(posedge clk);
  reset = 0;
  signal_out.ready = 1;
  fundamental = {14'b00000100000000, 10'b0}; // 512 Hz
  repeat (1_000_000) @(posedge clk); // 0.01 seconds
  harmonicity = {3'b001, 13'b0}; // harmonicity 1
  mod_index = {7'b0100000, 9'b0}; // mod index of 64
  repeat (1_000_000) @(posedge clk); // 0.01 seconds
  mod_index = '1; // mod index of ~256
  repeat (1_000_000) @(posedge clk); // 0.01 seconds
  mod_index = {7'b0100000, 9'b0}; // mod index of 64
  harmonicity = {3'b010, 13'b0}; // harmonicity of 2
  repeat (1_000_000) @(posedge clk); // 0.01 seconds
  $finish;
end

fm dut_i (
  .clk,
  .reset,
  .fundamental,
  .harmonicity,
  .mod_index,
  .signal_out
);

endmodule
