#!/bin/sh

# Compile the verilog
mkdir -p build
RED='\033[0;31m'
NC='\033[0m' # No Color

iverilog -o build/testbench *.v || { printf "${RED}Failed to compile, check errors${NC}\n"; exit 0; }

# Run the simulation
cd build
./testbench || { printf "${RED}Failed to run simulation, check errors${NC}\n"; exit 0; }

# Check if GTK wave is already running
WID=$(cat gtkwave)
if osascript -e "tell application \"System Events\" to (name of processes) contains \"GTKWave\""; then
    # Wait for the existing process to close
    pkill -f "GTKWave"
    while ps -p $(cat gtkwave.pid) > /dev/null; do
        true
    done
fi

# Load the VCD file in GTK wave and launch it
nohup gtkwave -M dump.vcd .dump.gtkw -a .dump.gtkw --dark --rcvar 'splash_disable on' --saveonexit 2>&1 &
GTKWAVE=$!

# Dump IDs to lockfiles so we know to restart next time
echo $WID > gtkwave
echo $GTKWAVE > gtkwave.pid