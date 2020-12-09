# process logic analyzer data (csv format) from Saleae software
import matplotlib.pyplot as plt

def to_hex(val, bits):
    if val < 0:
        val += 2**bits
    return hex(val)[2:]

f = open("i2s_data.csv", "r")
signal = f.readlines()[::2]
f.close()

plt.figure()
plt.plot(signal[:2048])
plt.show()
exit()

f = open("raw_sawtooth.txt", "w")
f.writelines([to_hex(int(s.split(',')[-1]), 24) + "\n" for s in signal])
f.close()

