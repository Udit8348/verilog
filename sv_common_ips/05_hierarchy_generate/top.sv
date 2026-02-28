// top.sv - Lesson 05
//
// Focus:
//  - parameters
//  - generate-for loops
//  - hierarchical structure you can see in the wave
//
// We build a small “pipeline” of N registers using generate.

module reg_stage #(parameter int W = 8) (
    input  logic clk,
    input  logic rst_n,
    input  logic [W-1:0] d,
    output logic [W-1:0] q
);
    always_ff @(posedge clk) begin
        if (!rst_n) q <= '0;
        else        q <= d;
    end
endmodule

module top #(
    parameter int W = 8,
    parameter int N = 4
)(
    input  logic clk,
    input  logic rst_n,
    input  logic [W-1:0] in_data,
    output logic [W-1:0] out_data
);
    // Array of signals between stages
    logic [W-1:0] pipe [0:N];

    assign pipe[0] = in_data;
    assign out_data = pipe[N];

    // Generate N stages
    genvar i;
    generate
        for (i = 0; i < N; i++) begin : GEN_STAGES
            reg_stage #(.W(W)) u_stage (
                .clk(clk),
                .rst_n(rst_n),
                .d(pipe[i]),
                .q(pipe[i+1])
            );
        end
    endgenerate

endmodule