# pynq-audio

RTL and python for using the audio codec with Pynq.
Additional audio DSP project to demonstrate functionality:
- Synthesis - slightly janky fixed-point FM synthesizer (still have some scaling issues; may need to change to floating point)
- Analysis - spectral-based pitch detection. For now, uses a modified harmonic product spectrum and phase vocoder

## `src/rtl`

#### rtl design for i2s controller

- `adau1761.sv` toplevel of DSP chain with I2S interface to audio codec
- `adau1761_wrapper.v` verilog wrapper to allow for use of `adau1761.sv` in vivado block diagram
- `axis.sv` AXI stream interface
- `dsp.sv` AXI stream digital signal chain
- `i2s_serdes.sv` AXI stream <-> I2S serdes
- `rising_edge.sv` synchronizer and rising edge detector for slow signals (used for `bclk` and `lrclk` by `i2s_serdes`)

#### rtl design for the rest of the project

###### synthesis
- `wavetable.sv` sine-wave generator (uses CORDIC to save memory and keep high resolution audio signal)
- `fm.sv` fm tone generator for use in a synth (uses multiple sine-wave generators)

###### analysis
- `fft.sv` wrapper for 1024-point XFFT IP
- `fundamental_bin_finder.sv` estimates the fundamental frequency of DFT data using harmonic product spectrum (plans to use tonal estimates as well to improve estimate)
- `harmonic_product_spectrum.sv` computes a modified harmonic product spectrum of DFT data
- `pitch_detect.sv` combines fundamental detection with a phase vocoder to estimate the pitch of a windowed frame of time-series data
- `sample_buffer.sv` overlapping FIFO which overlaps input frames (planned to also apply a windowing function)

## `src/python`
pynq python code for initializing codec with AXI_IIC ip

## `src/test`
PRBS checker for i2s controller
Testbenches for other modules (I don't think any are automated yet; I just wrote these to generate waveforms and see if the design was behaving as I expected)

## `src/model`
some C code for experimenting with LFSR design
would be useful to add some fixed point and bit-accurate models for the analysis modules, but I don't have enough time before this project is due.

