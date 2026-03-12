#pragma once

#include <memory>
#include <string>
#include "verilated.h"
#include "verilated_vcd_c.h"

inline vluint64_t g_time = 0;
inline double sc_time_stamp() { return static_cast<double>(g_time); }

struct Config {
    const std::string vcd_path;
    int levels = 99;
};

template <typename TDut>
class Sim {
public:
    Sim(int argc, char** argv, Config& _cfg) : dut_(std::make_unique<TDut>()), cfg(_cfg) {
        Verilated::commandArgs(argc, argv);

        if (!cfg.vcd_path.empty()) {
            open_trace(cfg.vcd_path, cfg.levels);
        }
    }
    
    TDut* dut() { return dut_.get(); }

    // allow a cleaner interface which lets the sim "directly access" the dut ptr for its signals
    // achieved by overloading the -> operator making sim a wrapper over dut
    TDut* operator->() { return dut_.get(); }
    const TDut* operator->() const { return dut_.get(); }

    // Combinational step
    void step(int n = 1) {
        for (int i = 0; i < n; i++) {
            dut_->eval();
            if (tfp_) tfp_->dump(g_time);
            g_time++;
        }
    }

    // Clocked tick
    void tick(int cycles = 1) {
        for (int i = 0; i < cycles; i++) {
            dut_->clk = 0;
            step(1);
            dut_->clk = 1;
            step(1);
        }
    }

    ~Sim() { close_trace(); }
    Sim(const Sim&) = delete;
    Sim& operator=(const Sim&) = delete;

private:
    std::unique_ptr<TDut> dut_;
    std::unique_ptr<VerilatedVcdC> tfp_;
    
    Config cfg;

    void open_trace(const std::string vcd_path, int levels = 99) {
        Verilated::traceEverOn(true);
        tfp_ = std::make_unique<VerilatedVcdC>();
        dut_->trace(tfp_.get(), levels);
        tfp_->open(vcd_path.c_str());
    }

    void close_trace() {
        if (tfp_) {
            tfp_->close();
            tfp_.reset();
        }
    }
};