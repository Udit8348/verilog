// including the timescale here allows you to preview the vcd file in 3rd party tools too
`timescale 1ns/1ps

module half_adder(
    input wire A, B,
    output wire Sum, CarryOut
);
    assign Sum = A ^ B;
    assign CarryOut = A & B;
endmodule