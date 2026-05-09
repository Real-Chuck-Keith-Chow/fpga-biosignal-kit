`timescale 1ns/1ps

module uart_tx #(
    parameter int unsigned CLK_HZ = 50_000_000,
    parameter int unsigned BAUD   = 115200
)(
    input  logic       clk,
    input  logic       rst_n,
    input  logic [7:0] data_i,
    input  logic       valid_i,

    output logic       busy_o,
    output logic       tx_o
);

    localparam int unsigned DIV = CLK_HZ / BAUD;

    logic [$clog2(DIV)-1:0] div_cnt_q;
    logic [3:0]             bit_cnt_q;
    logic [9:0]             frame_q;
    logic                   busy_q;

    assign busy_o = busy_q;
    assign tx_o   = busy_q ? frame_q[0] : 1'b1;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            div_cnt_q <= '0;
            bit_cnt_q <= '0;
            frame_q   <= 10'h3FF;
            busy_q    <= 1'b0;
        end else begin
            if (!busy_q) begin
                div_cnt_q <= '0;
                bit_cnt_q <= '0;

                if (valid_i) begin
                    frame_q <= {1'b1, data_i, 1'b0};
                    busy_q  <= 1'b1;
                end
            end else if (div_cnt_q == DIV - 1) begin
                div_cnt_q <= '0;
                frame_q   <= {1'b1, frame_q[9:1]};
                bit_cnt_q <= bit_cnt_q + 1'b1;

                if (bit_cnt_q == 9)
                    busy_q <= 1'b0;
            end else begin
                div_cnt_q <= div_cnt_q + 1'b1;
            end
        end
    end

endmodule
