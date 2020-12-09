// sample_buffer.sv - Reed Foster
// buffer to overlap input samples
// assumes 1024-point buffer

module sample_buffer (
  input wire clk, reset,
  Axis_If.Slave din,
  Axis_If.Master dout
);

logic [9:0] read_addr, read_stop, write_addr, write_stop, window_addr;
logic [9:0] read_next, write_next;

assign read_next = read_addr + 1'b1;
assign write_next = write_addr + 1'b1;

logic write_ok = 1'b1; // inverted full/empty flags
logic read_ok = 1'b0;

logic write_enable;
assign write_enable = din.valid && din.ready;
assign din.ready = write_ok;

logic [6:0] dout_valid = '0;
integer i;
always @(posedge clk) begin
  for (i = 1; i < 7; i++) begin
    dout_valid[i] <= dout_valid[i-1];
  end
  dout_valid[0] <= read_ok;
end

assign dout.valid = dout_valid[6];

always @(posedge clk) begin
  if (reset) begin
    read_addr <= '0;
    write_addr <= '0;
    window_addr <= '0;
    read_stop <= '0;
    write_stop <= '0;
    write_ok <= 1'b1;
    read_ok <= 1'b0;
  end else begin
    if (write_enable) begin
      if (write_ok) begin
        write_addr <= write_addr + 1'b1;
        if (write_next == write_stop) begin
          write_stop <= write_next + 512;
          write_ok <= 1'b0;
          read_ok <= 1'b1;
        end
      end
    end
    if (dout.ready) begin
      if (read_ok) begin
        window_addr <= window_addr + 1'b1;
        if (read_next == read_stop) begin
          read_stop <= read_stop + 512;
          read_addr <= read_stop + 512;
          write_ok <= 1'b1;
          read_ok <= 1'b0;
        end else begin
          read_addr <= read_next;
        end
        if (read_next == write_addr) begin
          read_ok <= 1'b0;
          write_ok <= 1'b1;
        end
      end
    end
  end
end

// 1024-point buffer memory
logic [23:0] buffer_out;
blk_mem_gen_0 mem (
  .clka(clk),
  .addra(write_addr),
  .dina(din.data),
  .wea(write_enable && write_ok),
  .clkb(clk),
  .addrb(read_addr),
  .doutb(buffer_out)
);

logic [15:0] window_data;

blk_mem_gen_2 window_mem ( // 2 cycle latency
  .clka(clk),
  .addra(window_addr),
  .douta(window_data)
);

logic [47:0] product;
assign dout.data = product[39:16];
xbip_dsp48_macro_0 mpy_window ( // 4 cycle latency
  .clk,
  .A(buffer_out),
  .B({2'b0, window_data}),
  .C('0),
  .P(product)
);

endmodule
