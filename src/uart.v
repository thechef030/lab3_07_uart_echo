`timescale 1ns/1ps

module uart_rx #(
    parameter integer DIV = 5208
) (
    input  wire       clk,
    input  wire       rst_p,
    input  wire       rx,
    output reg  [7:0] data,
    output reg        valid,
    output reg        framing_error
);

    (* ASYNC_REG="TRUE" *) reg [1:0] sync;

    reg [1:0] state;
    integer timer;
    reg [2:0] bitno;
    reg [7:0] shift;

    always @(posedge clk) begin
        if (rst_p) begin
            sync <= 3;
            state <= 0;
            timer <= 0;
            bitno <= 0;
            shift <= 0;
            data <= 0;
            valid <= 0;
            framing_error <= 0;
        end
        else begin
            sync <= {sync[0], rx};
            valid <= 0;
            framing_error <= 0;

            case (state)

                0: begin
                    if (!sync[1]) begin
                        timer <= DIV/2 - 1;
                        state <= 1;
                    end
                end

                1: begin
                    if (timer != 0)
                        timer <= timer - 1;
                    else if (sync[1])
                        state <= 0;
                    else begin
                        timer <= DIV - 1;
                        bitno <= 0;
                        state <= 2;
                    end
                end

                2: begin
                    if (timer != 0)
                        timer <= timer - 1;
                    else begin
                        shift[bitno] <= sync[1];
                        timer <= DIV - 1;

                        if (bitno == 7)
                            state <= 3;
                        else
                            bitno <= bitno + 1'b1;
                    end
                end

                3: begin
                    if (timer != 0)
                        timer <= timer - 1;
                    else begin
                        if (sync[1]) begin
                            data <= shift;
                            valid <= 1;
                        end
                        else begin
                            framing_error <= 1;
                        end

                        state <= 0;
                    end
                end

            endcase
        end
    end

endmodule


module uart_tx #(
    parameter integer DIV = 5208
) (
    input  wire       clk,
    input  wire       rst_p,
    input  wire       valid,
    input  wire [7:0] data,
    output wire       ready,
    output wire       tx
);

    reg [9:0] shift;
    reg [3:0] remaining;
    integer timer;

    assign ready = (remaining == 0);
    assign tx = ready ? 1'b1 : shift[0];

    always @(posedge clk) begin
        if (rst_p) begin
            shift <= 10'h3ff;
            remaining <= 0;
            timer <= 0;
        end
        else if (ready) begin
            if (valid) begin
                shift <= {1'b1, data, 1'b0};
                remaining <= 10;
                timer <= DIV - 1;
            end
        end
        else if (timer != 0) begin
            timer <= timer - 1;
        end
        else begin
            timer <= DIV - 1;
            shift <= {1'b1, shift[9:1]};
            remaining <= remaining - 1'b1;
        end
    end

endmodule
