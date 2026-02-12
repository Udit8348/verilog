// produce a bitwise AND over some vector
module bitwise (
    logic[1:0] a,
    logic[1:0] b,
    logic[1:0] bitwise_o
);
    assign bitwise_o = a & b;
endmodule