`timescale 1ns/1ps

// final abstraction level of a 4 bit adder
// depending on the synthesis tool this may get inferred as a ripple carry adder or something else
module ripple_carry4_plus (
    input  logic [3:0] A,
    input  logic [3:0] B,
    input  logic       Cin,
    output logic [3:0] Sum,
    output logic       Cout
);
    always_comb begin
        {Cout, Sum} = A + B + Cin;
    end
endmodule