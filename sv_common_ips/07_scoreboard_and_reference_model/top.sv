// top.sv - Lesson 07
//
// Focus:
//  - A simple FIFO DUT that is easy to model in C++
//  - C++ scoreboard + reference model can check every transfer
//
// The DUT is intentionally small so the testbench structure is the main lesson.

module top (
    input  logic clk,
    input  logic rst_n,

    input  logic       in_valid,
    input  logic [7:0] in_data,
    output logic       in_ready,

    input  logic       out_ready,
    output logic       out_valid,
    output logic [7:0] out_data,

    output logic [3:0] count
);
    localparam int DEPTH = 8;
    localparam int AW = $clog2(DEPTH);

    logic [7:0] mem [0:DEPTH-1];
    logic [AW-1:0] wptr;
    logic [AW-1:0] rptr;
    logic [AW:0] used;

    logic push;
    logic pop;

    assign in_ready = (int'(used) < DEPTH);
    assign out_valid = (used != 0);
    assign out_data = mem[rptr];
    assign count = used[3:0];

    assign push = in_valid && in_ready;
    assign pop = out_ready && out_valid;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            wptr <= '0;
            rptr <= '0;
            used <= '0;
        end else begin
            if (push) begin
                mem[wptr] <= in_data;
                wptr <= wptr + 1'b1;
            end

            if (pop) begin
                rptr <= rptr + 1'b1;
            end

            unique case ({push, pop})
                2'b10: used <= used + 1'b1;
                2'b01: used <= used - 1'b1;
                default: used <= used;
            endcase
        end
    end

endmodule
