BOARD=tangnano9k
FAMILY=GW1N-9C
DEVICE=GW1NR-LV9QN88PC6/I5

all: bitstream.fs

# Synthesis
synthesis.json: top.v tangnano9k.cst
	yosys -p "read_verilog top.v; synth_gowin -noalu -nowidelut -nolutram -nodffe -top top -json synthesis.json"

# Place and Route
pnr.json: synthesis.json
	nextpnr-gowin --json synthesis.json --write pnr.json --enable-auto-longwires --enable-globals --freq 27 --device ${DEVICE} --family ${FAMILY} --cst ${BOARD}.cst

# Generate Bitstream
bitstream.fs: pnr.json
	gowin_pack -d ${FAMILY} -o bitstream.fs pnr.json

# Program Board
load: bitstream.fs
	openFPGALoader -b ${BOARD} bitstream.fs

# Flash Board
flash: bitstream.fs
	openFPGALoader -b ${BOARD} bitstream.fs -f

# Cleanup build artifacts
clean:
	rm bitstream.fs

.PHONY: load flash clean test
.INTERMEDIATE: pnr.json synthesis.json