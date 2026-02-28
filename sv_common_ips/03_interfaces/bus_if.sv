// bus_if.sv
//
// A simple ready/valid interface.
// Producer drives: valid, data
// Consumer drives: ready
//
// modport enforces directionality at compile time.

interface rv_if #(parameter int W = 8) (input logic clk);
    logic         valid;
    logic         ready;
    logic [W-1:0] data;

    // Producer sees ready as input, drives valid/data
    modport producer (
        input  clk,
        input  ready,
        output valid,
        output data
    );

    // Consumer sees valid/data as input, drives ready
    modport consumer (
        input  clk,
        input  valid,
        input  data,
        output ready
    );
endinterface