// produce a bitwise AND over some vector
module bitwise (
    input logic[1:0] a,
    input logic[1:0] b,
    output logic[1:0] bitwise_o
);
    assign bitwise_o = a & b;
endmodule