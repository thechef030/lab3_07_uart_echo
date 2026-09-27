`timescale 1ns/1ps

module lab3_uart_echo #(
    parameter integer CLK_HZ = 50_000_000,
    parameter integer BAUD = 9_600
) (
    input  wire       clk_50mhz,
    input  wire       rst_p,
    input  wire       uart_rxd,
    output wire       uart_txd,
    output wire [7:0] led
);

    localparam integer DIV = (CLK_HZ + BAUD/2) / BAUD;

    wire [7:0] rx_data;
    wire rx_valid;
    wire rx_framing_error;
    wire tx_ready;

    reg tx_valid;
    reg [7:0] tx_data;
    reg [7:0] last_data;

    uart_rx #(.DIV(DIV)) u_rx(
        .clk(clk_50mhz),
        .rst_p(rst_p),
        .rx(uart_rxd),
        .data(rx_data),
        .valid(rx_valid),
        .framing_error(rx_framing_error)
    );

    uart_tx #(.DIV(DIV)) u_tx(
        .clk(clk_50mhz),
        .rst_p(rst_p),
        .valid(tx_valid),
        .data(tx_data),
        .ready(tx_ready),
        .tx(uart_txd)
    );

    always @(posedge clk_50mhz or posedge rst_p) begin
        if (rst_p) begin
            tx_valid  <= 0;
            tx_data   <= 0;
            last_data <= 0;
        end
        else begin
            tx_valid <= 0;

            if (rx_valid) begin
                last_data <= rx_data;

                if (tx_ready) begin
                    tx_data  <= rx_data;
                    tx_valid <= 1;
                end
            end
        end
    end

    assign led = last_data;

endmodule
