/*
    Demo: demonstrate the difference between logical (&&) and bitwise (&), then view waveforms
    Note: in the degenerate one-bit case they will have the same output, but otherwise that is not always true
    Note 2: for some reason, an instance cannot be named 'logic' could be an error related to iverilog compiler

*/

module testbench();
    // create these as regs since we are not driving them
    // the output is a wire because ...
    reg[1:0] a;
    reg[1:0] b;
    wire[1:0] bt_out;
    wire lg_out;

    // example of a module instantiation
    bitwise my_bitwise_inst(
        .a(a),
        .b(b),
        .bitwise_o(bt_out)
    );

    logical my_logical_inst(
        .a(a),
        .b(b),
        .logical_o(lg_out)
    );

	
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