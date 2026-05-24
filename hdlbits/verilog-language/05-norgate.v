/* Create a module that implements a NOR gate. */

module (input a, input b, output c);
    assign c = !(a | b);
endmodule