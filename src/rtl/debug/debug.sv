// debug.sv - Reed Foster
// low-performance janky "logic analyzer"

module debug #(
  parameter int DWIDTH = 24
) (
  input wire clk, reset,
  input data_in_valid,
  input [DWIDTH-1:0] data_in,
  output [DWIDTH-1:0] data_out,
  // debug control
  input capture, // trigger recording of signal on the rising edge
  input next // updates the read address on rising edge
);

logic [11:0] write_addr, read_addr;
logic next_d;
logic capture_d;
logic we;
always @(posedge clk) begin
  next_d <= next;
  capture_d <= capture;
  if (reset) begin
    we <= 1'b0;
    write_addr <= '0;
    read_addr <= '0;
  end else begin
    if (capture && !capture_d) begin
      we <= 1'b1;
      write_addr <= '0;
      read_addr <= '0;
    end
    if (we) begin
      if (data_in_valid) begin
        write_addr <= write_addr + 1'b1;
        if (write_addr == 12'hfff) begin
          we <= 1'b0;
        end
      end
    end
    if (next && !next_d) begin
      read_addr <= read_addr + 1'b1;
    end
  end
end

blk_mem_gen_1 buffer (
  .clka(clk),
  .clkb(clk),
  .addra(write_addr),
  .addrb(read_addr),
  .dina(data_in),
  .wea(we),
  .doutb(data_out)
);

endmodule
