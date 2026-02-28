// top.sv - Lesson 08
//
// Focus:
//  - Same FIFO-style DUT boundary as Lesson 07
//  - Assertions at the DUT boundary to verify stimulus constraints
//
// This lets C++ do the constrained-like generation while SV still enforces
// protocol/data rules at the interface.

module top (
    input  logic clk,
    input  logic rst_n,

    input  logic       in_valid,
    input  logic [7:0] in_data,
    output logic       in_ready,

    input  logic       out_ready,
    output logic       out_valid,
    output logic [7:0] out_data,

    output logic [3:0] count
);
    localparam int DEPTH = 8;
    localparam int AW = $clog2(DEPTH);

    logic [7:0] mem [0:DEPTH-1];
    logic [AW-1:0] wptr;
    logic [AW-1:0] rptr;
    logic [AW:0] used;

    logic push;
    logic pop;

    assign in_ready = (int'(used) < DEPTH);
    assign out_valid = (used != 0);
    assign out_data = mem[rptr];
    assign count = used[3:0];

    assign push = in_valid && in_ready;
    assign pop = out_ready && out_valid;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            wptr <= '0;
            rptr <= '0;
            used <= '0;
        end else begin
            if (push) begin
                mem[wptr] <= in_data;
                wptr <= wptr + 1'b1;
            end

            if (pop) begin
                rptr <= rptr + 1'b1;
            end

            unique case ({push, pop})
                2'b10: used <= used + 1'b1;
                2'b01: used <= used - 1'b1;
                default: used <= used;
            endcase
        end
    end

    // Boundary checks:
    //  - no push when full
    //  - no pop when empty
    //  - pushed data obeys the C++ generator's constraints
    always_ff @(posedge clk) begin
        if (rst_n) begin
            assert (!(in_valid && !in_ready))
                else $fatal(1, "Constraint violated: push attempted while full");

            assert (!(out_ready && !out_valid))
                else $fatal(1, "Constraint violated: pop attempted while empty");

            if (push) begin
                assert (in_data[0] == 1'b1)
                    else $fatal(1, "Constraint violated: pushed data must be odd");

                assert (in_data != 8'hFF)
                    else $fatal(1, "Constraint violated: pushed data must not be 0xFF");

                assert (in_data[7:4] != 4'hF)
                    else $fatal(1, "Constraint violated: pushed data upper nibble must not be 0xF");
            end
        end
    end

endmodule
