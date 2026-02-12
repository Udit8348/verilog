// produce a 1-bit logical AND (boolean)
module logical (
    logic[1:0] a,
    logic[1:0] b,
    logic logical_o // note this will always need just one bit
);
    assign logical_o = a && b;
endmodule