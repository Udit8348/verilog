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

struct RefillEnt {
    uint8_t addr;
    uint32_t data;
};

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    Vtop* dut = new Vtop;
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    dut->trace(tfp, 99);
    tfp->open("waveform.vcd");

    std::mt19937 rng(0x1515u);
    std::uniform_int_distribution<int> pct(0, 99);
    std::uniform_int_distribution<int> addr_dist(0, 255);
    std::uniform_int_distribution<uint32_t> data_dist(0, 0x00FFFFFFu);

    std::deque<uint8_t> miss_q;
    std::deque<RefillEnt> refill_q;

    int issue_checks = 0;
    int refill_issues = 0;
    int miss_issues = 0;

    // Reset
    dut->rst_n = 0;
    dut->miss_push = 0;
    dut->miss_addr_in = 0;
    dut->refill_push = 0;
    dut->refill_addr_in = 0;
    dut->refill_data_in = 0;
    dut->mem_ready = 0;
    for (int i = 0; i < 5; i++) tick(dut, tfp);
    dut->rst_n = 1;

    for (int cycle = 0; cycle < 320; cycle++) {
        const bool mem_ready = pct(rng) < 70;

        const bool miss_full = (miss_q.size() >= 4);
        const bool refill_full = (refill_q.size() >= 4);

        const bool miss_push = (!miss_full) && (pct(rng) < 45);
        const bool refill_push = (!refill_full) && (pct(rng) < 45);

        const uint8_t miss_addr_in = static_cast<uint8_t>(addr_dist(rng));
        const uint8_t refill_addr_in = static_cast<uint8_t>(addr_dist(rng));
        const uint32_t refill_data_in = data_dist(rng);

        dut->miss_push = miss_push;
        dut->miss_addr_in = miss_addr_in;
        dut->refill_push = refill_push;
        dut->refill_addr_in = refill_addr_in;
        dut->refill_data_in = refill_data_in;
        dut->mem_ready = mem_ready;

        const bool exp_issue = mem_ready && (!refill_q.empty() || !miss_q.empty());
        const bool exp_is_refill = mem_ready && !refill_q.empty();
        const uint8_t exp_addr = exp_is_refill
                                     ? refill_q.front().addr
                                     : ((!miss_q.empty() && mem_ready) ? miss_q.front() : 0);
        const uint32_t exp_data = exp_is_refill ? refill_q.front().data : 0u;

        dut->eval();

        if (static_cast<int>(dut->issue_valid) != static_cast<int>(exp_issue)) {
            std::cerr << "[cycle " << cycle << "] issue_valid mismatch\n";
            tfp->close();
            delete tfp;
            delete dut;
            return 1;
        }

        if (exp_issue) {
            if (static_cast<int>(dut->issue_is_refill) != static_cast<int>(exp_is_refill)) {
                std::cerr << "[cycle " << cycle << "] issue_is_refill mismatch\n";
                tfp->close();
                delete tfp;
                delete dut;
                return 1;
            }

            if (static_cast<uint8_t>(dut->issue_addr) != exp_addr) {
                std::cerr << "[cycle " << cycle << "] issue_addr mismatch\n";
                tfp->close();
                delete tfp;
                delete dut;
                return 1;
            }

            if (exp_is_refill && static_cast<uint32_t>(dut->issue_wdata) != exp_data) {
                std::cerr << "[cycle " << cycle << "] issue_wdata mismatch\n";
                tfp->close();
                delete tfp;
                delete dut;
                return 1;
            }

            issue_checks++;
        }

        // Mirror DUT update behavior: pushes then pops.
        if (miss_push && !miss_full) {
            miss_q.push_back(miss_addr_in);
        }

        if (refill_push && !refill_full) {
            refill_q.push_back({refill_addr_in, refill_data_in});
        }

        if (exp_issue) {
            if (exp_is_refill) {
                refill_q.pop_front();
                refill_issues++;
            } else {
                miss_q.pop_front();
                miss_issues++;
            }
        }

        tick(dut, tfp);

        if (static_cast<int>(dut->miss_count) != static_cast<int>(miss_q.size())) {
            std::cerr << "[cycle " << cycle << "] miss_count mismatch\n";
            tfp->close();
            delete tfp;
            delete dut;
            return 1;
        }

        if (static_cast<int>(dut->refill_count) != static_cast<int>(refill_q.size())) {
            std::cerr << "[cycle " << cycle << "] refill_count mismatch\n";
            tfp->close();
            delete tfp;
            delete dut;
            return 1;
        }
    }

    std::cout << "PASS: checks=" << issue_checks
              << " refill_issues=" << refill_issues
              << " miss_issues=" << miss_issues << "\n";

    tfp->close();
    delete tfp;
    delete dut;
    return 0;
}
