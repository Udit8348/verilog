#!/bin/sh

# Colors
RED='\033[0;31m'
NC='\033[0m'

TOP=top
BUILD_DIR=build
OBJ_DIR=obj_dir
WAVE=waveform.vcd

mkdir -p $BUILD_DIR

# Clean previous build
rm -rf $BUILD_DIR/$OBJ_DIR
rm -f $BUILD_DIR/$WAVE

# ----------------------------------------
# Verilate (generate C++)
# ----------------------------------------
verilator --cc --trace --exe *.sv sim.cpp \
    --top-module $TOP \
    -Mdir $BUILD_DIR/$OBJ_DIR || {
    printf "${RED}Verilation failed${NC}\n"
    exit 1
}

# ----------------------------------------
# Build generated C++
# ----------------------------------------
make -C $BUILD_DIR/$OBJ_DIR -f V${TOP}.mk V${TOP} || {
    printf "${RED}C++ build failed${NC}\n"
    exit 1
}

# ----------------------------------------
# Run simulation
# ----------------------------------------
$BUILD_DIR/$OBJ_DIR/V${TOP} || {
    printf "${RED}Simulation failed${NC}\n"
    exit 1
}

# ----------------------------------------
# Ensure waveform exists
# ----------------------------------------
if [ ! -f $WAVE ]; then
    printf "${RED}${WAVE} not generated${NC}\n"
    exit 1
fi

# ----------------------------------------
# Kill existing GTKWave safely
# ----------------------------------------
if pgrep -x "gtkwave" >/dev/null 2>&1; then
    pkill -x "gtkwave"
    sleep 0.3
fi

# ----------------------------------------
# Launch GTKWave
# ----------------------------------------
nohup gtkwave $WAVE --dark \
    --rcvar 'splash_disable on' >/dev/null 2>&1 &
GTKWAVE=$!

echo "$GTKWAVE" > gtkwave.pid