// producer.sv
//
// Simple pattern generator: when enabled, it emits incrementing bytes.
// It follows ready/valid handshake:
//  - If valid && ready: transfer happens, advance to next value
//  - If valid && !ready: hold data stable, keep valid asserted

module producer (
    input  logic rst_n,
    input  logic en,
    rv_if.producer bus
);
    logic [7:0] counter;

    always_ff @(posedge bus.clk) begin
        if (!rst_n) begin
            counter   <= 8'd0;
            bus.valid <= 1'b0;
            bus.data  <= 8'd0;
        end else begin
            if (!en) begin
                // When disabled, deassert valid
                bus.valid <= 1'b0;
            end else begin
                // When enabled, assert valid and present current counter
                bus.valid <= 1'b1;
                bus.data  <= counter;

                // Advance only on successful handshake
                if (bus.valid && bus.ready) begin
                    counter <= counter + 8'd1;
                end
            end
        end
    end
endmodule