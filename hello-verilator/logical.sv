// produce a 1-bit logical AND (boolean)
module logical (
    input logic a,
    input logic b,
    output logic logical_o // note this will always need just one bit
);
    assign logical_o = a && b;
endmodule