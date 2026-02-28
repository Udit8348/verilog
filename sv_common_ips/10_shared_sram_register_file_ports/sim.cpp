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

struct Req {
    bool req;
    bool we;
    uint8_t addr;
    uint16_t wdata;
};

static Req random_req(std::mt19937& rng) {
    std::uniform_int_distribution<int> pct(0, 99);
    std::uniform_int_distribution<int> bit(0, 1);
    std::uniform_int_distribution<int> addr_dist(0, 15);
    std::uniform_int_distribution<int> data_dist(0, 65535);

    Req r;
    r.req = pct(rng) < 65;
    r.we = bit(rng) != 0;
    r.addr = static_cast<uint8_t>(addr_dist(rng));
    r.wdata = static_cast<uint16_t>(data_dist(rng));
    return r;
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    Vtop* dut = new Vtop;
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    dut->trace(tfp, 99);
    tfp->open("waveform.vcd");

    std::array<uint16_t, 16> mem = {};
    for (int i = 0; i < 16; i++) mem[i] = static_cast<uint16_t>(0x1000u + i);

    bool rr_turn = false;
    std::mt19937 rng(0x1010u);
    int checks = 0;

    // Reset
    dut->rst_n = 0;
    dut->c0_req = 0;
    dut->c1_req = 0;
    dut->c0_we = 0;
    dut->c1_we = 0;
    dut->c0_addr = 0;
    dut->c1_addr = 0;
    dut->c0_wdata = 0;
    dut->c1_wdata = 0;
    for (int i = 0; i < 5; i++) tick(dut, tfp);
    dut->rst_n = 1;

    for (int cycle = 0; cycle < 260; cycle++) {
        Req c0 = random_req(rng);
        Req c1 = random_req(rng);

        dut->c0_req = c0.req;
        dut->c0_we = c0.we;
        dut->c0_addr = c0.addr;
        dut->c0_wdata = c0.wdata;

        dut->c1_req = c1.req;
        dut->c1_we = c1.we;
        dut->c1_addr = c1.addr;
        dut->c1_wdata = c1.wdata;

        uint8_t expected_grant = 0;
        if (c0.req && c1.req) {
            expected_grant = rr_turn ? 0x2u : 0x1u;
        } else if (c0.req) {
            expected_grant = 0x1u;
        } else if (c1.req) {
            expected_grant = 0x2u;
        }

        dut->eval();
        const uint8_t got_grant = static_cast<uint8_t>(dut->grant & 0x3u);
        if (got_grant != expected_grant) {
            std::cerr << "[cycle " << cycle << "] GRANT mismatch: expected="
                      << static_cast<int>(expected_grant)
                      << " got=" << static_cast<int>(got_grant) << "\n";
            tfp->close();
            delete tfp;
            delete dut;
            return 1;
        }

        const bool g0 = (expected_grant & 0x1u) != 0u;
        const bool g1 = (expected_grant & 0x2u) != 0u;

        uint16_t expected_rdata0 = 0;
        uint16_t expected_rdata1 = 0;
        bool check_rdata0 = false;
        bool check_rdata1 = false;

        if (g0) {
            if (c0.we) {
                mem[c0.addr] = c0.wdata;
            } else {
                expected_rdata0 = mem[c0.addr];
                check_rdata0 = true;
            }
            rr_turn = true;
        }

        if (g1) {
            if (c1.we) {
                mem[c1.addr] = c1.wdata;
            } else {
                expected_rdata1 = mem[c1.addr];
                check_rdata1 = true;
            }
            rr_turn = false;
        }

        tick(dut, tfp);

        if (static_cast<int>(dut->c0_ready) != static_cast<int>(g0)) {
            std::cerr << "[cycle " << cycle << "] c0_ready mismatch\n";
            tfp->close();
            delete tfp;
            delete dut;
            return 1;
        }

        if (static_cast<int>(dut->c1_ready) != static_cast<int>(g1)) {
            std::cerr << "[cycle " << cycle << "] c1_ready mismatch\n";
            tfp->close();
            delete tfp;
            delete dut;
            return 1;
        }

        if (check_rdata0) {
            const uint16_t got = static_cast<uint16_t>(dut->c0_rdata);
            if (got != expected_rdata0) {
                std::cerr << "[cycle " << cycle << "] c0_rdata mismatch: expected="
                          << expected_rdata0 << " got=" << got << "\n";
                tfp->close();
                delete tfp;
                delete dut;
                return 1;
            }
            checks++;
        }

        if (check_rdata1) {
            const uint16_t got = static_cast<uint16_t>(dut->c1_rdata);
            if (got != expected_rdata1) {
                std::cerr << "[cycle " << cycle << "] c1_rdata mismatch: expected="
                          << expected_rdata1 << " got=" << got << "\n";
                tfp->close();
                delete tfp;
                delete dut;
                return 1;
            }
            checks++;
        }
    }

    std::cout << "PASS: checks=" << checks << "\n";

    tfp->close();
    delete tfp;
    delete dut;
    return 0;
}
