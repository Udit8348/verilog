// sim.cpp - ripple_carry4 testbench (combinational)
// Run: ./run.sh then open waveform.vcd in GTKWave.

#include "Vripple_carry4.h"
#include "../../lib/verilator_sim.h"

#include <cstdint>

static inline void apply(Sim<Vripple_carry4>& sim, uint8_t a, uint8_t b) {
    sim->A = a & 0xF;
    sim->B = b & 0xF;
    sim.step();
}

int main(int argc, char** argv) {
    Sim<Vripple_carry4> sim(argc, argv);
    sim.open_trace("waveform.vcd");

    apply(sim, 0x0, 0x0); // 0 + 0
    apply(sim, 0x1, 0x0); // 1 + 0
    apply(sim, 0x0, 0x1); // 0 + 1
    apply(sim, 0x1, 0x1); // 1 + 1

    // Carry / ripple-focused cases
    apply(sim, 0x3, 0x1); // 0011 + 0001 = 0100
    apply(sim, 0x7, 0x1); // 0111 + 0001 = 1000 (ripple through 3 bits)
    apply(sim, 0xF, 0x1); // 1111 + 0001 = 1_0000 (full ripple, CarryOut=1)
    apply(sim, 0xA, 0x5); // 1010 + 0101 = 1111 (no carry out)


    // Hold final value so last transition is easy to see
    sim.step();

    return 0;
}