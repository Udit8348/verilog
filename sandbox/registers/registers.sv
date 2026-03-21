`timescale 1ns/1ps

module dff #(
    parameter int W = 8
) (
    input  logic         clk,
    input  logic         rst_n,   // active-low reset
    input  logic         en,      // clock enable
    input  logic [W-1:0] d,
    output logic [W-1:0] q
);

    // q is inferred as a flip-flop with a registered output
    // between clock edges, q holds its value even if d wiggles
    // q has asynchronous active-low reset since it is provided in the sensitivity list
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= '0;
        else if (en)
            q <= d;
    end

endmodule