// i2c_controller.sv - Reed Foster
// controller for ADAU1761 control interface

module i2c_controller #(
  parameter CLOCK_DIV = 250 // 100MHz/250 = 400kHz
)(
  input wire clk, reset,
  output logic  scl,
  input         sda_i,
  output logic  sda_o,
  output        sda_t
);

enum {
  Idle,
  Start,
  Continue,
  End
} state = Idle;

logic [7:0] clk_div_count = 0;
logic en_clk_div_count = 0;
logic rst_clk_div_count = 0;

always_ff @(posedge clk) begin
  if (reset) begin
    clk_div_count <= '0;
  end else begin
    if (rst_clk_div_count) begin
      clk_div_count <= '0;
    end else if (en_clk_div_count) begin
      clk_div_count <= clk_div_count + 1'b1;
    end
  end
end

always_ff @(posedge clk) begin
  if (reset) begin
    state <= Idle;
  end else begin
    case (state)
      Start: begin
        // set sda_o <= 0, wait tsch, then set scl <= 0
        // tsch > 0.6 us = 60 cyc at 100MHz clk
        if (sda_o == 1'b1) begin
          sda_o <= 1'b0;
          en_clk_div_count <= 1'b1;
        end else if (clk_div_count >= 60) begin
          scl <= 1'b0;
          state <= Continue;
        end
      end
      Continue: begin
         
      end
      End: begin
      end
      default: begin
      end
    endcase
  end
end


endmodule
