// top.sv - Lesson 11
//
// Use-case:
//  - Multiple on-chip bus masters contending for one slave/register block.
//  - Round-robin arbitration across three masters.

module top (
    input  logic clk,
    input  logic rst_n,

    input  logic        m0_valid,
    input  logic        m0_we,
    input  logic [1:0]  m0_addr,
    input  logic [31:0] m0_wdata,
    output logic        m0_ready,
    output logic [31:0] m0_rdata,

    input  logic        m1_valid,
    input  logic        m1_we,
    input  logic [1:0]  m1_addr,
    input  logic [31:0] m1_wdata,
    output logic        m1_ready,
    output logic [31:0] m1_rdata,

    input  logic        m2_valid,
    input  logic        m2_we,
    input  logic [1:0]  m2_addr,
    input  logic [31:0] m2_wdata,
    output logic        m2_ready,
    output logic [31:0] m2_rdata,

    output logic [2:0]  grant,
    output logic [1:0]  rr_ptr_dbg
);
    logic [31:0] regs [0:3];
    logic [1:0] rr_ptr;

    always_comb begin
        logic [2:0] valid;
        valid = {m2_valid, m1_valid, m0_valid};

        grant = 3'b000;
        for (int off = 0; off < 3; off++) begin
            int idx;
            idx = int'(rr_ptr) + off;
            if (idx >= 3) idx = idx - 3;

            if (grant == 3'b000 && valid[idx]) begin
                grant[idx] = 1'b1;
            end
        end
    end

    assign rr_ptr_dbg = rr_ptr;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            rr_ptr <= 2'd0;
            m0_ready <= 1'b0;
            m1_ready <= 1'b0;
            m2_ready <= 1'b0;
            m0_rdata <= '0;
            m1_rdata <= '0;
            m2_rdata <= '0;
            regs[0] <= 32'h0000_1000;
            regs[1] <= 32'h0000_1001;
            regs[2] <= 32'h0000_1002;
            regs[3] <= 32'h0000_1003;
        end else begin
            m0_ready <= 1'b0;
            m1_ready <= 1'b0;
            m2_ready <= 1'b0;

            if (grant[0]) begin
                m0_ready <= 1'b1;
                if (m0_we) regs[m0_addr] <= m0_wdata;
                else       m0_rdata <= regs[m0_addr];
                rr_ptr <= 2'd1;
            end

            if (grant[1]) begin
                m1_ready <= 1'b1;
                if (m1_we) regs[m1_addr] <= m1_wdata;
                else       m1_rdata <= regs[m1_addr];
                rr_ptr <= 2'd2;
            end

            if (grant[2]) begin
                m2_ready <= 1'b1;
                if (m2_we) regs[m2_addr] <= m2_wdata;
                else       m2_rdata <= regs[m2_addr];
                rr_ptr <= 2'd0;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (rst_n) begin
            assert ($onehot0(grant))
                else $fatal(1, "Bus interconnect violation: grant must be one-hot or zero");

            assert (!(grant[0] && !m0_valid))
                else $fatal(1, "Bus interconnect violation: m0 granted without valid");
            assert (!(grant[1] && !m1_valid))
                else $fatal(1, "Bus interconnect violation: m1 granted without valid");
            assert (!(grant[2] && !m2_valid))
                else $fatal(1, "Bus interconnect violation: m2 granted without valid");
        end
    end

endmodule
