#!/bin/sh
RED='\033[0;31m'
NC='\033[0m'

TOP=top
BUILD_DIR=build
OBJ_DIR=obj_dir
WAVE=waveform.vcd

mkdir -p $BUILD_DIR
rm -rf $BUILD_DIR/$OBJ_DIR
rm -f $BUILD_DIR/$WAVE

# Include dpi_impl.cpp in the --exe list.
verilator --cc --trace --exe *.sv sim.cpp dpi_impl.cpp \
    --top-module $TOP \
    -Mdir $BUILD_DIR/$OBJ_DIR || {
    printf "${RED}Verilation failed${NC}\n"
    exit 1
}

make -C $BUILD_DIR/$OBJ_DIR -f V${TOP}.mk V${TOP} || {
    printf "${RED}C++ build failed${NC}\n"
    exit 1
}

$BUILD_DIR/$OBJ_DIR/V${TOP} || {
    printf "${RED}Simulation failed${NC}\n"
    exit 1
}

if [ ! -f $WAVE ]; then
    printf "${RED}${WAVE} not generated${NC}\n"
    exit 1
fi

if pgrep -x "gtkwave" >/dev/null 2>&1; then
    pkill -x "gtkwave"
    sleep 0.3
fi

nohup gtkwave $WAVE --dark --rcvar 'splash_disable on' >/dev/null 2>&1 &
echo "$!" > gtkwave.pid