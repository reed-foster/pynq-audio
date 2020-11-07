from pynq import Overlay
ol = Overlay("overlay.bit")
ol.download()

IIC_ADDR = 0x3b
R0_CLOCK_CONTROL                                = 0x00
R1_PLL_CONTROL                                  = 0x02
R2_DIGITAL_MIC_JACK_DETECTION_CONTROL           = 0x08
R3_RECORD_POWER_MANAGEMENT                      = 0x09
R4_RECORD_MIXER_LEFT_CONTROL_0                  = 0x0A
R5_RECORD_MIXER_LEFT_CONTROL_1                  = 0x0B
R6_RECORD_MIXER_RIGHT_CONTROL_0                 = 0x0C
R7_RECORD_MIXER_RIGHT_CONTROL_1                 = 0x0D
R8_LEFT_DIFFERENTIAL_INPUT_VOLUME_CONTROL       = 0x0E
R9_RIGHT_DIFFERENTIAL_INPUT_VOLUME_CONTROL      = 0x0F
R10_RECORD_MICROPHONE_BIAS_CONTROL              = 0x10
R11_ALC_CONTROL_0                               = 0x11
R12_ALC_CONTROL_1                               = 0x12
R13_ALC_CONTROL_2                               = 0x13
R14_ALC_CONTROL_3                               = 0x14
R15_SERIAL_PORT_CONTROL_0                       = 0x15
R16_SERIAL_PORT_CONTROL_1                       = 0x16
R17_CONVERTER_CONTROL_0                         = 0x17
R18_CONVERTER_CONTROL_1                         = 0x18
R19_ADC_CONTROL                                 = 0x19
R20_LEFT_INPUT_DIGITAL_VOLUME                   = 0x1A
R21_RIGHT_INPUT_DIGITAL_VOLUME                  = 0x1B
R22_PLAYBACK_MIXER_LEFT_CONTROL_0               = 0x1C
R23_PLAYBACK_MIXER_LEFT_CONTROL_1               = 0x1D
R24_PLAYBACK_MIXER_RIGHT_CONTROL_0              = 0x1E
R25_PLAYBACK_MIXER_RIGHT_CONTROL_1              = 0x1F
R26_PLAYBACK_LR_MIXER_LEFT_LINE_OUTPUT_CONTROL  = 0x20
R27_PLAYBACK_LR_MIXER_RIGHT_LINE_OUTPUT_CONTROL = 0x21
R28_PLAYBACK_LR_MIXER_MONO_OUTPUT_CONTROL       = 0x22
R29_PLAYBACK_HEADPHONE_LEFT_VOLUME_CONTROL      = 0x23
R30_PLAYBACK_HEADPHONE_RIGHT_VOLUME_CONTROL     = 0x24
R31_PLAYBACK_LINE_OUTPUT_LEFT_VOLUME_CONTROL    = 0x25
R32_PLAYBACK_LINE_OUTPUT_RIGHT_VOLUME_CONTROL   = 0x26
R33_PLAYBACK_MONO_OUTPUT_CONTROL                = 0x27
R34_PLAYBACK_POP_CLICK_SUPPRESSION              = 0x28
R35_PLAYBACK_POWER_MANAGEMENT                   = 0x29
R36_DAC_CONTROL_0                               = 0x2A
R37_DAC_CONTROL_1                               = 0x2B
R38_DAC_CONTROL_2                               = 0x2C
R39_SERIAL_PORT_PAD_CONTROL                     = 0x2D
R40_CONTROL_PORT_PAD_CONTROL_0                  = 0x2F
R41_CONTROL_PORT_PAD_CONTROL_1                  = 0x30
R42_JACK_DETECT_PIN_CONTROL                     = 0x31
R67_DEJITTER_CONTROL                            = 0x36
R58_SERIAL_INPUT_ROUTE_CONTROL                  = 0xF2
R59_SERIAL_OUTPUT_ROUTE_CONTROL                 = 0xF3
R61_DSP_ENABLE                                  = 0xF5
R62_DSP_RUN                                     = 0xF6
R63_DSP_SLEW_MODES                              = 0xF7
R64_SERIAL_PORT_SAMPLING_RATE                   = 0xF8
R65_CLOCK_ENABLE_0                              = 0xF9
R66_CLOCK_ENABLE_1                              = 0xFA

