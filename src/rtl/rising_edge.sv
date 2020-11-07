// rising_edge.sv - Reed Foster
// 1 bit FF synchronizer followed by a rising edge detector


module rising_edge #(
  parameter int PRE_FF_COUNT = 1
) (
  input wire clk,
  input  in,
  output rising_edge,
  output falling_edge
);

logic [PRE_FF_COUNT:0] shift_reg;
always @(posedge clk) begin
  shift_reg <= {shift_reg[PRE_FF_COUNT-1:0], in};
end

assign rising_edge = !shift_reg[PRE_FF_COUNT] & shift_reg[PRE_FF_COUNT-1];
assign falling_edge = shift_reg[PRE_FF_COUNT] & !shift_reg[PRE_FF_COUNT-1];

endmodule
