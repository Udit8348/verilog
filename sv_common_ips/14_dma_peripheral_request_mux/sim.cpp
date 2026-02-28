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

static Req random_req(std::mt19937& rng, int req_pct) {
    std::uniform_int_distribution<int> pct(0, 99);
    std::uniform_int_distribution<int> bit(0, 1);
    std::uniform_int_distribution<int> addr_dist(0, 15);
    std::uniform_int_distribution<int> data_dist(0, 65535);

    Req r;
    r.req = pct(rng) < req_pct;
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

    std::array<uint16_t, 16> regs = {};
    for (int i = 0; i < 16; i++) regs[i] = static_cast<uint16_t>(0x2000u + i);

    bool dma_rr_ptr = false;
    int cpu_grants = 0;
    int dma0_grants = 0;
    int dma1_grants = 0;
    int cpu_preemptions = 0;
    int checks = 0;

    std::mt19937 rng(0x1414u);

    // Reset
    dut->rst_n = 0;
    dut->cpu_req = 0;
    dut->cpu_we = 0;
    dut->cpu_addr = 0;
    dut->cpu_wdata = 0;
    dut->dma0_req = 0;
    dut->dma0_we = 0;
    dut->dma0_addr = 0;
    dut->dma0_wdata = 0;
    dut->dma1_req = 0;
    dut->dma1_we = 0;
    dut->dma1_addr = 0;
    dut->dma1_wdata = 0;
    for (int i = 0; i < 5; i++) tick(dut, tfp);
    dut->rst_n = 1;

    for (int cycle = 0; cycle < 280; cycle++) {
        Req cpu = random_req(rng, 35);
        Req dma0 = random_req(rng, 70);
        Req dma1 = random_req(rng, 70);

        dut->cpu_req = cpu.req;
        dut->cpu_we = cpu.we;
        dut->cpu_addr = cpu.addr;
        dut->cpu_wdata = cpu.wdata;

        dut->dma0_req = dma0.req;
        dut->dma0_we = dma0.we;
        dut->dma0_addr = dma0.addr;
        dut->dma0_wdata = dma0.wdata;

        dut->dma1_req = dma1.req;
        dut->dma1_we = dma1.we;
        dut->dma1_addr = dma1.addr;
        dut->dma1_wdata = dma1.wdata;

        uint8_t exp_grant = 0;
        if (cpu.req) {
            exp_grant = 0x1u;
            if (dma0.req || dma1.req) cpu_preemptions++;
        } else if (dma0.req && dma1.req) {
            exp_grant = dma_rr_ptr ? 0x4u : 0x2u;
        } else if (dma0.req) {
            exp_grant = 0x2u;
        } else if (dma1.req) {
            exp_grant = 0x4u;
        }

        dut->eval();
        const uint8_t got_grant = static_cast<uint8_t>(dut->grant & 0x7u);
        if (got_grant != exp_grant) {
            std::cerr << "[cycle " << cycle << "] GRANT mismatch\n";
            tfp->close();
            delete tfp;
            delete dut;
            return 1;
        }

        bool check_rdata = false;
        uint16_t exp_rdata = 0;
        int who = -1;

        if (exp_grant & 0x1u) {
            who = 0;
            cpu_grants++;
            if (cpu.we) regs[cpu.addr] = cpu.wdata;
            else {
                exp_rdata = regs[cpu.addr];
                check_rdata = true;
            }
        } else if (exp_grant & 0x2u) {
            who = 1;
            dma0_grants++;
            if (dma0.we) regs[dma0.addr] = dma0.wdata;
            else {
                exp_rdata = regs[dma0.addr];
                check_rdata = true;
            }
            dma_rr_ptr = true;
        } else if (exp_grant & 0x4u) {
            who = 2;
            dma1_grants++;
            if (dma1.we) regs[dma1.addr] = dma1.wdata;
            else {
                exp_rdata = regs[dma1.addr];
                check_rdata = true;
            }
            dma_rr_ptr = false;
        }

        tick(dut, tfp);

        if (static_cast<int>(dut->cpu_ready) != ((exp_grant & 0x1u) ? 1 : 0) ||
            static_cast<int>(dut->dma0_ready) != ((exp_grant & 0x2u) ? 1 : 0) ||
            static_cast<int>(dut->dma1_ready) != ((exp_grant & 0x4u) ? 1 : 0)) {
            std::cerr << "[cycle " << cycle << "] ready mismatch\n";
            tfp->close();
            delete tfp;
            delete dut;
            return 1;
        }

        if (check_rdata) {
            uint16_t got = 0;
            if (who == 0) got = static_cast<uint16_t>(dut->cpu_rdata);
            if (who == 1) got = static_cast<uint16_t>(dut->dma0_rdata);
            if (who == 2) got = static_cast<uint16_t>(dut->dma1_rdata);

            if (got != exp_rdata) {
                std::cerr << "[cycle " << cycle << "] rdata mismatch\n";
                tfp->close();
                delete tfp;
                delete dut;
                return 1;
            }
            checks++;
        }
    }

    std::cout << "PASS: checks=" << checks << "\n";
    std::cout << "grants(cpu,dma0,dma1)=(" << cpu_grants << ", " << dma0_grants << ", " << dma1_grants << ")\n";
    std::cout << "cpu_preemptions=" << cpu_preemptions << "\n";

    tfp->close();
    delete tfp;
    delete dut;
    return 0;
}
