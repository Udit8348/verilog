# 4 Bit Full Adder (Ripple Carry to HLS)

`ripple-carry4.v` primitive 4 bit ripple carry adder in verilog, simulated in `sim.cpp`
```
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
```

Use genvar in verilog to cleanup impl (`ripple-carry4-gen-old.v`)
```
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
```

See this in sv now (`ripple-carry4-gen.sv`)
```
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
```

Finally, HLS lets us express functionality and allow for synthesis to infer how to complete this hw (`hls-adder4.sv`)
```
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
```

