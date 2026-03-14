module shadow_comparator(
    input wire clk,
    input wire rst_n,
    input wire shadow_output,
    input wire physical_output,
    output reg emergency_stop
);
    reg shadow_delayed;
    wire match = (physical_output == shadow_output) || (physical_output == shadow_delayed);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shadow_delayed <= 1'b0;
            emergency_stop <= 1'b0;
        end else begin
            shadow_delayed <= shadow_output;
            if (!match)
                emergency_stop <= 1'b1;
        end
    end
endmodule

module shadow_plc(
    input wire clk,
    input wire rst_n,
    input wire input_a,
    input wire physical_output,
    output wire output_q,
    output wire EMERGENCY_STOP
);
    reg [4:0] delay_shift;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            delay_shift <= 5'b0;
        else
            delay_shift <= {delay_shift[3:0], input_a};
    end
    assign output_q = delay_shift[4];
    wire comparator_stop;
    shadow_comparator comparator(
        .clk(clk),
        .rst_n(rst_n),
        .shadow_output(output_q),
        .physical_output(physical_output),
        .emergency_stop(comparator_stop)
    );
    assign EMERGENCY_STOP = comparator_stop;
endmodule
