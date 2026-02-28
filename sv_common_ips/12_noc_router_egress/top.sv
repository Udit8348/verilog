// top.sv - Lesson 12
//
// Use-case:
//  - NoC/router output arbitration: multiple virtual channels to one egress.
//  - Egress only sends when downstream credit is available.

module top (
    input  logic clk,
    input  logic rst_n,

    input  logic       vc0_valid,
    input  logic [7:0] vc0_flit,
    output logic       vc0_ready,

    input  logic       vc1_valid,
    input  logic [7:0] vc1_flit,
    output logic       vc1_ready,

    input  logic       vc2_valid,
    input  logic [7:0] vc2_flit,
    output logic       vc2_ready,

    input  logic       vc3_valid,
    input  logic [7:0] vc3_flit,
    output logic       vc3_ready,

    input  logic       egr_credit,
    output logic       egr_valid,
    output logic [7:0] egr_flit,
    output logic [1:0] egr_vc,

    output logic [3:0] grant,
    output logic [1:0] rr_ptr_dbg
);
    logic [1:0] rr_ptr;

    always_comb begin
        logic [3:0] valid;
        valid = {vc3_valid, vc2_valid, vc1_valid, vc0_valid};

        grant = 4'b0000;
        if (egr_credit) begin
            for (int off = 0; off < 4; off++) begin
                int idx;
                idx = int'(rr_ptr) + off;
                if (idx >= 4) idx = idx - 4;

                if (grant == 4'b0000 && valid[idx]) begin
                    grant[idx] = 1'b1;
                end
            end
        end

        vc0_ready = grant[0];
        vc1_ready = grant[1];
        vc2_ready = grant[2];
        vc3_ready = grant[3];

        egr_valid = |grant;
        egr_flit = 8'h00;
        egr_vc = 2'd0;

        unique case (1'b1)
            grant[0]: begin egr_flit = vc0_flit; egr_vc = 2'd0; end
            grant[1]: begin egr_flit = vc1_flit; egr_vc = 2'd1; end
            grant[2]: begin egr_flit = vc2_flit; egr_vc = 2'd2; end
            grant[3]: begin egr_flit = vc3_flit; egr_vc = 2'd3; end
            default: begin egr_flit = 8'h00;    egr_vc = 2'd0; end
        endcase
    end

    assign rr_ptr_dbg = rr_ptr;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            rr_ptr <= 2'd0;
        end else if (|grant) begin
            rr_ptr <= egr_vc + 2'd1;
        end
    end

    always_ff @(posedge clk) begin
        if (rst_n) begin
            assert ($onehot0(grant))
                else $fatal(1, "NoC egress violation: grant must be one-hot or zero");

            assert (egr_valid == (|grant))
                else $fatal(1, "NoC egress violation: egr_valid mismatch with grant");

            if (!egr_credit) begin
                assert (grant == 4'b0000)
                    else $fatal(1, "NoC egress violation: grant without credit");
            end
        end
    end

endmodule
