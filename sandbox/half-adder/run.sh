#!/bin/sh

RED='\033[0;31m'
NC='\033[0m'

TOP=half_adder
BUILD_DIR=build
OBJ_DIR=obj_dir
WAVE=waveform.vcd

mkdir -p "$BUILD_DIR"

rm -rf "$BUILD_DIR/$OBJ_DIR"
rm -f "$WAVE"

# ------------------------------------------------------------------------
# Verilate (generate C++)
# ------------------------------------------------------------------------
verilator --cc --trace --exe \
    half-adder.v sim.cpp \
    --top-module "$TOP" \
    -Mdir "$BUILD_DIR/$OBJ_DIR" || {
    printf "${RED}Verilation failed${NC}\n"
    exit 1
}

# ------------------------------------------------------------------------
# Build generated C++
# ------------------------------------------------------------------------
make -C "$BUILD_DIR/$OBJ_DIR" -f "V${TOP}.mk" "V${TOP}" || {
    printf "${RED}C++ build failed${NC}\n"
    exit 1
}

# ------------------------------------------------------------------------
# Run simulation
# ------------------------------------------------------------------------
"$BUILD_DIR/$OBJ_DIR/V${TOP}" || {
    printf "${RED}Simulation failed${NC}\n"
    exit 1
}

# ------------------------------------------------------------------------
# Ensure waveform exists
# ------------------------------------------------------------------------
if [ ! -f "$WAVE" ]; then
    printf "${RED}${WAVE} not generated${NC}\n"
    exit 1
fi

# ------------------------------------------------------------------------
# Launch GTKWave in the background (optional)
# ------------------------------------------------------------------------
if command -v gtkwave >/dev/null 2>&1; then
    if pgrep -x "gtkwave" >/dev/null 2>&1; then
        pkill -x "gtkwave"
        sleep 0.3
    fi
    nohup gtkwave "$WAVE" --dark --rcvar 'splash_disable on' >/dev/null 2>&1 &
    echo "$!" > gtkwave.pid
fi

exit 0