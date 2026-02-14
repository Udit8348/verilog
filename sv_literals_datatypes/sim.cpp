// sim.cpp - Lesson 01
//
// This is a minimal Verilator C++ harness that:
//  - toggles clk
//  - applies reset
//  - drives in_u8 / in_s8
//  - dumps a VCD waveform
//
// Run: ./run.sh then open waveform.vcd in GTKWave.

#include "Vtop.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

static vluint64_t main_time = 0;
double sc_time_stamp() { return (double)main_time; }

static void tick(Vtop* dut, VerilatedVcdC* tfp) {
    // Rising edge
    dut->clk = 0;
    dut->eval();
    if (tfp) tfp->dump(main_time++);
    dut->clk = 1;
    dut->eval();
    if (tfp) tfp->dump(main_time++);
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    Vtop* dut = new Vtop;

    // Enable tracing
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    dut->trace(tfp, 99);
    tfp->open("waveform.vcd");

    // Reset
    dut->rst_n = 0;
    dut->in_u8 = 0;
    dut->in_s8 = 0;
    for (int i = 0; i < 5; i++) tick(dut, tfp);

    // Deassert reset
    dut->rst_n = 1;

    // Drive a few values
    for (int i = 0; i < 40; i++) {
        // Unsigned ramp
        dut->in_u8 = (uint8_t)(i * 7);

        // Signed pattern: alternate negative/positive
        int8_t s = (i & 1) ? (int8_t)(-i) : (int8_t)(i);
        dut->in_s8 = (uint8_t)s; // Verilator ports are packed bits; assign via uint8_t

        tick(dut, tfp);
    }

    tfp->close();
    delete tfp;
    delete dut;
    return 0;
}