module top (
    input  clk,
    input  rst_n,
    input  [7:0] in_u8,
    input  signed [7:0] in_s8,
    output reg [7:0] out_sum_u,            // REG: driven in always @(posedge clk)
    output reg signed [8:0] out_sum_s,      // REG: driven in always @(posedge clk)
    output [3:0] out_enum_bits,             // WIRE: driven by continuous assign
    output [15:0] out_struct_pack           // WIRE: driven by continuous assign
);

    // REG: these are variables (procedurally assigned via initial); in SV you used "logic ... = ..."
    reg [7:0] a;
    reg [7:0] b;
    reg [7:0] c;

    // REG: Verilog integer is typically 32-bit signed
    integer unsized;

    // REG: variables initialized once
    reg [15:0] fill0;
    reg [15:0] fill1;
    reg [15:0] fillx;
    reg [15:0] fillz;

    // REG: 2-state-ish concept from SV "bit" (Verilog reg is 4-state, but this is for the lesson)
    reg two_state_flag;

    // REG: SV "logic" -> Verilog reg (still 4-state)
    reg four_state_flag;

    // REG: enum replaced by explicit 4-bit state encoding
    reg [3:0] state;

    // REG: packed struct replaced by a single 16-bit packed reg
    reg [15:0] pack_me;

    // State encodings (enum replacement)
    localparam [3:0] ST_IDLE = 4'h0;
    localparam [3:0] ST_RUN  = 4'h1;
    localparam [3:0] ST_ERR  = 4'hE;
    localparam [3:0] ST_DONE = 4'hF;

    // WIRE: used for combinational "next state" (keeps always block simple)
    wire [3:0] next_state;

    // WIRE: used for the signed add (explicit widening/casting replacement for $signed usage)
    wire signed [8:0] a_widen_s;
    assign a_widen_s = {1'b0, a}; // ASSIGN: zero-extend a to 9 bits, then treated as signed

    // WIRE + ASSIGN: combinational next-state logic (replacement for unique case + ?:)
    assign next_state =
        (state == ST_IDLE) ? ((in_u8 == 8'h00) ? ST_IDLE : ST_RUN) :
        (state == ST_RUN ) ? ((in_u8 == 8'hFF) ? ST_DONE : ST_RUN) :
        (state == ST_DONE) ? ST_DONE :
                             ST_ERR;

    // INITIAL: replaces SV variable declarations with initial values
    initial begin
        a       = 8'hA5;
        b       = 8'd10;
        c       = 8'b00111100;
        unsized = 32'hFFFF_FF00;
        fill0   = 16'h0000;
        fill1   = 16'hFFFF;
        fillx   = 16'hXXXX;
        fillz   = 16'hZZZZ;
        two_state_flag  = 1'b0;
        four_state_flag = 1'b0;
        state   = ST_IDLE;
        pack_me = 16'h0000;
        out_sum_u = 8'h00;
        out_sum_s = 9'sh000;
    end

    // REGs updated on clock edge (replacement for always_ff)
    always @(posedge clk) begin
        if (!rst_n) begin
            state <= ST_IDLE;
            out_sum_u <= 8'h00;
            out_sum_s <= 9'sh000;
            two_state_flag <= 1'b0;
            four_state_flag <= 1'b0;
            pack_me <= 16'h0000;
        end else begin
            out_sum_u <= in_u8 + a;

            // Signed add: in_s8 is signed [7:0]; widen to 9 bits by repeating sign bit.
            out_sum_s <= {in_s8[7], in_s8} + a_widen_s;

            state <= next_state;

            // Pack two bytes: lo=in_u8, hi=b (struct replacement)
            pack_me[7:0]   <= in_u8;
            pack_me[15:8]  <= b;

            // 2-state vs 4-state compare demo
            two_state_flag <= (in_u8[0] == 1'b1);
            four_state_flag <= (in_u8[0] === 1'b1);
        end
    end

    // ASSIGN: continuous assignments drive outputs that are wires
    assign out_enum_bits   = state;
    assign out_struct_pack = pack_me;

endmodule