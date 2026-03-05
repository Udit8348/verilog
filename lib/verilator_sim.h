#pragma once

#include <memory>
#include "verilated.h"
#include "verilated_vcd_c.h"

inline vluint64_t g_time = 0;
inline double sc_time_stamp() { return static_cast<double>(g_time); }

template <typename TDut>
class Sim {
public:
    Sim(int argc, char** argv) : dut_(std::make_unique<TDut>()) {
        Verilated::commandArgs(argc, argv);
    }
    
    // allow accessing raw verilator generated dut
    TDut* dut() { return dut_.get(); }

    // allow a cleaner interface which lets the sim "directly access" the dut ptr for its signals
    // achieved by overloading the -> operator making sim a wrapper over dut
    TDut* operator->() { return dut_.get(); }
    const TDut* operator->() const { return dut_.get(); }

    // safely open trace file handle at provided path (RAII)
    void open_trace(const char* vcd_path, int levels = 99) {
        Verilated::traceEverOn(true);
        tfp_ = std::make_unique<VerilatedVcdC>();
        dut_->trace(tfp_.get(), levels);
        tfp_->open(vcd_path);
    }

    // safely close the trace file handle (managed by dtor)
    void close_trace() {
        if (tfp_) {
            tfp_->close();
            tfp_.reset();
        }
    }

    // Combinational step: eval + dump + advance time
    void step(int n = 1) {
        for (int i = 0; i < n; i++) {
            dut_->eval();
            if (tfp_) tfp_->dump(g_time);
            g_time++;
        }
    }

    // Clocked tick: assumes dut has a port named 'clk' and models falling -> rising edge
    void tick(int cycles = 1) {
        for (int i = 0; i < cycles; i++) {
            dut_->clk = 0;
            step(1);
            dut_->clk = 1;
            step(1);
        }
    }

    ~Sim() { close_trace(); }

    // dont allow reassigning the sim obj once it is created
    Sim(const Sim&) = delete;
    Sim& operator=(const Sim&) = delete;

private:
    std::unique_ptr<TDut> dut_;
    std::unique_ptr<VerilatedVcdC> tfp_;
};