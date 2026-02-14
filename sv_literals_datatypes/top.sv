// top.sv - Lesson 01
//
// Focus:
//  - Literal values (sized/unsized, based numbers, x/z)
//  - 2-state vs 4-state types (bit/logic)
//  - packed vectors vs unpacked arrays
//  - enums, structs, signed arithmetic
//
// Verilator note:
//  - This is all supported and synthesizable-ish; we still drive it from C++.

module top (
    input  logic clk,
    input  logic rst_n,

    // A few inputs from C++ so you can poke values and see how types behave.
    input  logic [7:0] in_u8,
    input  logic signed [7:0] in_s8,

    output logic [7:0] out_sum_u,     // unsigned sum demo
    output logic signed [8:0] out_sum_s, // signed sum demo
    output logic [3:0] out_enum_bits,
    output logic [15:0] out_struct_pack
);

    // -------------------------
    // Literal Values
    // -------------------------
    // Sized literals:
    logic [7:0] a = 8'hA5;     // 0xA5
    logic [7:0] b = 8'd10;     // decimal 10
    logic [7:0] c = 8'b0011_1100; // binary with underscores for readability

    // Unsized literal (default 32-bit, signed in many contexts). Avoid in RTL.
    // Here we show it intentionally.
    int unsized = 'hFFFF_FF00; // 32-bit int

    // '0, '1, 'x, 'z are width-filling literals.
    logic [15:0] fill0 = '0;   // all zeros
    logic [15:0] fill1 = '1;   // all ones
    logic [15:0] fillx = 'x;   // all X
    logic [15:0] fillz = 'z;   // all Z (tri-state; mostly for TB)

    // -------------------------
    // Data types: bit vs logic
    // -------------------------
    // bit is 2-state (0/1), logic is 4-state (0/1/X/Z).
    // In synthesizable code you typically use logic everywhere.
    bit   two_state_flag;
    logic four_state_flag;

    // -------------------------
    // Packed struct + enum
    // -------------------------
    typedef enum logic [3:0] {
        ST_IDLE = 4'h0,
        ST_RUN  = 4'h1,
        ST_ERR  = 4'hE,
        ST_DONE = 4'hF
    } state_e;

    state_e state;

    // A packed struct is like a single packed vector with named fields.
    typedef struct packed {
        logic [7:0] lo;
        logic [7:0] hi;
    } u16_split_t;

    u16_split_t pack_me;

    // -------------------------
    // Signed arithmetic demo
    // -------------------------
    // Unsigned sum: wraps mod 256 (because out_sum_u is 8 bits).
    // Signed sum: we widen to 9 bits to keep sign and show overflow behavior.
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state <= ST_IDLE;
            out_sum_u <= '0;
            out_sum_s <= '0;
            two_state_flag <= 1'b0;
            four_state_flag <= 1'b0;
            pack_me <= '{lo:'0, hi:'0};
        end else begin
            // show unsigned addition
            out_sum_u <= in_u8 + a; // both treated as unsigned vectors

            // show signed addition: cast/widen explicitly
            // in_s8 is signed, but a is unsigned; force sign extend carefully.
            out_sum_s <= $signed(in_s8) + $signed({1'b0, a}); // widen a to 9 bits then sign-cast

            // simple state progression based on input patterns
            unique case (state)
                ST_IDLE: state <= (in_u8 == 8'h00) ? ST_IDLE : ST_RUN;
                ST_RUN : state <= (in_u8 == 8'hFF) ? ST_DONE : ST_RUN;
                ST_DONE: state <= ST_DONE;
                default: state <= ST_ERR;
            endcase

            // pack two bytes into a struct for convenience
            pack_me.lo <= in_u8;
            pack_me.hi <= b;

            // show 2-state vs 4-state: if in_u8 contains X, logic can hold it (in a real sim)
            // Verilator is 2-state by default for many signals, but logic is still the right habit.
            two_state_flag <= (in_u8[0] == 1'b1);
            four_state_flag <= (in_u8[0] === 1'b1); // 4-state compare
        end
    end

    assign out_enum_bits = state;
    assign out_struct_pack = pack_me; // packed struct can be assigned like a vector

endmodule