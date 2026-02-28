// top.sv - Lesson 06 (DPI)
//
// We import a C function:
//   int dpi_add(int a, int b);
//
// Then we use it in sequential logic.
//
// Verilator note:
//  - DPI-C is supported, but keep types simple (int, longint, byte, etc).

module top (
    input  logic clk,
    input  logic rst_n,
    input  logic [7:0] a,
    input  logic [7:0] b,
    output logic [15:0] sum
);

    // DPI import declaration
    import "DPI-C" function int dpi_add(input int a, input int b);

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            sum <= '0;
        end else begin
            // Cast packed vectors to int for DPI call
            int ai = a;
            int bi = b;
            int si = dpi_add(ai, bi);

            // Store result
            sum <= si[15:0];
        end
    end

endmodule