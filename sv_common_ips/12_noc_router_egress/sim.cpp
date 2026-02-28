#include "Vtop.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

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

struct VCStim {
    bool valid;
    uint8_t flit;
};

static VCStim random_vc(std::mt19937& rng) {
    std::uniform_int_distribution<int> pct(0, 99);
    std::uniform_int_distribution<int> flit_dist(0, 255);
    VCStim s;
    s.valid = pct(rng) < 60;
    s.flit = static_cast<uint8_t>(flit_dist(rng));
    return s;
}

static uint8_t expected_grant(uint8_t valid_bits, bool credit, uint8_t rr_ptr) {
    if (!credit) return 0;

    for (int off = 0; off < 4; off++) {
        int idx = static_cast<int>(rr_ptr) + off;
        if (idx >= 4) idx -= 4;
        if ((valid_bits >> idx) & 0x1u) {
            return static_cast<uint8_t>(1u << idx);
        }
    }
    return 0;
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    Vtop* dut = new Vtop;
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    dut->trace(tfp, 99);
    tfp->open("waveform.vcd");

    std::array<int, 4> sent_count = {0, 0, 0, 0};
    std::mt19937 rng(0x1212u);
    uint8_t rr_ptr = 0;

    // Reset
    dut->rst_n = 0;
    dut->vc0_valid = 0;
    dut->vc1_valid = 0;
    dut->vc2_valid = 0;
    dut->vc3_valid = 0;
    dut->vc0_flit = 0;
    dut->vc1_flit = 0;
    dut->vc2_flit = 0;
    dut->vc3_flit = 0;
    dut->egr_credit = 0;
    for (int i = 0; i < 5; i++) tick(dut, tfp);
    dut->rst_n = 1;

    int checks = 0;

    for (int cycle = 0; cycle < 280; cycle++) {
        VCStim vc0 = random_vc(rng);
        VCStim vc1 = random_vc(rng);
        VCStim vc2 = random_vc(rng);
        VCStim vc3 = random_vc(rng);

        std::uniform_int_distribution<int> pct(0, 99);
        const bool credit = pct(rng) < 70;

        dut->vc0_valid = vc0.valid;
        dut->vc0_flit = vc0.flit;
        dut->vc1_valid = vc1.valid;
        dut->vc1_flit = vc1.flit;
        dut->vc2_valid = vc2.valid;
        dut->vc2_flit = vc2.flit;
        dut->vc3_valid = vc3.valid;
        dut->vc3_flit = vc3.flit;
        dut->egr_credit = credit;

        const uint8_t valid_bits =
            (static_cast<uint8_t>(vc3.valid) << 3) |
            (static_cast<uint8_t>(vc2.valid) << 2) |
            (static_cast<uint8_t>(vc1.valid) << 1) |
            (static_cast<uint8_t>(vc0.valid) << 0);

        const uint8_t exp_gnt = expected_grant(valid_bits, credit, rr_ptr);

        dut->eval();

        const uint8_t got_gnt = static_cast<uint8_t>(dut->grant & 0xFu);
        if (got_gnt != exp_gnt) {
            std::cerr << "[cycle " << cycle << "] GRANT mismatch: expected="
                      << static_cast<int>(exp_gnt)
                      << " got=" << static_cast<int>(got_gnt) << "\n";
            tfp->close();
            delete tfp;
            delete dut;
            return 1;
        }

        const bool exp_valid = exp_gnt != 0;
        if (static_cast<int>(dut->egr_valid) != static_cast<int>(exp_valid)) {
            std::cerr << "[cycle " << cycle << "] egr_valid mismatch\n";
            tfp->close();
            delete tfp;
            delete dut;
            return 1;
        }

        if (exp_valid) {
            uint8_t exp_vc = 0;
            if (exp_gnt & 0x1u) exp_vc = 0;
            if (exp_gnt & 0x2u) exp_vc = 1;
            if (exp_gnt & 0x4u) exp_vc = 2;
            if (exp_gnt & 0x8u) exp_vc = 3;

            if (static_cast<uint8_t>(dut->egr_vc & 0x3u) != exp_vc) {
                std::cerr << "[cycle " << cycle << "] egr_vc mismatch\n";
                tfp->close();
                delete tfp;
                delete dut;
                return 1;
            }

            uint8_t exp_flit = 0;
            if (exp_vc == 0) exp_flit = vc0.flit;
            if (exp_vc == 1) exp_flit = vc1.flit;
            if (exp_vc == 2) exp_flit = vc2.flit;
            if (exp_vc == 3) exp_flit = vc3.flit;

            if (static_cast<uint8_t>(dut->egr_flit) != exp_flit) {
                std::cerr << "[cycle " << cycle << "] egr_flit mismatch\n";
                tfp->close();
                delete tfp;
                delete dut;
                return 1;
            }

            sent_count[exp_vc]++;
            rr_ptr = static_cast<uint8_t>((exp_vc + 1) & 0x3u);
            checks++;
        }

        tick(dut, tfp);
    }

    std::cout << "PASS: checks=" << checks
              << " sent=[" << sent_count[0] << ", "
              << sent_count[1] << ", "
              << sent_count[2] << ", "
              << sent_count[3] << "]\n";

    tfp->close();
    delete tfp;
    delete dut;
    return 0;
}
