    #include "Vhalf_adder.h"
    #include "../../lib/verilator_sim.h" 

    int main(int argc, char** argv) {
        Sim<Vhalf_adder> sim(argc, argv);
        sim.open_trace("waveform.vcd");

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