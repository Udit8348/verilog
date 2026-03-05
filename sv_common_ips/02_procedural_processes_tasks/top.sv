// top.sv - Lesson 02
//
// Focus:
//  - always_ff vs always_comb
//  - if/else, case, for loops
//  - blocking vs nonblocking assignments
//  - tasks vs functions (and typical usage patterns)
//
// Verilator note:
//  - These are core SV RTL constructs and are supported.

module top (
    input  logic clk,
    input  logic rst_n,

    input  logic        en,
    input  logic [7:0]  x,
    input  logic [7:0]  y,

    output logic [7:0]  sum_comb,
    output logic [7:0]  sum_seq,
    output logic [7:0]  popcnt_x,
    output logic        gt_flag
);

    // -------------------------
    // Function: pure combinational calculation
    // Must not contain timing (#) or wait or nonblocking.
    // Functions are automatic by default in systemverilog.
    // 
    // -------------------------
    function automatic logic [7:0] popcount8(input logic [7:0] v);
        logic [7:0] cnt;
        cnt = 8'd0;
        for (int i = 0; i < 8; i++) begin
            cnt = cnt + v[i];
        end
        return cnt;
    endfunction

    /**
        The for loop gets resolved into a compile-time unroll.
        This is known as a ripple-style adder chain. That is 7 / 8 8-bit adders deep.

            cnt = cnt + v[0]
            cnt = cnt + v[1]
            cnt = cnt + v[2]
            cnt = cnt + v[3]
            cnt = cnt + v[4]
            cnt = cnt + v[5]
            cnt = cnt + v[6]
            cnt = cnt + v[7]

        We can divide and conquer with a pairwise summation. Known as an adder tree (parallel reduction).
    */

    // -------------------------
    // Task: can model multi-step procedures (still keep it combinational here)
    // Tasks can have output/inout arguments.
    // -------------------------
    task automatic add8(
        input  logic [7:0] a,
        input  logic [7:0] b,
        output logic [7:0] r
    );
        // Blocking assignment is fine in tasks used inside always_comb
        r = a + b;
    endtask

    // -------------------------
    // always_comb: “combinational logic”
    // -------------------------
    always_comb begin
        // Default assignments are important to avoid inferred latches.
        sum_comb = 8'd0;
        gt_flag  = 1'b0;

        if (en) begin
            // Use a task to compute sum
            add8(x, y, sum_comb);

            // Compare
            gt_flag = (x > y);
        end
    end

    // Use function
    always_comb begin
        popcnt_x = popcount8(x);
    end

    // -------------------------
    // always_ff: “sequential logic”
    // - use nonblocking <= to model flops
    // -------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            sum_seq <= 8'd0;
        end else begin
            // Nonblocking assignment: updates at end of time step
            if (en) sum_seq <= x + y;
            else    sum_seq <= sum_seq; // explicit hold (optional; flop holds by nature)
        end
    end

endmodule