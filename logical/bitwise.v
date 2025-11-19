module bitwise (
    input[1:0] a,
    input[1:0] b,
    output[1:0] bitwise_o
);
    assign bitwise_o = a & b;
endmodule