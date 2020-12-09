import numpy as np

def phase_to_hex(p):
    p = int(p*2**21)
    if p < 0:
        p += 2**24
    return hex(p)

phase = np.zeros(2)
phase[0] = np.arctan2(1932, -179533)/np.pi
phase[1] = np.arctan2(-33406, -176324)/np.pi

max_k = 8

raw_min_n = phase[0]-phase[1] + 0.5*max_k
min_n = round(raw_min_n)
fund = (phase[1] - phase[0] + min_n)/(512/48000)

print(f'phase = {phase_to_hex(phase[1])}, last_phase = {phase_to_hex(phase[0])}')
print(f'min_n = {hex(int(raw_min_n*2**21))}, fund = {hex(int(fund*2**10))}')
print(f'fixed point equivalent: {int(fund*2**10)/2**10}')
