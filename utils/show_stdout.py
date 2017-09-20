#!/usr/bin/env python3
'''
 show_stdout.py -f <filename> [-m] [ -adr num ]  

OR

 cat <filename> | show_stdout.py [-m] [-adr num] 

Process an OPC trace file from emulation to create a stdout type file from
data sent to the specified output port or memory address.

By default alll 'OUT' traffic is logged. 

This can be filtered by providing a specific OUT address.

Alternatively a memory location and address should be supplied for memory mapped IO.

'''
import getopt
import sys
import os
import re


def showUsageAndExit() :
    print (__doc__)
    sys.exit(2)

def process_file(filename, adr=-1, mem_not_io=False):

    adrstr = '0x.*?' if adr==-1 else '0x%04x' % adr
    iostr = 'STORE' if mem_not_io else 'OUT'
    stdout_re = re.compile("\s*?%s:\s*Address : %s .*?Data : 0x.*? \(\s*?(\d*)\).*?" % (iostr,adrstr))
    try:
        if filename =="":
            f = sys.stdin
        else:
            f = open(filename,"r")
    except:
        print("Problem reading from input file %s" % filename)
        sys.exit(1)

    for l in f:
        mobj = stdout_re.match(l)
        if mobj:
            ch = chr( int(mobj.group(1)) )
            print(ch, end="")
        pass
    f.close()

if __name__ == '__main__':
    filename = ""
    adr = -1
    mem_not_io = False
    try:
        opts, args = getopt.getopt( sys.argv[1:], "f:a:mh", ["filename=","adr=","memory", "help"])
    except getopt.GetoptError:
        showUsageAndExit()
    for opt, arg in opts:
        if opt in ( "-f", "--filename" ) :
            filename = arg
        elif opt in ( "-a", "--adr" ) :
            adr = int(arg,0)
        elif opt in ( "-m", "--memory" ) :
            mem_not_io = True
        elif opt in ( "-h","--help" ) :            
            showUsageAndExit()
        else:
            showUsageAndExit()        
        
    if filename != "" and not os.path.exists(filename):
        print("Error: cannot find file %s" % filename)
        sys.exit(2)

    process_file(filename, adr, mem_not_io)
