#!/bin/bash

PROG=$1

if [[ -z $PROG ]]; then
    PROG=pi
fi


# Clean up
rm -f *~ ${PROG}.bin ${PROG}.c.xml  ${PROG}.fpp  ${PROG}.hex  ${PROG}.lis  ${PROG}.s

# Compile
./c64 ${PROG}.c

# Patch the assember to fix some buhs
#sed -e "s/push.*/&,r14/g" -i ${PROG}.s
#sed -e "s/pop.*/&,r14/g"  -i ${PROG}.s
#sed -e "s/word/WORD/g"    -i ${PROG}.s
#sed -r "s/align/#align/g" -i ${PROG}.s

# Assemble
cat ${PROG}.s lib.s > tmp.s
python ../../opc6/opc6asm.py tmp.s ${PROG}.hex

# Hex to binary
xxd -r -p < ${PROG}.hex | dd status=none conv=swab ibs=2 skip=$((16#0100)) count=$((16#0400)) > ${PROG}.bin

# Generare srecords
srec_cat ${PROG}.bin -Binary --offset 0x100 | grep S1

