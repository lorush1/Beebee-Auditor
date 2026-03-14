module bus_monitor (
    input wire clk,
    input wire rst_n,
    input wire spi_sck,
    input wire spi_ss_n,
    input wire spi_mosi,
    output reg capture_active
);
localparam [31:0] START_SIG = {8'h53, 8'h54, 8'h41, 8'h52};
reg sck_d;
reg [7:0] shift_reg;
reg [2:0] bit_cnt;
reg [7:0] byte_val;
reg byte_valid;
reg [31:0] window;
wire [31:0] next_window = {window[23:0], byte_val};

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sck_d <= 0;
        shift_reg <= 0;
        bit_cnt <= 0;
        byte_val <= 0;
        byte_valid <= 0;
        window <= 0;
        capture_active <= 0;
    end else begin
        sck_d <= spi_sck;
        if (spi_ss_n) begin
            bit_cnt <= 0;
            shift_reg <= 0;
            byte_valid <= 0;
            window <= 0;
            capture_active <= 0;
        end
        if (byte_valid) begin
            window <= next_window;
            if (next_window == START_SIG)
                capture_active <= 1;
            byte_valid <= 0;
        end
        if (!spi_ss_n && !sck_d && spi_sck) begin
            shift_reg <= {shift_reg[6:0], spi_mosi};
            if (bit_cnt == 3'd7) begin
                bit_cnt <= 0;
                byte_val <= {shift_reg[6:0], spi_mosi};
                byte_valid <= 1;
            end else begin
                bit_cnt <= bit_cnt + 1;
            end
        end
    end
end
endmodule
