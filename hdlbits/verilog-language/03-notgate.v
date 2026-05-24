/* Create a module that implements a NOT gate. */

module (  input in, output out  );
    assign out = ~in; // bitwise not, `!` is a logical not
endmodule