# pynq-audio

RTL and python for using the audio codec with Pynq

## `src/rtl`
rtl design for i2s controller

- `adau1761.sv` toplevel of DSP chain with I2S interface to audio codec
- `adau1761_wrapper.v` verilog wrapper to allow for use of `adau1761.sv` in vivado block diagram
- `axis.sv` AXI stream interface
- `dsp.sv` AXI stream digital signal chain
- `i2s_serdes.sv` AXI stream <-> I2S serdes
- `rising_edge.sv` synchronizer and rising edge detector for slow signals (used for `bclk` and `lrclk` by `i2s_serdes`)

## `src/python`
pynq python code for initializing codec with AXI_IIC ip

## `src/test`
PRBS checker for i2s controller

## `src/model`
some C code for experimenting with LFSR design

