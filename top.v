module top(
    input wire clk,
    input wire rst_n,
    input wire spi_sck,
    input wire spi_ss_n,
    input wire spi_mosi,
    input wire hw_reset,
    input wire physical_output,
    input wire [31:0] plc_timer,
    input wire [7:0] sensors,
    output wire capture_active,
    output wire ALERT,
    output wire EMERGENCY_STOP
);
    wire shadow_output_q;
    bus_monitor bus_monitor_inst(
        .clk(clk),
        .rst_n(rst_n),
        .spi_sck(spi_sck),
        .spi_ss_n(spi_ss_n),
        .spi_mosi(spi_mosi),
        .capture_active(capture_active)
    );
    logic_auditor logic_auditor_inst(
        .clk(clk),
        .hw_reset(hw_reset),
        .sensors(sensors),
        .plc_timer(plc_timer),
        .ALERT(ALERT)
    );
    shadow_plc shadow_plc_inst(
        .clk(clk),
        .rst_n(rst_n),
        .input_a(ALERT),
        .physical_output(physical_output),
        .output_q(shadow_output_q),
        .EMERGENCY_STOP(EMERGENCY_STOP)
    );
endmodule
