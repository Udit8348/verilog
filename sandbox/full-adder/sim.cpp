#include "Vfull_adder.h"
#include "../../lib/verilator_sim.h"

int main(int argc, char** argv) {
    Sim<Vfull_adder> sim(argc, argv);
    sim.open_trace("waveform.vcd");

    for (int A = 0; A <= 1; A++) {
        for (int B = 0; B <= 1; B++) {
            for (int Cin = 0; Cin <= 1; Cin++) {
                sim->A = A;
                sim->B = B;
                sim->Cin = Cin;
                sim.step();
            }
        }
    }

    sim.step(); // hold last state (optional, makes last edge obvious)
    return 0;
}