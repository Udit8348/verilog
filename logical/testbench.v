/*
    In this demo, we demonstrate the difference between logical (&&) and bitwise (&)
    Note: in the degenerate one-bit case they will have the same output, but otherwise that is not always true
    Note 2: for some reason, an instance cannot be named 'logic' could be an error related to iverilog compiler
    Note 3: 'and' is not valid syntax in verilog, despite chatGPT saying so
*/

module testbench();
    // create these as regs since we are not driving them
    reg[1:0] a;
    reg[1:0] b;
    wire[1:0] bt_out;
    wire lg_out;
    // todo: review assumed data range and formats for numbers
    // todo: what happens if we try this on negative numbers

    bitwise my_bitwise_inst(
    .a(a),
    .b(b),
    .bitwise_o(bt_out) // how exactly does this get marked as an output? what is bt_out doing?
    );

    // again, figure out what the arg .() stuff actually means here...
    logical my_logical_inst(
    .a(a),
    .b(b),
    .logical_o(lg_out)
    );

	// todo: how to set the time scale
    initial begin
        $dumpvars;
        a = 2'b00;
        b = 2'b01;
        #2
        a = 2'b11;
        b = 2'b01;
        #2
        a = 2'b00;
        b = 2'b11;
        #2
        a = 2'b11;
        b = 2'b10;
        #2
        $finish;
    end
endmodule