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

    typedef enum logic [1:0] {
        IDLE  = 2'd0,
        START = 2'd1,
        DATA  = 2'd2,
        STOP  = 2'd3
    } state_t;

    state_t state_q, state_d;
    logic [15:0] div_cnt_q, div_cnt_d;
    logic [3:0]  bit_cnt_q, bit_cnt_d;
    logic [9:0]  shreg_q, shreg_d;
    logic        tx_d, tx_q;
    logic        busy_d, busy_q;

    always_comb begin
        state_d   = state_q;
        div_cnt_d = div_cnt_q + 1;
        bit_cnt_d = bit_cnt_q;
        shreg_d   = shreg_q;
        tx_d      = tx_q;
        busy_d    = busy_q;

        if (div_cnt_q == DIV-1) div_cnt_d = 0;

        case (state_q)
            IDLE: begin
                tx_d   = 1'b1;
                busy_d = 1'b0;
                if (valid_i) begin
                    shreg_d = {1'b1, data_i, 1'b0};
                    bit_cnt_d = 0;
                    state_d = START;
                    busy_d = 1'b1;
                    div_cnt_d = 0;
                end
            end

            START, DATA, STOP: begin
                busy_d = 1'b1;
                if (div_cnt_q == DIV-1) begin
                    tx_d = shreg_q[0];
                    shreg_d = {1'b1, shreg_q[9:1]};
                    bit_cnt_d = bit_cnt_q + 1;
                    if (bit_cnt_q == 9) begin
                        state_d = IDLE;
                        busy_d  = 1'b0;
                    end
                end
            end
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q   <= IDLE;
            div_cnt_q <= 0;
            bit_cnt_q <= 0;
            shreg_q   <= 10'h3FF;
            tx_q      <= 1'b1;
            busy_q    <= 1'b0;
        end else begin
            state_q   <= state_d;
            div_cnt_q <= div_cnt_d;
            bit_cnt_q <= bit_cnt_d;
            shreg_q   <= shreg_d;
            tx_q      <= tx_d;
            busy_q    <= busy_d;
        end
    end

    assign tx_o   = tx_q;
    assign busy_o = busy_q;

endmodule
