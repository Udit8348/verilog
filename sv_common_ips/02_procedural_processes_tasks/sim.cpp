#include "Vtop.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

static vluint64_t main_time = 0;
double sc_time_stamp() { return (double)main_time; }

static void tick(Vtop* dut, VerilatedVcdC* tfp) {
    dut->clk = 0; dut->eval(); if (tfp) tfp->dump(main_time++);
    dut->clk = 1; dut->eval(); if (tfp) tfp->dump(main_time++);
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    Vtop* dut = new Vtop;
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    dut->trace(tfp, 99);
    tfp->open("waveform.vcd");

    // Reset
    dut->rst_n = 0;
    dut->en = 0;
    dut->x = 0;
    dut->y = 0;
    for (int i = 0; i < 4; i++) tick(dut, tfp);
    dut->rst_n = 1;

    // Drive stimulus
    for (int i = 0; i < 50; i++) {
        dut->en = (i % 3) != 0;      // occasionally disable
        dut->x  = (uint8_t)(i * 5);
        dut->y  = (uint8_t)(200 - i * 3);
        tick(dut, tfp);
    }

    tfp->close();
    delete tfp;
    delete dut;
    return 0;
}