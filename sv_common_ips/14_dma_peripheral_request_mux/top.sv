// top.sv - Lesson 14
//
// Use-case:
//  - DMA engines and CPU/peripheral accesses sharing one peripheral bus.
//  - CPU control traffic has priority; DMA channels share leftover cycles.

module top (
    input  logic clk,
    input  logic rst_n,

    input  logic        cpu_req,
    input  logic        cpu_we,
    input  logic [3:0]  cpu_addr,
    input  logic [15:0] cpu_wdata,
    output logic        cpu_ready,
    output logic [15:0] cpu_rdata,

    input  logic        dma0_req,
    input  logic        dma0_we,
    input  logic [3:0]  dma0_addr,
    input  logic [15:0] dma0_wdata,
    output logic        dma0_ready,
    output logic [15:0] dma0_rdata,

    input  logic        dma1_req,
    input  logic        dma1_we,
    input  logic [3:0]  dma1_addr,
    input  logic [15:0] dma1_wdata,
    output logic        dma1_ready,
    output logic [15:0] dma1_rdata,

    output logic [2:0]  grant,
    output logic        dma_rr_ptr_dbg
);
    logic [15:0] regs [0:15];
    logic dma_rr_ptr;

    always_comb begin
        grant = 3'b000;

        if (cpu_req) begin
            grant = 3'b001;
        end else if (dma0_req && dma1_req) begin
            grant = dma_rr_ptr ? 3'b100 : 3'b010;
        end else if (dma0_req) begin
            grant = 3'b010;
        end else if (dma1_req) begin
            grant = 3'b100;
        end
    end

    assign dma_rr_ptr_dbg = dma_rr_ptr;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            dma_rr_ptr <= 1'b0;
            cpu_ready <= 1'b0;
            dma0_ready <= 1'b0;
            dma1_ready <= 1'b0;
            cpu_rdata <= '0;
            dma0_rdata <= '0;
            dma1_rdata <= '0;
            for (int i = 0; i < 16; i++) begin
                regs[i] <= 16'h2000 + i[15:0];
            end
        end else begin
            cpu_ready <= 1'b0;
            dma0_ready <= 1'b0;
            dma1_ready <= 1'b0;

            if (grant[0]) begin
                cpu_ready <= 1'b1;
                if (cpu_we) regs[cpu_addr] <= cpu_wdata;
                else        cpu_rdata <= regs[cpu_addr];
            end

            if (grant[1]) begin
                dma0_ready <= 1'b1;
                if (dma0_we) regs[dma0_addr] <= dma0_wdata;
                else         dma0_rdata <= regs[dma0_addr];
                dma_rr_ptr <= 1'b1;
            end

            if (grant[2]) begin
                dma1_ready <= 1'b1;
                if (dma1_we) regs[dma1_addr] <= dma1_wdata;
                else         dma1_rdata <= regs[dma1_addr];
                dma_rr_ptr <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (rst_n) begin
            assert ($onehot0(grant))
                else $fatal(1, "DMA mux violation: grant must be one-hot or zero");

            if (cpu_req) begin
                assert (grant == 3'b001)
                    else $fatal(1, "DMA mux violation: CPU request must take priority");
            end
        end
    end

endmodule
