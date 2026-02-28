#include "Vtop.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#include <cstdint>
#include <deque>
#include <iostream>
#include <random>

static vluint64_t main_time = 0;
double sc_time_stamp() { return (double)main_time; }

static void tick(Vtop* dut, VerilatedVcdC* tfp) {
    dut->clk = 0;
    dut->eval();
    if (tfp) tfp->dump(main_time++);

    dut->clk = 1;
    dut->eval();
    if (tfp) tfp->dump(main_time++);
}

static constexpr int kDepth = 8;

struct Stim {
    bool in_valid;
    bool out_ready;
    uint8_t in_data;
    int attempts;
};

static Stim gen_constrained_like(std::mt19937& rng, int model_used) {
    std::uniform_int_distribution<int> pct(0, 99);
    std::uniform_int_distribution<int> byte_dist(0, 255);

    int attempts = 0;
    while (true) {
        attempts++;

        Stim s;
        s.in_valid = pct(rng) < 70;
        s.out_ready = pct(rng) < 60;
        s.in_data = static_cast<uint8_t>(byte_dist(rng));
        s.attempts = attempts;

        // Constraint 1: do not push when model predicts full.
        const bool c_no_overflow = !(s.in_valid && (model_used >= kDepth));

        // Constraint 2: do not pop when model predicts empty.
        const bool c_no_underflow = !(s.out_ready && (model_used == 0));

        // Constraint 3: pushed data must be odd, not 0xFF, and upper nibble != 0xF.
        const bool c_data_shape =
            !s.in_valid ||
            (((s.in_data & 0x1u) == 1u) && (s.in_data != 0xFFu) && ((s.in_data >> 4) != 0xFu));

        if (c_no_overflow && c_no_underflow && c_data_shape) {
            return s;
        }
    }
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    Vtop* dut = new Vtop;

    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    dut->trace(tfp, 99);
    tfp->open("waveform.vcd");

    std::deque<uint8_t> ref_fifo;
    std::mt19937 rng(0x9C31u);

    int checks = 0;
    int generated = 0;
    int rejected = 0;

    // Reset
    dut->rst_n = 0;
    dut->in_valid = 0;
    dut->in_data = 0;
    dut->out_ready = 0;
    for (int i = 0; i < 5; i++) tick(dut, tfp);

    dut->rst_n = 1;

    for (int cycle = 0; cycle < 240; cycle++) {
        const Stim s = gen_constrained_like(rng, static_cast<int>(ref_fifo.size()));
        generated++;
        rejected += (s.attempts - 1);

        dut->in_valid = s.in_valid;
        dut->out_ready = s.out_ready;
        dut->in_data = s.in_data;

        dut->eval();

        // These should never fail because the generator constraints prevent it.
        if (dut->in_valid && !dut->in_ready) {
            std::cerr << "[cycle " << cycle << "] Unexpected push block at DUT boundary\n";
            tfp->close();
            delete tfp;
            delete dut;
            return 1;
        }

        if (dut->out_ready && !dut->out_valid) {
            std::cerr << "[cycle " << cycle << "] Unexpected pop block at DUT boundary\n";
            tfp->close();
            delete tfp;
            delete dut;
            return 1;
        }

        const bool push_fire = (dut->in_valid && dut->in_ready);
        const bool pop_fire = (dut->out_ready && dut->out_valid);

        if (pop_fire) {
            if (ref_fifo.empty()) {
                std::cerr << "[cycle " << cycle << "] Scoreboard underflow\n";
                tfp->close();
                delete tfp;
                delete dut;
                return 1;
            }

            const uint8_t expected = ref_fifo.front();
            const uint8_t got = static_cast<uint8_t>(dut->out_data);
            if (expected != got) {
                std::cerr << "[cycle " << cycle << "] DATA MISMATCH: expected="
                          << static_cast<int>(expected)
                          << " got=" << static_cast<int>(got) << "\n";
                tfp->close();
                delete tfp;
                delete dut;
                return 1;
            }

            ref_fifo.pop_front();
            checks++;
        }

        if (push_fire) {
            ref_fifo.push_back(static_cast<uint8_t>(dut->in_data));
            checks++;
        }

        tick(dut, tfp);

        if (static_cast<int>(dut->count) != static_cast<int>(ref_fifo.size())) {
            std::cerr << "[cycle " << cycle << "] COUNT MISMATCH: dut="
                      << static_cast<int>(dut->count)
                      << " ref=" << ref_fifo.size() << "\n";
            tfp->close();
            delete tfp;
            delete dut;
            return 1;
        }
    }

    // Drain with legal pops only.
    int drain_cycle = 240;
    while (!ref_fifo.empty()) {
        dut->in_valid = 0;
        dut->in_data = 0;
        dut->out_ready = 1;

        dut->eval();

        const bool pop_fire = (dut->out_ready && dut->out_valid);
        if (!pop_fire) {
            std::cerr << "[cycle " << drain_cycle << "] Drain expected pop but saw none\n";
            tfp->close();
            delete tfp;
            delete dut;
            return 1;
        }

        const uint8_t expected = ref_fifo.front();
        const uint8_t got = static_cast<uint8_t>(dut->out_data);
        if (expected != got) {
            std::cerr << "[cycle " << drain_cycle << "] DRAIN DATA MISMATCH: expected="
                      << static_cast<int>(expected)
                      << " got=" << static_cast<int>(got) << "\n";
            tfp->close();
            delete tfp;
            delete dut;
            return 1;
        }

        ref_fifo.pop_front();
        checks++;

        tick(dut, tfp);
        drain_cycle++;

        if (drain_cycle > 420) {
            std::cerr << "Drain timeout\n";
            tfp->close();
            delete tfp;
            delete dut;
            return 1;
        }
    }

    std::cout << "PASS: checks=" << checks
              << " generated=" << generated
              << " rejected_by_constraints=" << rejected << "\n";

    tfp->close();
    delete tfp;
    delete dut;
    return 0;
}
