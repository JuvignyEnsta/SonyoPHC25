import sys
import os 

if len(sys.argv) > 1:
    argv = sys.argv[1:]
    filename = argv[0]
    
    f = open(filename + '.ram', 'rb')
    bin = f.read()
    f.close()
    f = open(filename + '.bas', 'w')
    
    f.write('20 CLEAR 50, &HE000\n')
    f.write('30 RESTORE 1000 : SCREEN 3,1,1\n')
    f.write('40 FOR I=0 TO '+str(len(bin)-1) + '\n')
    f.write('50 READ A$ : POKE &HE000+I, VAL("&H"+A$)\n')
    f.write('60 NEXT I\n')
    f.write(f"70 EXEC &HE000\n")
    f.write(f"75 GOTO 75\n")
    f.write(f"80 END\n")
    line = 1000    
    for i in range(0,len(bin), 16):
        s = f"{line} DATA "
        for j in range(i, min(len(bin),i+16)):
                s += f"{bin[j]:02X},"
        s = s[:-1] + "\n"    
        f.write(s)
        line += 10
    f.close()
else:
    print("Usage : python3 ram2data.py <basename>")
    
