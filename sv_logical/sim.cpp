#include "Vtop.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

vluint64_t main_time = 0;

double sc_time_stamp() { return main_time; }

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    Vtop* top = new Vtop;

    // Enable waveform dumping
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    
    top->trace(tfp, 5); //  number trace levels
    tfp->open("waveform.vcd");

    auto step = [&](int cycles) {
        for (int i = 0; i < cycles; i++) {
            top->eval();
            tfp->dump(main_time);
            main_time++;
        }
    };

    top->a = 0b00;
    top->b = 0b01;
    step(2);

    top->a = 0b11;
    top->b = 0b01;
    step(2);

    top->a = 0b00;
    top->b = 0b11;
    step(2);

    top->a = 0b11;
    top->b = 0b10;
    step(2);

    top->final();
    tfp->close();
    delete top;
    return 0;
}