`timescale 1ns/1ps

module adc_interface #(
    parameter int unsigned WIDTH   = 12,
    parameter int unsigned SPI_DIV = 100
)(
    input  logic             clk,
    input  logic             rst_n,
    input  logic             start_i,

    output logic [WIDTH-1:0] data_o,
    output logic             valid_o,

    output logic             adc_sclk_o,
    output logic             adc_cs_n_o,
    output logic             adc_mosi_o,
    input  logic             adc_miso_i
);

    typedef enum logic [1:0] {
        IDLE,
        SHIFT,
        DONE
    } state_t;

    state_t state_q;
    logic [WIDTH-1:0] shift_q;
    logic [$clog2(WIDTH+1)-1:0] bit_cnt_q;
    logic [$clog2(SPI_DIV)-1:0] div_cnt_q;
    logic sclk_q;

    assign adc_mosi_o = 1'b0;
    assign adc_sclk_o = sclk_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q    <= IDLE;
            shift_q    <= '0;
            bit_cnt_q  <= '0;
            div_cnt_q  <= '0;
            sclk_q     <= 1'b0;
            adc_cs_n_o <= 1'b1;
            data_o     <= '0;
            valid_o    <= 1'b0;
        end else begin
            valid_o <= 1'b0;

            case (state_q)
                IDLE: begin
                    adc_cs_n_o <= 1'b1;
                    sclk_q     <= 1'b0;
                    div_cnt_q  <= '0;

                    if (start_i) begin
                        adc_cs_n_o <= 1'b0;
                        bit_cnt_q  <= WIDTH;
                        shift_q    <= '0;
                        state_q    <= SHIFT;
                    end
                end

                SHIFT: begin
                    if (div_cnt_q == SPI_DIV - 1) begin
                        div_cnt_q <= '0;
                        sclk_q    <= ~sclk_q;

                        if (!sclk_q) begin
                            shift_q   <= {shift_q[WIDTH-2:0], adc_miso_i};
                            bit_cnt_q <= bit_cnt_q - 1'b1;

                            if (bit_cnt_q == 1)
                                state_q <= DONE;
                        end
                    end else begin
                        div_cnt_q <= div_cnt_q + 1'b1;
                    end
                end

                DONE: begin
                    adc_cs_n_o <= 1'b1;
                    sclk_q     <= 1'b0;
                    data_o     <= shift_q;
                    valid_o    <= 1'b1;
                    state_q    <= IDLE;
                end
            endcase
        end
    end

endmodule
