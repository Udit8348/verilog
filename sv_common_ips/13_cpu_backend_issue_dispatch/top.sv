// top.sv - Lesson 13
//
// Use-case:
//  - CPU backend issue/dispatch where multiple instruction slots compete
//    for limited execution resources (ALU and MUL pipelines).

module top (
    input  logic clk,
    input  logic rst_n,

    input  logic       s0_valid,
    input  logic       s0_is_mul,
    input  logic [3:0] s0_tag,

    input  logic       s1_valid,
    input  logic       s1_is_mul,
    input  logic [3:0] s1_tag,

    input  logic       s2_valid,
    input  logic       s2_is_mul,
    input  logic [3:0] s2_tag,

    input  logic       alu_ready,
    input  logic       mul_ready,

    output logic       alu_issue_valid,
    output logic [3:0] alu_issue_tag,
    output logic [1:0] alu_issue_slot,

    output logic       mul_issue_valid,
    output logic [3:0] mul_issue_tag,
    output logic [1:0] mul_issue_slot,

    output logic [2:0] alu_grant,
    output logic [2:0] mul_grant,

    output logic [1:0] alu_rr_ptr_dbg,
    output logic [1:0] mul_rr_ptr_dbg
);
    logic [1:0] alu_rr_ptr;
    logic [1:0] mul_rr_ptr;

    logic [2:0] valid_alu;
    logic [2:0] valid_mul;

    function automatic logic [2:0] rr_pick3(
        input logic [2:0] valid,
        input logic [1:0] ptr
    );
        logic [2:0] g;
        g = 3'b000;

        unique case (ptr)
            2'd0: begin
                if (valid[0])      g = 3'b001;
                else if (valid[1]) g = 3'b010;
                else if (valid[2]) g = 3'b100;
            end
            2'd1: begin
                if (valid[1])      g = 3'b010;
                else if (valid[2]) g = 3'b100;
                else if (valid[0]) g = 3'b001;
            end
            default: begin
                if (valid[2])      g = 3'b100;
                else if (valid[0]) g = 3'b001;
                else if (valid[1]) g = 3'b010;
            end
        endcase

        return g;
    endfunction

    assign valid_alu[0] = s0_valid && !s0_is_mul;
    assign valid_alu[1] = s1_valid && !s1_is_mul;
    assign valid_alu[2] = s2_valid && !s2_is_mul;

    assign valid_mul[0] = s0_valid && s0_is_mul;
    assign valid_mul[1] = s1_valid && s1_is_mul;
    assign valid_mul[2] = s2_valid && s2_is_mul;

    always_comb begin
        if (alu_ready) alu_grant = rr_pick3(valid_alu, alu_rr_ptr);
        else           alu_grant = 3'b000;
    end

    always_comb begin
        if (mul_ready) mul_grant = rr_pick3(valid_mul, mul_rr_ptr);
        else           mul_grant = 3'b000;
    end

    assign alu_issue_valid = |alu_grant;
    assign mul_issue_valid = |mul_grant;

    always_comb begin
        alu_issue_tag = 4'h0;
        alu_issue_slot = 2'd0;

        if (alu_grant[0]) begin
            alu_issue_tag = s0_tag;
            alu_issue_slot = 2'd0;
        end else if (alu_grant[1]) begin
            alu_issue_tag = s1_tag;
            alu_issue_slot = 2'd1;
        end else if (alu_grant[2]) begin
            alu_issue_tag = s2_tag;
            alu_issue_slot = 2'd2;
        end
    end

    always_comb begin
        mul_issue_tag = 4'h0;
        mul_issue_slot = 2'd0;

        if (mul_grant[0]) begin
            mul_issue_tag = s0_tag;
            mul_issue_slot = 2'd0;
        end else if (mul_grant[1]) begin
            mul_issue_tag = s1_tag;
            mul_issue_slot = 2'd1;
        end else if (mul_grant[2]) begin
            mul_issue_tag = s2_tag;
            mul_issue_slot = 2'd2;
        end
    end

    assign alu_rr_ptr_dbg = alu_rr_ptr;
    assign mul_rr_ptr_dbg = mul_rr_ptr;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            alu_rr_ptr <= 2'd0;
            mul_rr_ptr <= 2'd0;
        end else begin
            if (alu_grant[0]) alu_rr_ptr <= 2'd1;
            if (alu_grant[1]) alu_rr_ptr <= 2'd2;
            if (alu_grant[2]) alu_rr_ptr <= 2'd0;

            if (mul_grant[0]) mul_rr_ptr <= 2'd1;
            if (mul_grant[1]) mul_rr_ptr <= 2'd2;
            if (mul_grant[2]) mul_rr_ptr <= 2'd0;
        end
    end

    always_ff @(posedge clk) begin
        if (rst_n) begin
            assert ($onehot0(alu_grant))
                else $fatal(1, "CPU issue violation: ALU grant must be one-hot or zero");

            assert ($onehot0(mul_grant))
                else $fatal(1, "CPU issue violation: MUL grant must be one-hot or zero");

            assert ((alu_grant & mul_grant) == 3'b000)
                else $fatal(1, "CPU issue violation: same slot granted to ALU and MUL");
        end
    end

endmodule
