// consumer.sv
//
// Consumes bytes when valid && ready.
// Backpressures periodically by toggling ready.

module consumer (
    input  logic rst_n,
    rv_if.consumer bus,
    output logic [7:0] last_seen,
    output logic [15:0] count_seen
);
    always_ff @(posedge bus.clk) begin
        if (!rst_n) begin
            bus.ready  <= 1'b0;
            last_seen  <= 8'd0;
            count_seen <= 16'd0;
        end else begin
            // Simple periodic backpressure: ready is high for 3 cycles, low for 2.
            // You can see producer “hold” behavior in the waveform.
            if ((count_seen % 5) < 3) bus.ready <= 1'b1;
            else                      bus.ready <= 1'b0;

            if (bus.valid && bus.ready) begin
                last_seen  <= bus.data;
                count_seen <= count_seen + 16'd1;
            end
        end
    end
endmodule