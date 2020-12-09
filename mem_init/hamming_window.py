import numpy as np
import matplotlib.pyplot as plt

fixed_point = [hex(int(i))[2:] + ',\n' for i in np.hamming(1024)*2**16]
print(fixed_point)
exit()
f = open("hamming_1024.coe", "w")
f.writelines(fixed_point)
f.close()
