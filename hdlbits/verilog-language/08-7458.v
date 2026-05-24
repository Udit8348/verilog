/* Create a module with the same functionality as the 7458 chip */

module intermediate_7458 (  input p1a, input p1b, input p1c, input p1d, input p1e, input p1f,
                            output p1y,
                            input p2a, input p2b, input p2c, input p2d, 
                            output p2y  );

wire and2ab;
wire and2cd;

wire and3abc;
wire and3def;


assign and2ab = p2a & p2b;
assign and2cd = p2c & p2d;

assign and3abc = p1a & p1b & p1c;
assign and3def = p1d & p1e & p1f;


assign p1y = and3abc | and3def;
assign p2y = and2ab | and2cd;


endmodule



module direct_7458 (  input p1a, input p1b, input p1c, input p1d, input p1e, input p1f,
                            output p1y,
                            input p2a, input p2b, input p2c, input p2d, 
                            output p2y  );

assign p1y = (p1a & p1b & p1c) | (p1d & p1e & p1f);
assign p2y = (p2a & p2b) | (p2c & p2d);

endmodule