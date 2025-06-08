import sys
import os 

chunk = 64

if len(sys.argv) > 1:
    argv = sys.argv[1:]
    filename = argv[0]
    
    f = open(filename + '.ram', 'rb')
    bin = f.read()
    f.close()
    f = open(filename + '.bas', 'w')
    
    f.write('20 CLEAR 50, &HE000\n')
    f.write('30 RESTORE 1000 : SCREEN 3,1,1 : ADDR = &HE000\n')
    f.write('40 READ DX$ : if DX$<>"X" THEN X=LEN(DX$): FOR J=1 to X step 2 : POKE ADR,VAL("&H"+MID$(DX$,J,2)):ADR=ADR+1:NEXT J: GOTO 40\n')
    #f.write('40 FOR I=0 TO '+str(len(bin)-1) + '\n')
    #f.write('50 READ A$ : POKE &HE000+I, VAL("&H"+A$)\n')
    #f.write('60 NEXT I\n')
    f.write(f"70 EXEC &HE000\n")
    f.write(f"75 GOTO 75\n")
    f.write(f"80 END\n")
    line = 1000    
    for i in range(0,len(bin), chunk):
        s = f"{line} DATA \""
        for j in range(i, min(len(bin),i+chunk)):
                s += f"{bin[j]:02X}"
        s += "\"\n"    
        f.write(s)
        line += 10
    f.write(f"{line} DATA \"X\"\n")
    f.close()
else:
    print("Usage : python3 ram2data.py <basename>")
    
