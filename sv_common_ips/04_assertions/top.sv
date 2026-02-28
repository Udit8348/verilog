// top.sv - Lesson 04
//
// Focus:
//  - Immediate assertions (assert(...) else $fatal)
//  - Concurrent assertions / SVA properties (simple ones)
//  - Practical protocol checks
//
// Verilator note:
//  - Many SVA forms are supported, but keep it simple for portability.

module top (
    input  logic clk,
    input  logic rst_n,
    input  logic valid,
    input  logic ready,
    input  logic [7:0] data,

    output logic [7:0] last_data
);

    // Track last_data on successful transfers
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            last_data <= 8'd0;
        end else begin
            if (valid && ready) last_data <= data;
        end
    end

    // -------------------------
    // Immediate assertion example
    // -------------------------
    always_ff @(posedge clk) begin
        if (rst_n) begin
            // Example rule: data must not be 0xAA when valid is high
            // (arbitrary “bad value” to show failing behavior if you want)
            assert(!(valid && (data == 8'hAA)))
                else $fatal(1, "Assertion failed: data==0xAA while valid=1");
        end
    end

    // -------------------------
    // Concurrent assertion example (SVA)
    // -------------------------
    // Rule: once valid is asserted, if ready is low, data must remain stable
    // until transfer occurs. This is a common ready/valid requirement.
    property hold_data_when_stalled;
        @(posedge clk) disable iff (!rst_n)
            (valid && !ready) |=> $stable(data);
    endproperty

    assert property (hold_data_when_stalled)
        else $fatal(1, "SVA failed: data changed while stalled (valid=1, ready=0)");

endmodule