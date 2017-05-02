# python3 opcemu.py <filename.hex> [<filename.memdump>]
import sys
op = { "and"  :0x00, "lda":0x01,"not"  :0x02,"add":0x03, "and.i":0x10, "lda.i":0x11, "not.i":0x12,
       "add.i":0x13, "sec":0x15,"lda.p":0x09,"sta":0x18, "sta.p":0x08, "jpc"  :0x19, "jpz"  :0x1a, 
       "jp"   :0x1b, "jsr":0x1c,"rts"  :0x1d,"lxa":0x1e, "halt" :0x1f, "BYTE":0x100 }

dis = dict( [ (op[k],k) for k in op])

with open(sys.argv[1],"r") as f:
    bytemem = bytearray( [ int(x,16) for x in f.read().split() ])

(pc, acc, c, link) = (0x100,0,0,0) # initialise machine state
print ("PC   : Mem   : ACC C : Mnemonic Operand\n%s" % ('-'*40))
while True:
    opcode = (bytemem[pc] >> 3) & 0x1F
    operand_adr = ((bytemem[pc] << 8) | bytemem[pc+1]) & 0x07FF
    if (opcode & 0x10 == 0x00):
        operand_data = bytemem[operand_adr] & 0xFF
    else:
        operand_data = bytemem[pc+1] & 0xFF
    if (opcode  & 0x18 == 0x08):  # Second read for pointer operations
        operand_adr = bytemem[operand_data] & 0xFF        
        operand_data = (bytemem[operand_adr] & 0xFF)
        
    print ("%04x : %02x %02x : %02x  %d : %-8s %03x    " % ( pc, bytemem[pc], bytemem[pc+1],
        acc, c,  dis[opcode], operand_data if opcode & 0x10==1 else operand_adr) )
    pc += 2
    if opcode in ( op["and"], op["and.i"]):
        acc = acc & operand_data & 0xFF
        c = 0
    elif opcode in ( op["not"], op["not.i"]):
        acc = ~operand_data & 0xFF
    elif opcode in (op["add"], op["add.i"]) :
        res = (acc + operand_data + c ) & 0x1FF
        acc = res & 0xFF
        c = (res>>8) & 1
    elif opcode in (op["lda.i"], op["lda"], op["lda.p"]):
        acc = operand_data & 0xFF
    elif opcode in (op["sta"], op["sta.p"]):
        bytemem[operand_adr] = acc
    elif opcode in (op["jpc"], op["jpz"], op["jp"]):
        condition = (c==1) if opcode==op["jpc"] else (acc==0) if opcode==op["jpz"] else True
        pc = operand_adr if condition else pc
    elif opcode == op["lxa"]:
        tmp = acc
        acc = link
        link = tmp & 0x07
    elif opcode == op["rts"]:
        pc = (link << 8) | acc
    elif opcode == op["sec"]:
        c = 1
    elif opcode == op["jsr"]:
        link = (pc >> 8) & 0x07
        acc = pc & 0xFF
        pc = operand_adr
    elif opcode == op["halt"]:
        print("Stopped on halt instruction at %04x" % (pc-2) )
        break

if len(sys.argv) > 2:  # Dump memory for inspection if required
    with open(sys.argv[2],"w" ) as f:
        for i in range(0, len(bytemem), 24):
            f.write( '%s\n' %  ' '.join("%02x"%n for n in bytemem[i:i+24]))
