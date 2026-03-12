`timescale 1ns/1ps

// 1-bit half adder in gate level simulation form with explicit delays
module half_adder (
    output wire Sum, CarryOut,
    input  wire A, B
);

    xor #1 U1 (Sum, A, B);
    and #1 U2 (CarryOut, A, B);

endmodule