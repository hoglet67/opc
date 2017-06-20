# Paths that will need changing

PAPILIO_LOADER=/opt/GadgetFactory/papilio-loader/programmer
XILINX=/opt/Xilinx/14.7
PATH  := "$(PATH):${XILINX}/ISE_DS/ISE/bin/lin"
SHELL := env PATH=$(PATH) /bin/sh

# Shouldn't need to make changes below this point

BIT_FILE=working/opc5wrapper.bit
BMM_FILE=opc5system_bd.bmm

build: opc5system.bit

deploy: opc5system.bit
	impact -batch deploy.batch

program: opc5system.bit
	impact -batch program.batch

opc5system.bit: monitor.mem $(BIT_FILE)
	data2mem -bm $(BMM_FILE) -bd monitor.mem -bt $(BIT_FILE) -o b opc5system.bit

monitor.mem : ../../monitor.s
	python ../../opc5lsasm.py ../../monitor.s monitor.hex
	tr " " "\n" <monitor.hex | head -16384 > monitor.mem

.phony: clean

clean:
	rm -f opc5system.bit monitor.mem monitor.hex
	rm -f opc5system.cfi opc5system.mcs opc5system.prm
