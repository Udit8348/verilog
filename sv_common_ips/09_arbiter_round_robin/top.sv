// top.sv - Lesson 09
//
// Focus:
//  - 4-way round-robin arbiter
//  - one-hot grant/protocol assertions
//  - structure that is easy to mirror in a C++ reference model

module top (
    input  logic clk,
    input  logic rst_n,

    input  logic [3:0] req,
    output logic [3:0] gnt,

    output logic [1:0] rr_ptr_dbg
);
    logic [1:0] rr_ptr;
    logic [3:0] gnt_next;

    // Pick one request using round-robin priority starting at rr_ptr.
    always_comb begin
        logic found;
        gnt_next = 4'b0000;
        found = 1'b0;

        for (int off = 0; off < 4; off++) begin
            int idx;
            idx = int'(rr_ptr) + off;
            if (idx >= 4) idx = idx - 4;

            if (!found && req[idx]) begin
                gnt_next[idx] = 1'b1;
                found = 1'b1;
            end
        end
    end

    assign gnt = gnt_next;
    assign rr_ptr_dbg = rr_ptr;

    // Move pointer to the slot after the granted requester.
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            rr_ptr <= 2'd0;
        end else if (|gnt_next) begin
            unique case (1'b1)
                gnt_next[0]: rr_ptr <= 2'd1;
                gnt_next[1]: rr_ptr <= 2'd2;
                gnt_next[2]: rr_ptr <= 2'd3;
                gnt_next[3]: rr_ptr <= 2'd0;
                default: rr_ptr <= rr_ptr;
            endcase
        end
    end

    // Protocol/boundary checks.
    always_ff @(posedge clk) begin
        if (rst_n) begin
            assert ($onehot0(gnt))
                else $fatal(1, "Arbiter violation: gnt must be one-hot or zero");

            assert ((gnt & ~req) == 4'b0000)
                else $fatal(1, "Arbiter violation: grant without matching request");

            if (req == 4'b0000) begin
                assert (gnt == 4'b0000)
                    else $fatal(1, "Arbiter violation: nonzero grant when no requests");
            end
        end
    end

endmodule
