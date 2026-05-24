/* Create a module that implements an XNOR gate. */

module (  input a, input b, output out);
    assign out = ~(a^b);
endmodule