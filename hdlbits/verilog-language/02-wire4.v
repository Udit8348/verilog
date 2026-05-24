/* 
Create a module with 3 inputs and 4 outputs that behaves like wires that makes these connections:
    a -> w
    b -> x
    b -> y
    c -> z
*/

module wire4(  input a, input b, input c, output w, output x, output y, output z  );
    assign w = a;
    assign x = b;
    assign y = b;
    assign z = c;
endmodule