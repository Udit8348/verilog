    #include "Vregisters.h"
    #include "../../lib/verilator_sim.h" 

    int main(int argc, char** argv) {
        Config cfg {.vcd_path = "waveform.vcd"};
        Sim<Vregisters> sim(argc, argv, cfg);

        for (int A = 0; A <= 1; A++) {
            for (int B = 0; B <= 1; B++) {
                sim->A = A;
                sim->B = B;
                sim.step();
            }
        }
        
        sim.step(); // hold so we can see the final state

        return 0;
    }