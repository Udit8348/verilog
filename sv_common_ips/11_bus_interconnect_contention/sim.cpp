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

struct BusReq {
    bool valid;
    bool we;
    uint8_t addr;
    uint32_t wdata;
};

static BusReq random_req(std::mt19937& rng) {
    std::uniform_int_distribution<int> pct(0, 99);
    std::uniform_int_distribution<int> bit(0, 1);
    std::uniform_int_distribution<int> addr_dist(0, 3);
    std::uniform_int_distribution<uint32_t> data_dist(0, 0xFFFFu);

    BusReq r;
    r.valid = pct(rng) < 60;
    r.we = bit(rng) != 0;
    r.addr = static_cast<uint8_t>(addr_dist(rng));
    r.wdata = data_dist(rng);
    return r;
}

static uint8_t expected_grant(uint8_t valid, uint8_t rr_ptr) {
    for (int off = 0; off < 3; off++) {
        int idx = static_cast<int>(rr_ptr) + off;
        if (idx >= 3) idx -= 3;
        if ((valid >> idx) & 0x1u) {
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

    std::array<uint32_t, 4> regs = {0x1000u, 0x1001u, 0x1002u, 0x1003u};
    std::array<int, 3> grant_count = {0, 0, 0};
    uint8_t rr_ptr = 0;

    std::mt19937 rng(0x1111u);
    int checks = 0;

    // Reset
    dut->rst_n = 0;
    dut->m0_valid = 0;
    dut->m1_valid = 0;
    dut->m2_valid = 0;
    dut->m0_we = 0;
    dut->m1_we = 0;
    dut->m2_we = 0;
    dut->m0_addr = 0;
    dut->m1_addr = 0;
    dut->m2_addr = 0;
    dut->m0_wdata = 0;
    dut->m1_wdata = 0;
    dut->m2_wdata = 0;
    for (int i = 0; i < 5; i++) tick(dut, tfp);
    dut->rst_n = 1;

    for (int cycle = 0; cycle < 280; cycle++) {
        BusReq m0 = random_req(rng);
        BusReq m1 = random_req(rng);
        BusReq m2 = random_req(rng);

        dut->m0_valid = m0.valid;
        dut->m0_we = m0.we;
        dut->m0_addr = m0.addr;
        dut->m0_wdata = m0.wdata;

        dut->m1_valid = m1.valid;
        dut->m1_we = m1.we;
        dut->m1_addr = m1.addr;
        dut->m1_wdata = m1.wdata;

        dut->m2_valid = m2.valid;
        dut->m2_we = m2.we;
        dut->m2_addr = m2.addr;
        dut->m2_wdata = m2.wdata;

        const uint8_t valid_bits =
            (static_cast<uint8_t>(m2.valid) << 2) |
            (static_cast<uint8_t>(m1.valid) << 1) |
            (static_cast<uint8_t>(m0.valid) << 0);

        const uint8_t exp_gnt = expected_grant(valid_bits, rr_ptr);

        dut->eval();
        const uint8_t got_gnt = static_cast<uint8_t>(dut->grant & 0x7u);
        if (got_gnt != exp_gnt) {
            std::cerr << "[cycle " << cycle << "] GRANT mismatch: expected="
                      << static_cast<int>(exp_gnt)
                      << " got=" << static_cast<int>(got_gnt) << "\n";
            tfp->close();
            delete tfp;
            delete dut;
            return 1;
        }

        bool check_rdata = false;
        int grant_idx = -1;
        uint32_t exp_rdata = 0;

        if (exp_gnt & 0x1u) {
            grant_idx = 0;
            grant_count[0]++;
            if (m0.we) regs[m0.addr] = m0.wdata;
            else {
                exp_rdata = regs[m0.addr];
                check_rdata = true;
            }
            rr_ptr = 1;
        } else if (exp_gnt & 0x2u) {
            grant_idx = 1;
            grant_count[1]++;
            if (m1.we) regs[m1.addr] = m1.wdata;
            else {
                exp_rdata = regs[m1.addr];
                check_rdata = true;
            }
            rr_ptr = 2;
        } else if (exp_gnt & 0x4u) {
            grant_idx = 2;
            grant_count[2]++;
            if (m2.we) regs[m2.addr] = m2.wdata;
            else {
                exp_rdata = regs[m2.addr];
                check_rdata = true;
            }
            rr_ptr = 0;
        }

        tick(dut, tfp);

        if (static_cast<int>(dut->m0_ready) != ((exp_gnt & 0x1u) ? 1 : 0)) {
            std::cerr << "[cycle " << cycle << "] m0_ready mismatch\n";
            tfp->close();
            delete tfp;
            delete dut;
            return 1;
        }
        if (static_cast<int>(dut->m1_ready) != ((exp_gnt & 0x2u) ? 1 : 0)) {
            std::cerr << "[cycle " << cycle << "] m1_ready mismatch\n";
            tfp->close();
            delete tfp;
            delete dut;
            return 1;
        }
        if (static_cast<int>(dut->m2_ready) != ((exp_gnt & 0x4u) ? 1 : 0)) {
            std::cerr << "[cycle " << cycle << "] m2_ready mismatch\n";
            tfp->close();
            delete tfp;
            delete dut;
            return 1;
        }

        if (check_rdata) {
            uint32_t got = 0;
            if (grant_idx == 0) got = static_cast<uint32_t>(dut->m0_rdata);
            if (grant_idx == 1) got = static_cast<uint32_t>(dut->m1_rdata);
            if (grant_idx == 2) got = static_cast<uint32_t>(dut->m2_rdata);

            if (got != exp_rdata) {
                std::cerr << "[cycle " << cycle << "] rdata mismatch: expected="
                          << exp_rdata << " got=" << got << "\n";
                tfp->close();
                delete tfp;
                delete dut;
                return 1;
            }
            checks++;
        }
    }

    std::cout << "PASS: checks=" << checks
              << " grants=[" << grant_count[0] << ", "
              << grant_count[1] << ", "
              << grant_count[2] << "]\n";

    tfp->close();
    delete tfp;
    delete dut;
    return 0;
}
