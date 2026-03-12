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

module ripple_carry4_gen_sv (
    input  logic [3:0] A,
    input  logic [3:0] B,
    input  logic       Cin,
    output logic [3:0] Sum,
    output logic       CarryOut
);
    logic [4:0] C; // 5 bit signal
    assign C[0]     = Cin;
    assign CarryOut = C[4];

    genvar i;
    // generate (optional in sv)
    for (i = 0; i < 4; i++) begin : gen_fa // gen_fa is just the name of this blocks
        full_adder fa (
            .A   (A[i]),
            .B   (B[i]),
            .Cin (C[i]),
            .Sum (Sum[i]),
            .Cout(C[i+1])
        );
    end
    // endgenerate
    
endmodule