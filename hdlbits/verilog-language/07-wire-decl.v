/*
Create a module which AND's the first two pairs. Then OR the AND gates for OUT and generate an OUT_N(ot)
Hint: Practice creating intermediate wires. 
*/

module (  input a, input b, input c, input d, output out, output out_n);
    // declare intermediate wires, before usage
    wire and_ab;
    wire and_cd;
    wire sop;


    assign and_ab = a && b; 
    assign and_cd = c && d;

    assign sop = and_ab || and_cd;

    assign out = sop;
    assign out_n = !sop;
endmodule