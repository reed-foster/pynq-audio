// sample_buffer.sv - Reed Foster
// buffer to overlap input samples
// assumes 1024-point buffer

module sample_buffer (
  input wire clk, reset,
  Axis_If.Slave din,
  Axis_If.Slave dout
);

logic increment_read = 0;
// blockram has two-cycle read latency
logic increment_read_d;
always @(posedge clk) begin
  increment_read_d <= increment_read;
  dout.valid <= increment_read_d; // delay to match bram latency
end

logic shift_frame; // asserted for one cycle to shift read frame by 512 samples

logic [9:0] read_addr = '0;
logic [9:0] read_addr_next;
logic [9:0] write_addr = '0;
logic [9:0] write_addr_next;

assign read_addr_next = read_addr + 1'b1;
assign write_addr_next = write_addr + 1'b1;

logic write_enable;
assign write_enable = din.valid && din.ready;
assign din.ready = !increment_read; // if we're not incrementing read, then ready for data in

always @(posedge clk) begin
  if (reset) begin
    read_addr <= '0;
    write_addr <= '0;
    increment_read <= 1'b0;
    shift_frame <= 1'b0;
  end else begin
    // currently writing
    if (!increment_read) begin
      // normal behavior: update write address
      if (write_enable) begin
        write_addr <= write_addr_next;
      end
      // if we've got 1024 samples ready to read, switch to reading
      if (write_addr_next == read_addr) begin
        increment_read <= 1'b1;
      end
    end
    // currently reading
    else if (increment_read) begin
      // if we've read all 1024 samples
      if (read_addr_next == write_addr) begin
        increment_read <= 1'b0;
        shift_frame <= 1'b1;
        read_addr <= read_addr_next; // increment, then shift by half-frame next cycle
      // normal behavior: update read address
      end else if (dout.ready) begin // only update when output stream is ready
        read_addr <= read_addr_next;
      end
    end
    if (shift_frame) begin
      read_addr <= read_addr + 512;
      shift_frame <= 1'b0;
    end
  end
end

// 1024-point buffer memory
blk_mem_gen_0 mem (
  .clka(clk),
  .addra(write_addr),
  .dina(din.data),
  .wea(write_enable),
  .clkb(clk),
  .addrb(read_addr),
  .doutb(dout.data)
);

endmodule
