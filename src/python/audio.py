from pynq import Overlay
ol = Overlay("overlay.bit")
ol.download()

def send_byte(register, byte):
    # i2c address is 0x76, but axi_iic uses 7 bit addresses, so shift right by 1
    ol.axi_iic_0.send(0x3b, bytes([0x40]) + bytes([register]) + bytes([byte]), 3)

def send_bytes(register, payload):
    ol.axi_iic_0.send(0x3b, bytes([0x40]) + bytes([register]) + bytes(payload), 2 + len(payload))

import time

# R0 (0x00): enable PLL, set input clock frequency to 1024*f_s, disable core clock
send_byte(0x00, 0x0E)

# R1 (0x01): set PLL frequency to (4 + 0.9152)*f_MCLK = 4.9152*10MHz 
# also enable PLL
send_bytes(0x01, [0x02, 0x71, 0x02, 0x3C, 0x21, 0x01])

# wait until PLL lock is achieved
rxdata = bytes(6)
count =  1
while True:
    ol.axi_iic_0.send(0x3b, bytes([0x40, 0x02]), 2)
    ol.axi_iic_0.receive(0x3b, rxdata, 6)
    if rxdata[5] & 0x02 != 0:
        break
    if count > 100:
        print("failed to lock pll")
        break
    count += 1
    time.sleep(0.1)

# R0 (0x00): enable core clock
send_byte(0x00, 0x0F)

# wait for core to start up 
time.sleep(1)

# R15 (0x15): Put CODEC in Master mode
send_byte(0x15, 0x01)

# enable mixer output on L/R channels
# R22 (0x1C): unmute left DAC input to left channel playback mixer
# R24 (0x1E): unmute left DAC input to left channel playback mixer
send_byte(0x1C, 0x21)
send_byte(0x1E, 0x41)

# enable headphone playback on L/R channels
# R29 (0x23): set volume to 0dB (111001xx) and unmute and enable headphone volume control (xxxxxx11)
# R30 (0x24): set volume to 0dB (111001xx) and unmute and enable headphone volume control (xxxxxx11)
send_byte(0x23, 0xE7)
send_byte(0x24, 0xE7)

# Enable playback L/R channels
# R35 (0x29): leave bias control in default normal operation, enable left and right channel playback
send_byte(0x29, 0x03)

# Enable DAC for both channels
# R36 (0x2A): leave in stereo mode, enable both left and right DACs
send_byte(0x2A, 0x03)

# Set DAC/ADC i/o to use i2s data
# R58 (0xF2): set serial input [L0, R0] to DAC L/R
# R59 (0xF3): set ADC L/R to serial output [L0, R0]
send_byte(0xF2, 0x01)
send_byte(0xF3, 0x01)

# R65 (0xF9): enable all digital clocks
send_byte(0xF9, 0x7F)
# R66 (0xFA): enable digital clock generator 0 and 1
send_byte(0xFA, 0x03)

# enable i2s controller IP
ol.axi_gpio_0.write(0,1)