def send_byte(register, byte):
    ol.axi_iic_0.send(IIC_ADDR, bytes([0x40]) + bytes([register]) + bytes([byte]), 3)

def send_bytes(register, payload):
    ol.axi_iic_0.send(IIC_ADDR, bytes([0x40]) + bytes([register]) + bytes(payload), 2 + len(payload))

import time
send_byte(R0_CLOCK_CONTROL, 0x0E)
# 02 71 02 3c 21 03
send_bytes(R1_PLL_CONTROL, [0x02, 0x71, 0x02, 0x3C, 0x21, 0x01])
rxdata = bytes(6)
count =  1
while True:
    ol.axi_iic_0.send(0x3b, bytes([0x40, 0x02]), 2)
    ol.axi_iic_0.receive(0x3b, rxdata, 6)
    if rxdata[5] & 0x02 != 0:
        break
    if count > 10000:
        print("failed to lock pll")
        break
    count += 1
send_byte(R0_CLOCK_CONTROL, 0x0F)
time.sleep(1)
# Mute Mixer1 and Mixer2 here, enable when MIC and Line In used
send_byte(R4_RECORD_MIXER_LEFT_CONTROL_0, 0x00)
send_byte(R6_RECORD_MIXER_RIGHT_CONTROL_0, 0x00)
# Set LDVOL and RDVOL to 21 dB and Enable left and right differential
send_byte(R8_LEFT_DIFFERENTIAL_INPUT_VOLUME_CONTROL, 0xB3)
send_byte(R9_RIGHT_DIFFERENTIAL_INPUT_VOLUME_CONTROL, 0xB3)
# Enable MIC bias
#send_byte(R10_RECORD_MICROPHONE_BIAS_CONTROL, 0x01)
# Enable ALC control and noise gate
#send_byte(R14_ALC_CONTROL_3, 0x20)
# Put CODEC in Master mode
send_byte(R15_SERIAL_PORT_CONTROL_0, 0x01)
send_byte(R16_SERIAL_PORT_CONTROL_1, 0x00)
# Enable ADC on both channels, normal polarity and ADC high-pass filter
#send_byte(R19_ADC_CONTROL, 0x33)
# enable mixer output
send_byte(R22_PLAYBACK_MIXER_LEFT_CONTROL_0, 0x21)
send_byte(R24_PLAYBACK_MIXER_RIGHT_CONTROL_0, 0x41)
# Mute left and right channels output; enable them when output is needed
send_byte(R29_PLAYBACK_HEADPHONE_LEFT_VOLUME_CONTROL, 0xE7)
send_byte(R30_PLAYBACK_HEADPHONE_RIGHT_VOLUME_CONTROL, 0xE7)
# Enable play back right and left channels
send_byte(R35_PLAYBACK_POWER_MANAGEMENT, 0x03)
# Enable DAC for both channels
send_byte(R36_DAC_CONTROL_0, 0x03)
# Set SDATA_In to DAC
send_byte(R58_SERIAL_INPUT_ROUTE_CONTROL, 0x01)
# Set SDATA_Out to ADC
send_byte(R59_SERIAL_OUTPUT_ROUTE_CONTROL, 0x01)
# Enable DSP and DSP Run
send_byte(R61_DSP_ENABLE, 0x01)
send_byte(R62_DSP_RUN, 0x01)
# Enable Digital Clock Generator 0 and 1. 
send_byte(R65_CLOCK_ENABLE_0, 0x7F)
send_byte(R66_CLOCK_ENABLE_1, 0x03)

ol.axi_gpio_0.write(0,1)

