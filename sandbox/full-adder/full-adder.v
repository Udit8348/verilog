module half_adder(
    input  wire A, B,
    output wire Sum, CarryOut
);
    assign Sum      = A ^ B;
    assign CarryOut = A & B;
endmodule

// we can structurally build a full adder by wiring two half adders
// (optional) you can use boolean logic simplification to avoid instantiating two half-adders
module full_adder(
    input  wire A, B, Cin,
    output wire Sum, Cout
);
    wire s1, c1, c2;

    half_adder ha0 (.A(A),  .B(B),   .Sum(s1),  .CarryOut(c1)); // first half adder gets the operands
    half_adder ha1 (.A(s1), .B(Cin), .Sum(Sum), .CarryOut(c2)); // second half adder gets the intermediate result and the carryin

    assign Cout = c1 | c2; // if either half adder has a carry out then we have to express that
endmodule