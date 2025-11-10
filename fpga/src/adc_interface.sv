`timescale 1ns/1ps

module adc_interface #(
    parameter int unsigned CLK_HZ  = 50_000_000,
    parameter int unsigned WIDTH   = 12,
    parameter int unsigned SPI_DIV = 100
)(
    input  logic clk,
    input  logic rst_n,
    input  logic start_i,
    output logic [WIDTH-1:0] data_o,
    output logic valid_o,
    output logic adc_sclk_o,
    output logic adc_cs_n_o,
    output logic adc_mosi_o,
    input  logic adc_miso_i
);

    typedef enum logic [1:0] {
        IDLE  = 2'd0,
        SHIFT = 2'd1,
        DONE  = 2'd2
    } state_t;

    state_t state_q, state_d;
    logic [WIDTH-1:0] shift_reg_q, shift_reg_d;
    logic [$clog2(WIDTH):0] bit_cnt_q, bit_cnt_d;
    logic [15:0] div_cnt_q, div_cnt_d;
    logic sclk_en_d, sclk_en_q;
    logic spi_clk_edge;

    always_comb begin
        div_cnt_d = div_cnt_q + 1;
        spi_clk_edge = 1'b0;
        if (div_cnt_q == SPI_DIV-1) begin
            div_cnt_d = 0;
            spi_clk_edge = 1'b1;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            div_cnt_q <= 0;
        else
            div_cnt_q <= div_cnt_d;
    end

    always_comb begin
        state_d = state_q;
        shift_reg_d = shift_reg_q;
        bit_cnt_d = bit_cnt_q;
        sclk_en_d = sclk_en_q;
        adc_cs_n_o = 1'b1;
        adc_mosi_o = 1'b0;
        adc_sclk_o = 1'b0;
        valid_o = 1'b0;
        data_o = shift_reg_q;

        case (state_q)
            IDLE: begin
                if (start_i) begin
                    adc_cs_n_o = 1'b0;
                    state_d = SHIFT;
                    bit_cnt_d = WIDTH;
                    shift_reg_d = '0;
                end
            end

            SHIFT: begin
                adc_cs_n_o = 1'b0;
                sclk_en_d = 1'b1;
                adc_sclk_o = sclk_en_q;
                if (spi_clk_edge) begin
                    shift_reg_d = {shift_reg_q[WIDTH-2:0], adc_miso_i};
                    bit_cnt_d = bit_cnt_q - 1;
                    if (bit_cnt_q == 0)
                        state_d = DONE;
                end
            end

            DONE: begin
                adc_cs_n_o = 1'b1;
                sclk_en_d = 1'b0;
                valid_o = 1'b1;
                state_d = IDLE;
                data_o = shift_reg_q;
            end
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q <= IDLE;
            shift_reg_q <= '0;
            bit_cnt_q <= '0;
            sclk_en_q <= 1'b0;
        end else begin
            state_q <= state_d;
            shift_reg_q <= shift_reg_d;
            bit_cnt_q <= bit_cnt_d;
            sclk_en_q <= sclk_en_d;
        end
    end

`ifndef SYNTHESIS
    real phase = 0.0;
    always_ff @(posedge clk) begin
        if (valid_o) begin
            phase = phase + 0.05;
            data_o <= $rtoi(2048 + 1000*$sin(phase) + $urandom_range(-50,50));
        end
    end
`endif

endmodule
