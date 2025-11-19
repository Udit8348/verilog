module logical (
    input[1:0] a,
    input[1:0] b,
    output logical_o // note this will always need just one bit
);
    assign logical_o = a && b;
endmodule