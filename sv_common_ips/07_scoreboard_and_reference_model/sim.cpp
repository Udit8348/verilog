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

struct Txn {
    bool in_valid;
    bool out_ready;
    uint8_t in_data;
};

static Txn make_txn(std::mt19937& rng) {
    std::uniform_int_distribution<int> pct(0, 99);
    std::uniform_int_distribution<int> byte_dist(0, 255);

    Txn t;
    t.in_valid = pct(rng) < 65;
    t.out_ready = pct(rng) < 55;
    t.in_data = static_cast<uint8_t>(byte_dist(rng));
    return t;
}

static bool apply_and_check_cycle(
    Vtop* dut,
    VerilatedVcdC* tfp,
    std::deque<uint8_t>& ref_fifo,
    const Txn& t,
    int cycle,
    int* checks
) {
    dut->in_valid = t.in_valid;
    dut->out_ready = t.out_ready;
    dut->in_data = t.in_data;

    // Evaluate combinational outputs before the active clock edge.
    dut->eval();

    const bool push_fire = (dut->in_valid && dut->in_ready);
    const bool pop_fire = (dut->out_ready && dut->out_valid);

    if (pop_fire) {
        if (ref_fifo.empty()) {
            std::cerr << "[cycle " << cycle << "] Scoreboard underflow\n";
            return false;
        }

        const uint8_t expected = ref_fifo.front();
        const uint8_t got = static_cast<uint8_t>(dut->out_data);
        if (expected != got) {
            std::cerr << "[cycle " << cycle << "] DATA MISMATCH: expected="
                      << static_cast<int>(expected)
                      << " got=" << static_cast<int>(got) << "\n";
            return false;
        }

        ref_fifo.pop_front();
        (*checks)++;
    }

    if (push_fire) {
        ref_fifo.push_back(static_cast<uint8_t>(dut->in_data));
        (*checks)++;
    }

    tick(dut, tfp);

    // Check occupancy against the reference model every cycle.
    if (static_cast<int>(dut->count) != static_cast<int>(ref_fifo.size())) {
        std::cerr << "[cycle " << cycle << "] COUNT MISMATCH: dut="
                  << static_cast<int>(dut->count)
                  << " ref=" << ref_fifo.size() << "\n";
        return false;
    }

    return true;
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    Vtop* dut = new Vtop;

    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    dut->trace(tfp, 99);
    tfp->open("waveform.vcd");

    std::deque<uint8_t> ref_fifo;
    std::mt19937 rng(0x5A17u);

    int checks = 0;

    // Reset
    dut->rst_n = 0;
    dut->in_valid = 0;
    dut->in_data = 0;
    dut->out_ready = 0;
    for (int i = 0; i < 5; i++) tick(dut, tfp);

    dut->rst_n = 1;

    // Randomized traffic with self-checking scoreboard.
    for (int cycle = 0; cycle < 220; cycle++) {
        const Txn t = make_txn(rng);
        if (!apply_and_check_cycle(dut, tfp, ref_fifo, t, cycle, &checks)) {
            tfp->close();
            delete tfp;
            delete dut;
            return 1;
        }
    }

    // Drain remaining contents to verify end-to-end ordering.
    int drain_cycle = 220;
    while (!ref_fifo.empty()) {
        Txn t;
        t.in_valid = false;
        t.out_ready = true;
        t.in_data = 0;

        if (!apply_and_check_cycle(dut, tfp, ref_fifo, t, drain_cycle++, &checks)) {
            tfp->close();
            delete tfp;
            delete dut;
            return 1;
        }

        if (drain_cycle > 400) {
            std::cerr << "Drain timeout\n";
            tfp->close();
            delete tfp;
            delete dut;
            return 1;
        }
    }

    std::cout << "PASS: scoreboard checks=" << checks << "\n";

    tfp->close();
    delete tfp;
    delete dut;
    return 0;
}
