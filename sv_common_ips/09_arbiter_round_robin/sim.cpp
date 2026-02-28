#include "Vtop.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#include <algorithm>
#include <array>
#include <cstdint>
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

struct RefArbiter {
    uint8_t rr_ptr = 0;

    uint8_t grant_for(uint8_t req) const {
        for (int off = 0; off < 4; off++) {
            const uint8_t idx = static_cast<uint8_t>((rr_ptr + off) & 0x3u);
            if (req & (1u << idx)) {
                return static_cast<uint8_t>(1u << idx);
            }
        }
        return 0;
    }

    void update_after_grant(uint8_t grant) {
        if (!grant) return;

        uint8_t idx = 0;
        while (((grant >> idx) & 0x1u) == 0u) idx++;
        rr_ptr = static_cast<uint8_t>((idx + 1u) & 0x3u);
    }
};

static uint8_t random_req(std::mt19937& rng) {
    std::uniform_int_distribution<int> pct(0, 99);
    std::uniform_int_distribution<int> req_dist(0, 15);

    // Bias toward contention so round-robin behavior is visible often.
    if (pct(rng) < 35) {
        return 0xFu;
    }

    return static_cast<uint8_t>(req_dist(rng));
}

static bool run_cycle(
    Vtop* dut,
    VerilatedVcdC* tfp,
    RefArbiter* ref,
    uint8_t req,
    int cycle,
    std::array<int, 4>* grant_count,
    std::array<int, 4>* wait_now,
    std::array<int, 4>* max_wait,
    int* checks
) {
    dut->req = req;

    // Combinational check against the reference model before edge.
    dut->eval();
    const uint8_t expected = ref->grant_for(req);
    const uint8_t got = static_cast<uint8_t>(dut->gnt & 0xFu);

    if (got != expected) {
        std::cerr << "[cycle " << cycle << "] GRANT MISMATCH: req=0x"
                  << std::hex << static_cast<int>(req)
                  << " expected=0x" << static_cast<int>(expected)
                  << " got=0x" << static_cast<int>(got)
                  << std::dec << "\n";
        return false;
    }

    // Track wait/grant stats per requester.
    for (int i = 0; i < 4; i++) {
        const bool ri = ((req >> i) & 0x1u) != 0u;
        const bool gi = ((expected >> i) & 0x1u) != 0u;

        if (ri && !gi) {
            (*wait_now)[i]++;
            (*max_wait)[i] = std::max((*max_wait)[i], (*wait_now)[i]);
        }

        if (gi) {
            (*grant_count)[i]++;
            (*wait_now)[i] = 0;
        }

        if (!ri) {
            (*wait_now)[i] = 0;
        }
    }

    // Move design and reference model together.
    tick(dut, tfp);
    ref->update_after_grant(expected);

    (*checks)++;
    return true;
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    Vtop* dut = new Vtop;

    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    dut->trace(tfp, 99);
    tfp->open("waveform.vcd");

    std::mt19937 rng(0xA61Bu);
    RefArbiter ref;

    std::array<int, 4> grant_count = {0, 0, 0, 0};
    std::array<int, 4> wait_now = {0, 0, 0, 0};
    std::array<int, 4> max_wait = {0, 0, 0, 0};

    int checks = 0;

    // Reset
    dut->rst_n = 0;
    dut->req = 0;
    for (int i = 0; i < 5; i++) tick(dut, tfp);
    dut->rst_n = 1;

    // Directed contention: all requesters active.
    for (int cycle = 0; cycle < 24; cycle++) {
        if (!run_cycle(dut, tfp, &ref, 0xFu, cycle,
                       &grant_count, &wait_now, &max_wait, &checks)) {
            tfp->close();
            delete tfp;
            delete dut;
            return 1;
        }
    }

    // Random traffic phase.
    for (int cycle = 24; cycle < 260; cycle++) {
        const uint8_t req = random_req(rng);
        if (!run_cycle(dut, tfp, &ref, req, cycle,
                       &grant_count, &wait_now, &max_wait, &checks)) {
            tfp->close();
            delete tfp;
            delete dut;
            return 1;
        }
    }

    std::cout << "PASS: checks=" << checks << "\n";
    std::cout << "Grant count per requester: ["
              << grant_count[0] << ", "
              << grant_count[1] << ", "
              << grant_count[2] << ", "
              << grant_count[3] << "]\n";
    std::cout << "Max consecutive wait per requester: ["
              << max_wait[0] << ", "
              << max_wait[1] << ", "
              << max_wait[2] << ", "
              << max_wait[3] << "]\n";

    tfp->close();
    delete tfp;
    delete dut;
    return 0;
}
