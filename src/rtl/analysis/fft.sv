// fft.sv - Reed Foster
// 1024-point xfft IP wrapper

module fft (
  input wire clk, reset,
  Axis_If.Slave din,
  Axis_If.Master dout
);

// 3-bit pad, 20-bit scale schedule, 1 bit fwd/inv
localparam logic [23:0] config_data = {3'b0, 20'b0101_0101_0101_0101_0110, 1'b1};

logic din_tlast;
logic [9:0] sample_count;
assign din_tlast = sample_count == 10'b1111111111;

always @(posedge clk) begin
  if (reset) begin
    sample_count <= '0;
  end else begin
    if (din.ready && din.valid) begin
      sample_count <= sample_count + 1'b1;
    end
  end
end

// 1024-point, 100MHz, Radix-2 Burst I/O, fixed point scaled
// 24-bit data, 24-bit phase
xfft_0 xfft_i (
  .aclk(clk),
  .s_axis_data_tdata({24'b0, din.data}),
  .s_axis_data_tlast(din_tlast),
  .s_axis_data_tready(din.ready),
  .s_axis_data_tvalid(din.valid),
  .s_axis_config_tdata(config_data),
  .s_axis_config_tready(),
  .s_axis_config_tvalid(1'b1),
  .m_axis_data_tdata(dout.data),
  .m_axis_data_tlast(),
  .m_axis_data_tready(dout.ready),
  .m_axis_data_tvalid(dout.valid),
  .event_frame_started(),
  .event_tlast_unexpected(),
  .event_tlast_missing(),
  .event_status_channel_halt(),
  .event_data_in_channel_halt(),
  .event_data_out_channel_halt()
);

endmodule
