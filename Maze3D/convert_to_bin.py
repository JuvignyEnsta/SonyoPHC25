from PIL import Image
import numpy as np
import sys

filename_in  = ''
filename_out = ''
if len(sys.argv) != 3:
    print("Usage : convert_bin.py entree.png sortie.bin")
    exit(-1)
    
filename_in  = sys.argv[1]
filename_out = sys.argv[2]

img_png = Image.open(filename_in)
img_arr = np.array(img_png)

bin = []
print(img_arr.shape)
print(img_arr)
for y in range(0,img_arr.shape[0]):
    for x in range(0, img_arr.shape[1], 8):
        byte  = img_arr[y,x+0]*128 + img_arr[y,x+1]*64
        byte += img_arr[y,x+2]*32  + img_arr[y,x+3]*16
        byte += img_arr[y,x+4]*8   + img_arr[y,x+5]*4
        byte += img_arr[y,x+6]*2   + img_arr[y,x+7]
        bin.append(byte)

bin_arr = bytearray(bin)
with open(filename_out, "wb") as f:
    f.write(bin_arr)


        
