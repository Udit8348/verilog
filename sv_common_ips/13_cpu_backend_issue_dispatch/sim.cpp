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

struct Slot {
    bool valid;
    bool is_mul;
    uint8_t tag;
};

static Slot random_slot(std::mt19937& rng) {
    std::uniform_int_distribution<int> pct(0, 99);
    std::uniform_int_distribution<int> bit(0, 1);
    std::uniform_int_distribution<int> tag_dist(0, 15);

    Slot s;
    s.valid = pct(rng) < 65;
    s.is_mul = bit(rng) != 0;
    s.tag = static_cast<uint8_t>(tag_dist(rng));
    return s;
}

static uint8_t rr_pick(const std::array<Slot, 3>& slots, bool pick_mul, bool unit_ready, uint8_t ptr) {
    if (!unit_ready) return 0;

    for (int off = 0; off < 3; off++) {
        int idx = static_cast<int>(ptr) + off;
        if (idx >= 3) idx -= 3;

        if (slots[idx].valid && (slots[idx].is_mul == pick_mul)) {
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

    std::mt19937 rng(0x1313u);
    uint8_t alu_ptr = 0;
    uint8_t mul_ptr = 0;

    std::array<int, 3> alu_issue_per_slot = {0, 0, 0};
    std::array<int, 3> mul_issue_per_slot = {0, 0, 0};

    int checks = 0;

    // Reset
    dut->rst_n = 0;
    dut->s0_valid = 0;
    dut->s1_valid = 0;
    dut->s2_valid = 0;
    dut->s0_is_mul = 0;
    dut->s1_is_mul = 0;
    dut->s2_is_mul = 0;
    dut->s0_tag = 0;
    dut->s1_tag = 0;
    dut->s2_tag = 0;
    dut->alu_ready = 0;
    dut->mul_ready = 0;
    for (int i = 0; i < 5; i++) tick(dut, tfp);
    dut->rst_n = 1;

    for (int cycle = 0; cycle < 300; cycle++) {
        Slot s0 = random_slot(rng);
        Slot s1 = random_slot(rng);
        Slot s2 = random_slot(rng);

        std::uniform_int_distribution<int> pct(0, 99);
        const bool alu_ready = pct(rng) < 75;
        const bool mul_ready = pct(rng) < 60;

        std::array<Slot, 3> slots = {s0, s1, s2};

        dut->s0_valid = s0.valid;
        dut->s0_is_mul = s0.is_mul;
        dut->s0_tag = s0.tag;

        dut->s1_valid = s1.valid;
        dut->s1_is_mul = s1.is_mul;
        dut->s1_tag = s1.tag;

        dut->s2_valid = s2.valid;
        dut->s2_is_mul = s2.is_mul;
        dut->s2_tag = s2.tag;

        dut->alu_ready = alu_ready;
        dut->mul_ready = mul_ready;

        const uint8_t exp_alu_gnt = rr_pick(slots, false, alu_ready, alu_ptr);
        const uint8_t exp_mul_gnt = rr_pick(slots, true, mul_ready, mul_ptr);

        dut->eval();

        const uint8_t got_alu_gnt = static_cast<uint8_t>(dut->alu_grant & 0x7u);
        const uint8_t got_mul_gnt = static_cast<uint8_t>(dut->mul_grant & 0x7u);

        if (got_alu_gnt != exp_alu_gnt) {
            std::cerr << "[cycle " << cycle << "] ALU grant mismatch\n";
            tfp->close();
            delete tfp;
            delete dut;
            return 1;
        }

        if (got_mul_gnt != exp_mul_gnt) {
            std::cerr << "[cycle " << cycle << "] MUL grant mismatch\n";
            tfp->close();
            delete tfp;
            delete dut;
            return 1;
        }

        if (exp_alu_gnt) {
            int idx = (exp_alu_gnt & 0x1u) ? 0 : ((exp_alu_gnt & 0x2u) ? 1 : 2);
            const uint8_t got_slot = static_cast<uint8_t>(dut->alu_issue_slot & 0x3u);
            const uint8_t got_tag = static_cast<uint8_t>(dut->alu_issue_tag & 0xFu);

            if (got_slot != static_cast<uint8_t>(idx) || got_tag != slots[idx].tag) {
                std::cerr << "[cycle " << cycle << "] ALU issue payload mismatch\n";
                tfp->close();
                delete tfp;
                delete dut;
                return 1;
            }

            alu_issue_per_slot[idx]++;
            alu_ptr = static_cast<uint8_t>((idx + 1) % 3);
            checks++;
        }

        if (exp_mul_gnt) {
            int idx = (exp_mul_gnt & 0x1u) ? 0 : ((exp_mul_gnt & 0x2u) ? 1 : 2);
            const uint8_t got_slot = static_cast<uint8_t>(dut->mul_issue_slot & 0x3u);
            const uint8_t got_tag = static_cast<uint8_t>(dut->mul_issue_tag & 0xFu);

            if (got_slot != static_cast<uint8_t>(idx) || got_tag != slots[idx].tag) {
                std::cerr << "[cycle " << cycle << "] MUL issue payload mismatch\n";
                tfp->close();
                delete tfp;
                delete dut;
                return 1;
            }

            mul_issue_per_slot[idx]++;
            mul_ptr = static_cast<uint8_t>((idx + 1) % 3);
            checks++;
        }

        tick(dut, tfp);
    }

    std::cout << "PASS: checks=" << checks << "\n";
    std::cout << "ALU issues per slot: ["
              << alu_issue_per_slot[0] << ", "
              << alu_issue_per_slot[1] << ", "
              << alu_issue_per_slot[2] << "]\n";
    std::cout << "MUL issues per slot: ["
              << mul_issue_per_slot[0] << ", "
              << mul_issue_per_slot[1] << ", "
              << mul_issue_per_slot[2] << "]\n";

    tfp->close();
    delete tfp;
    delete dut;
    return 0;
}
