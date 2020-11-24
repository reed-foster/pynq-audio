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
  
  // come out of reset
  reset = 0;
  signal_out.ready = 1;
  
  // set up fundamental at 512 Hz and set harmonicity and modulation index
  fundamental = {14'b00000100000000, 10'b0}; // 512 Hz
  harmonicity = {3'b001, 13'b0}; // harmonicity 1
  mod_index = {7'b0000100, 9'b0}; // mod index of 4
  repeat (1_000_000) @(posedge clk); // 10 ms

  // after a few periods of first signal, change modulation index
  mod_index = {7'b0100000, 9'b0}; // mod index of 32
  repeat (1_000_000) @(posedge clk); // 10 ms

  // after a few periods, change modulation index and harmonicity
  mod_index = {7'b0001000, 9'b0}; // mod index of 8
  harmonicity = {3'b010, 13'b0}; // harmonicity of 2
  repeat (1_000_000) @(posedge clk); // 10 ms
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
