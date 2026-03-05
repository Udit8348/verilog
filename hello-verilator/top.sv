module top (
    input  logic [1:0] a,
    input  logic [1:0] b,
    output logic [1:0] bt_out,
    output logic       lg_out
);

    bitwise u_bitwise (
        .a(a),
        .b(b),
        .bitwise_o(bt_out)
    );

    logical u_logical (
        .a(a[0]),
        .b(b[0]),
        .logical_o(lg_out)
    );

endmodule