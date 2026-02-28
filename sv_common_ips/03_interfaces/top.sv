// top.sv - Lesson 03
//
// Wires producer <-> consumer through an interface instance.
// C++ only drives clk/rst_n/en.

`include "bus_if.sv"

module top (
    input  logic clk,
    input  logic rst_n,
    input  logic en,

    output logic [7:0]  last_seen,
    output logic [15:0] count_seen
);
    // Instantiate interface (bundles signals + modports)
    rv_if #(8) bus(clk);

    producer u_prod (
        .rst_n(rst_n),
        .en(en),
        .bus(bus)
    );

    consumer u_cons (
        .rst_n(rst_n),
        .bus(bus),
        .last_seen(last_seen),
        .count_seen(count_seen)
    );

endmodule