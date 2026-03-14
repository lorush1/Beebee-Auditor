`timescale 1ns/1ps
module tb_top;
    reg clk;
    reg rst_n;
    reg spi_sck;
    reg spi_ss_n;
    reg spi_mosi;
    reg hw_reset;
    reg physical_output;
    reg [31:0] plc_timer;
    reg [7:0] sensors;
    wire capture_active;
    wire ALERT;
    wire EMERGENCY_STOP;
    real attack_time;
    real stop_time;
    top dut(
        .clk(clk),
        .rst_n(rst_n),
        .spi_sck(spi_sck),
        .spi_ss_n(spi_ss_n),
        .spi_mosi(spi_mosi),
        .hw_reset(hw_reset),
        .physical_output(physical_output),
        .plc_timer(plc_timer),
        .sensors(sensors),
        .capture_active(capture_active),
        .ALERT(ALERT),
        .EMERGENCY_STOP(EMERGENCY_STOP)
    );
    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);
        clk = 0;
        rst_n = 0;
        spi_sck = 0;
        spi_ss_n = 1;
        spi_mosi = 0;
        hw_reset = 1;
        physical_output = 0;
        plc_timer = 32'h0;
        sensors = 8'h0;
        attack_time = 0.0;
        stop_time = 0.0;
        #5 rst_n = 1;
        #5 hw_reset = 0;
    end
    always #2.5 clk = ~clk;
    initial begin
        #20 sensors = 8'h03;
        plc_timer = 32'h01000000;
        physical_output = 1;
        attack_time = $realtime;
        #1;
        wait (EMERGENCY_STOP);
        stop_time = $realtime;
        if (stop_time - attack_time >= 10.0)
            $fatal;
        $finish;
    end
endmodule
