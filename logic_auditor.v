module logic_auditor(
    input wire clk,
    input wire hw_reset,
    input wire [7:0] sensors,
    input wire [31:0] plc_timer,
    output wire ALERT
);
    localparam [31:0] THRESHOLD = 32'h00FF_FFFF;
    wire logic_bomb = sensors[0] & sensors[1] & (plc_timer > THRESHOLD);
    reg latch_alert;
    always @(posedge clk or posedge hw_reset) begin
        if (hw_reset)
            latch_alert <= 1'b0;
        else if (logic_bomb)
            latch_alert <= 1'b1;
    end
    assign ALERT = latch_alert | logic_bomb;
endmodule

