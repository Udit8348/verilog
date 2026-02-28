// top.sv - Lesson 10
//
// Use-case:
//  - Shared SRAM/register-file port accessed by two clients.
//  - Single physical memory port, so requests are arbitrated.

module top (
    input  logic clk,
    input  logic rst_n,

    input  logic        c0_req,
    input  logic        c0_we,
    input  logic [3:0]  c0_addr,
    input  logic [15:0] c0_wdata,
    output logic        c0_ready,
    output logic [15:0] c0_rdata,

    input  logic        c1_req,
    input  logic        c1_we,
    input  logic [3:0]  c1_addr,
    input  logic [15:0] c1_wdata,
    output logic        c1_ready,
    output logic [15:0] c1_rdata,

    output logic [1:0]  grant,
    output logic        rr_turn_dbg
);
    logic [15:0] mem [0:15];
    logic rr_turn;

    always_comb begin
        grant = 2'b00;
        if (c0_req && c1_req) begin
            grant = rr_turn ? 2'b10 : 2'b01;
        end else if (c0_req) begin
            grant = 2'b01;
        end else if (c1_req) begin
            grant = 2'b10;
        end
    end

    assign rr_turn_dbg = rr_turn;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            rr_turn <= 1'b0;
            c0_ready <= 1'b0;
            c1_ready <= 1'b0;
            c0_rdata <= '0;
            c1_rdata <= '0;
            for (int i = 0; i < 16; i++) begin
                mem[i] <= 16'h1000 + i[15:0];
            end
        end else begin
            c0_ready <= 1'b0;
            c1_ready <= 1'b0;

            if (grant[0]) begin
                c0_ready <= 1'b1;
                if (c0_we) mem[c0_addr] <= c0_wdata;
                else       c0_rdata <= mem[c0_addr];
                rr_turn <= 1'b1;
            end

            if (grant[1]) begin
                c1_ready <= 1'b1;
                if (c1_we) mem[c1_addr] <= c1_wdata;
                else       c1_rdata <= mem[c1_addr];
                rr_turn <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (rst_n) begin
            assert ($onehot0(grant))
                else $fatal(1, "Shared SRAM arbiter violation: grant must be one-hot or zero");

            assert (!(c0_ready && c1_ready))
                else $fatal(1, "Shared SRAM violation: both clients ready in one cycle");
        end
    end

endmodule
