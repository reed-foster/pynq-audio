import matplotlib.pyplot as plt
from lib6003.audio import *
import numpy as np
from math import e, pi, sin, cos, log, floor, ceil
j = 1j

def peakiness(dft_mag):
    m = 2 # half-width of window function main lobe in bins
    peaks = np.zeros(dft_mag.shape)
    for k in range(len(dft_mag)):
        left = 0 if k < m else dft_mag[k-m]
        right = 0 if k >= len(dft_mag)-m else dft_mag[k+m]
        peaks[k] = (left+right)/dft_mag[k]
    return peaks

def amplitude_threshold(dft_mag):
    a = 0.55
    r = np.zeros(dft_mag.shape)
    for k in range(1,len(dft_mag)):
        r[k] = a*r[k-1] + (1-a)*dft_mag[k]
    return np.divide(r, dft_mag)

def compute_hps(dft_mag):
    product = np.zeros(dft_mag.shape)
    for k in range(2,len(dft_mag)//2):
        product[k] = dft_mag[k]*dft_mag[2*k]
    return product

def get_fundamental(dft, plot=False):
    mag = abs(dft)**2
    
    peaks = peakiness(mag[:32])
    am_threshold = amplitude_threshold(mag[:32])
    tonalness_pk = 1/(1+np.square(peaks))**2
    tonalness_am = 1/(1+np.square(am_threshold))**2
    salience = tonalness_am*tonalness_pk
    salience_hps = salience*compute_hps(mag[:32])
    maxk = 0
    maxhps = max(salience_hps)
    maxmag = max(mag[:32])
    for k in range(len(salience_hps)):
        if salience_hps[k] < maxhps/1024:
            continue
        if mag[k] > maxmag/256:
            maxk = k
            break
    left = maxk-2 if maxk-2 > 0 else 0
    right = maxk+3 if maxk+3 > 0 else 0
    maxk = left + mag[left:right].argmax()
    if plot:
        fig, ax1 = plt.subplots()
        ax1.set_xlabel('bin')
        ax1.set_ylabel('|X|', color='tab:red')
        ax1.plot(mag[:32], color='tab:red')
        ax1.scatter([maxk], [mag[maxk]], s=48, c='b')
        ax1.set_ylim(0,2500)
        ax2 = ax1.twinx()
        ax2.set_ylabel('hps(|X|)*salience', color='tab:blue')
        ax2.plot(salience_hps[:32], color='tab:blue')
        ax2.set_ylim(0,max(salience_hps[:32])*1.1)
        fig.tight_layout()
        plt.show()
    return maxk

# Setup of input file
#filename = 'sinusoid.wav'
filename = 'queen.wav'
signal, fs = wav_read(f'samples/{filename}')
in_key = [16.35,17.32,19.45,21.83,23.12,25.96,29.14,32.70,34.65,38.89,43.65,46.25,51.91,58.27,65.41,69.30,77.78,87.31,92.50,103.8,116.5,130.8,138.6,155.6,174.6,185.0,207.7,233.1,261.6,277.2,311.1,349.2,370.0,415.3,466.2,523.3,554.4,622.3,698.5,740.0,830.6,932.3,1047,1109,1245,1397,1480,1661,1865,2093,2217,2489,2794,2960,3322,3729,4186,4435,4978,5588,5920,6645,7459]
in_key = [65.25*i for i in range(1,10,2)]# + [65.25*3/2*i for i in range(1,40)]

dft_size = 1024
step_size_analysis = dft_size//2
t_a = step_size_analysis/fs
print(f'input latency = {dft_size/48000}')

num_ffts = (len(signal) - dft_size)//step_size_analysis + 1

window = np.hanning(dft_size)

last_phase_analysis = np.zeros(dft_size)
bin_freq = np.array([k*2*pi/dft_size for k in range(dft_size)])

output = np.zeros(len(signal))
last_maxk_list = [0, 0]
for bin in range(30,num_ffts):
    sample = signal[bin*step_size_analysis:bin*step_size_analysis+dft_size]
    dft = np.fft.fft(np.multiply(sample, window))
    mag = abs(dft)**2
    phase = np.arctan2(dft.imag, dft.real)
 
    total_energy = sum(mag)
    #print(f'total energy = {total_energy}')
    vocal_energy = 2*sum(mag[:int(2500/44100*1024)]) # if a sound is white, then don't autotune it
    #print(f'total energy in vocal range = {vocal_energy} ({round(vocal_energy/total_energy*100,2)}%)')
    autotune = vocal_energy/total_energy > 0.2
    maxk = get_fundamental(dft, True)
    #maxk = get_fundamental(dft, False)
    scale = 1
    if autotune:
        # phase vocoder stuff
        f_n = lambda n: (phase[maxk] - last_phase_analysis[maxk] + 2*pi*n)/(2*pi*t_a)
        min_n = round((last_phase_analysis[maxk]-phase[maxk])/(2*pi) + t_a*fs*maxk/dft_size)
        fundamental = f_n(min_n)
        print(f'maxk = {maxk}, fundamental = {fundamental}')
        scale = in_key[abs(np.array(in_key)-fundamental).argmin()]/fundamental
        scale = 220/fundamental
    if scale != 1:
        if scale > 1:
            # note is too low, need to shift up. concat signal with itself
            amp_0 = sample[-2]
            amp_1 = sample[-1]
            min_diff = 1e8
            min_n = -1
            for n in range(dft_size//2):
                diff = abs(amp_0 - sample[n]) + abs(amp_1 - sample[n+1])
                if diff < min_diff:
                    min_diff = diff
                    min_n = n
            n += 2
            for i in range(ceil((scale-1)*dft_size/(dft_size-n))):
                sample = np.concatenate((sample, sample[n:dft_size]))
        # if note is too high, need to shift down, but that doesn't require extra work for concatenation
        n_interp = np.linspace(0,dft_size*scale,dft_size) 
        s_interp = np.interp(n_interp, np.array(range(len(sample))), sample)
    else:
        s_interp = sample
    start = int(bin*step_size_analysis)
    end = start + dft_size
    output[start:end] = np.add(output[start:end], np.multiply(np.hanning(dft_size), s_interp))
    last_phase_analysis = phase
    #plt.figure()
    #plt.plot(output[:end])
    #plt.show()

wav_write(output, fs, 'queenauto.wav')
