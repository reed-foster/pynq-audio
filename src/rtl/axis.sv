// axis.sv - Reed Foster
// axi-stream interface

interface Axis_If #(
  parameter DWIDTH = 32
);

logic [DWIDTH - 1:0]  data;
logic                 ready;
logic                 valid;

modport Master (
  input   ready,
  output  valid,
  output  data
);

modport Slave (
  output  ready,
  input   valid,
  input   data
);
endinterface;
