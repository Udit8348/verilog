#!/bin/sh

# Colors
RED='\033[0;31m'
NC='\033[0m'

mkdir -p build

# Compile
iverilog -o build/testbench *.v || {
    printf "${RED}Failed to compile, check errors${NC}\n"
    exit 1
}

cd build || exit 1

# Run
./testbench || {
    printf "${RED}Simulation failed${NC}\n"
    exit 1
}

# Ensure VCD exists
if [ ! -f dump.vcd ]; then
    printf "${RED}dump.vcd not generated${NC}\n"
    exit 1
fi

# Kill existing GTKWave safely
if pgrep -x "GTKWave" >/dev/null 2>&1; then
    pkill -x "GTKWave"
    if [ -f gtkwave.pid ]; then
        while ps -p "$(cat gtkwave.pid)" >/dev/null 2>&1; do
            sleep 0.1
        done
    fi
fi

# Launch GTKWave
nohup gtkwave dump.vcd .dump.gtkw --dark \
    --rcvar 'splash_disable on' --saveonexit >/dev/null 2>&1 &
GTKWAVE=$!

echo "$GTKWAVE" > gtkwave.pid