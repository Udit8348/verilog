`timescale 1ns/1ps

module half_adder(
    input  wire A, B,
    output wire Sum, CarryOut
);
    assign Sum      = A ^ B;
    assign CarryOut = A & B;
endmodule

module full_adder(
    input  wire A, B, Cin,
    output wire Sum, Cout
);
    wire s1, c1, c2;

    half_adder ha0 (.A(A),  .B(B),   .Sum(s1),  .CarryOut(c1));
    half_adder ha1 (.A(s1), .B(Cin), .Sum(Sum), .CarryOut(c2));

    assign Cout = c1 | c2;
endmodule

// A[i] + B[i] = S[i] occur in parallel
// CarryOut serializes across the "ripples" of full adders
module ripple_carry4 (
    input wire [3:0] A, B,
    output wire [3:0] Sum,
    output wire CarryOut
);

    wire C1, C2, C3; // intermediate wires
    
    full_adder fa1 (.A(A[0]), .B(B[0]), .Cin(1'b0), .Sum(Sum[0]), .Cout(C1)); // hardcode carry in of 0
    full_adder fa2 (.A(A[1]), .B(B[1]), .Cin(C1), .Sum(Sum[1]), .Cout(C2));
    full_adder fa3 (.A(A[2]), .B(B[2]), .Cin(C2), .Sum(Sum[2]), .Cout(C3));
    full_adder fa4 (.A(A[3]), .B(B[3]), .Cin(C3), .Sum(Sum[3]), .Cout(CarryOut));

endmodule