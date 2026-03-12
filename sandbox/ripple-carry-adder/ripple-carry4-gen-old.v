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

// using traditional verilog syntax we can use a genvar to instantiate clones of some hw module
module ripple_carry4_gen_old (
    input  wire [3:0] A,
    input  wire [3:0] B,
    input  wire       Cin,
    output wire [3:0] Sum,
    output wire       CarryOut
);
    wire [4:0] C;
    assign C[0]    = Cin;
    assign CarryOut = C[4];

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : GEN_FA
            full_adder fa (
                .A   (A[i]),
                .B   (B[i]),
                .Cin (C[i]),
                .Sum (Sum[i]),
                .Cout(C[i+1])
            );
        end
    endgenerate
endmodule