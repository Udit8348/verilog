/* Create a module with one input and one output that behaves like a wire. */

module wire(  input in, output out  );

    assign out = in;

endmodule