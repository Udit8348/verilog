# 00 Literals and Datatypes Highlights


combinational reg (old verilog) becomes `always_comb` similar to level sensitive to inputs
```verilog
reg y;
always @(*) begin
  y = a & b;
end
```

sequential reg (old verilog) becomes `always_ff` similar to edge triggered
```verilog
reg y;
always @(posedge clk) begin
  y <= d;
end
```

wire
```verilog
wire y;
assign y = a & b;
```

There are also some other nettypes (tri, wand, etc) ... Not used commonly compared to `logic` (sv) and `reg`/`wire`. You might see it in
Multi-driver nets, tri-states, wand/wor are mostly:
- testbench modeling,
- board-level / IO modeling,
- gate-level netlists,
- special buses (I²C-like open-drain) where the IO cell handles it.


There are two different types of assignment operators `=` (blocking, think like sw) and `<=` (nonblocking, think like hw). Still important in System Verilog.
- `=` inside `always_comb` / `always @(*)` (combinational)
- `<=` inside `always_ff` / `always @(posedge clk ...)` (sequential)

SystemVerilog allows you to create `struct` and `enum` for improved expressiveness.

`unique` also helps improve expressiveness by indicating to linter to check that one branch should match

Do we need intermediate signals? Not always. In this small example we have `u16_split_t pack_me;` that is used `assign out_struct_pack = pack_me;` We could have done this:

```
always_ff @(posedge clk) begin
  if (!rst_n)
    out_struct_pack <= '0;
  else
    out_struct_pack <= {b, in_u8};  // hi=b, lo=in_u8
end
```