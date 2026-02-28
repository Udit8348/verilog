// top.sv - Lesson 15
//
// Use-case:
//  - Cache/memory-system queues contending for a memory port.
//  - Refill queue and miss-status queue both feed one downstream port.

module top (
    input  logic clk,
    input  logic rst_n,

    input  logic       miss_push,
    input  logic [7:0] miss_addr_in,
    output logic       miss_full,

    input  logic        refill_push,
    input  logic [7:0]  refill_addr_in,
    input  logic [31:0] refill_data_in,
    output logic        refill_full,

    input  logic       mem_ready,
    output logic       issue_valid,
    output logic       issue_is_refill,
    output logic [7:0] issue_addr,
    output logic [31:0] issue_wdata,

    output logic [2:0] miss_count,
    output logic [2:0] refill_count
);
    localparam int DEPTH = 4;

    logic [7:0] miss_addr_q [0:DEPTH-1];
    logic [1:0] miss_wptr;
    logic [1:0] miss_rptr;
    logic [2:0] miss_used;

    logic [7:0]  refill_addr_q [0:DEPTH-1];
    logic [31:0] refill_data_q [0:DEPTH-1];
    logic [1:0] refill_wptr;
    logic [1:0] refill_rptr;
    logic [2:0] refill_used;

    logic miss_pop;
    logic refill_pop;
    logic miss_do_push;
    logic refill_do_push;

    assign miss_full = (miss_used == 3'd4);
    assign refill_full = (refill_used == 3'd4);
    assign miss_count = miss_used;
    assign refill_count = refill_used;
    assign miss_do_push = miss_push && !miss_full;
    assign refill_do_push = refill_push && !refill_full;

    always_comb begin
        issue_valid = 1'b0;
        issue_is_refill = 1'b0;
        issue_addr = 8'h00;
        issue_wdata = 32'h0000_0000;

        miss_pop = 1'b0;
        refill_pop = 1'b0;

        if (mem_ready) begin
            if (refill_used != 0) begin
                issue_valid = 1'b1;
                issue_is_refill = 1'b1;
                issue_addr = refill_addr_q[refill_rptr];
                issue_wdata = refill_data_q[refill_rptr];
                refill_pop = 1'b1;
            end else if (miss_used != 0) begin
                issue_valid = 1'b1;
                issue_is_refill = 1'b0;
                issue_addr = miss_addr_q[miss_rptr];
                issue_wdata = 32'h0000_0000;
                miss_pop = 1'b1;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            miss_wptr <= 2'd0;
            miss_rptr <= 2'd0;
            miss_used <= 3'd0;

            refill_wptr <= 2'd0;
            refill_rptr <= 2'd0;
            refill_used <= 3'd0;
        end else begin
            // Miss queue push
            if (miss_do_push) begin
                miss_addr_q[miss_wptr] <= miss_addr_in;
                miss_wptr <= miss_wptr + 2'd1;
            end

            // Refill queue push
            if (refill_do_push) begin
                refill_addr_q[refill_wptr] <= refill_addr_in;
                refill_data_q[refill_wptr] <= refill_data_in;
                refill_wptr <= refill_wptr + 2'd1;
            end

            // Miss queue pop
            if (miss_pop) begin
                miss_rptr <= miss_rptr + 2'd1;
            end

            // Refill queue pop
            if (refill_pop) begin
                refill_rptr <= refill_rptr + 2'd1;
            end

            unique case ({miss_do_push, miss_pop})
                2'b10: miss_used <= miss_used + 3'd1;
                2'b01: miss_used <= miss_used - 3'd1;
                default: miss_used <= miss_used;
            endcase

            unique case ({refill_do_push, refill_pop})
                2'b10: refill_used <= refill_used + 3'd1;
                2'b01: refill_used <= refill_used - 3'd1;
                default: refill_used <= refill_used;
            endcase
        end
    end

    always_ff @(posedge clk) begin
        if (rst_n) begin
            if (issue_valid && issue_is_refill) begin
                assert (refill_used != 0)
                    else $fatal(1, "Cache queue violation: issued refill with empty refill queue");
            end

            if (issue_valid && !issue_is_refill) begin
                assert ((refill_used == 0) && (miss_used != 0))
                    else $fatal(1, "Cache queue violation: miss issued when refill should have priority");
            end

            assert (miss_used <= 3'd4)
                else $fatal(1, "Cache queue violation: miss queue overflow");
            assert (refill_used <= 3'd4)
                else $fatal(1, "Cache queue violation: refill queue overflow");
        end
    end

endmodule
