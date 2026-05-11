`timescale 1ns/1ps

module top_module #(
    parameter int unsigned CLK_HZ    = 50_000_000,
    parameter int unsigned SAMPLE_HZ = 1_000,
    parameter int unsigned ADC_WIDTH = 12,
    parameter int unsigned UART_BAUD = 115200
)(
    input  logic                 clk,
    input  logic                 rst_n,

    output logic                 adc_sclk_o,
    output logic                 adc_cs_n_o,
    output logic                 adc_mosi_o,
    input  logic                 adc_miso_i,

    output logic                 uart_tx_o,

    output logic [ADC_WIDTH-1:0] dbg_last_sample_o,
    output logic                 dbg_sample_tick_o
);

    localparam int unsigned SAMPLE_DIV = CLK_HZ / SAMPLE_HZ;

    logic [$clog2(SAMPLE_DIV)-1:0] sample_cnt_q;
    logic sample_tick;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_cnt_q <= '0;
            sample_tick  <= 1'b0;
        end else begin
            sample_tick <= 1'b0;

            if (sample_cnt_q == SAMPLE_DIV - 1) begin
                sample_cnt_q <= '0;
                sample_tick  <= 1'b1;
            end else begin
                sample_cnt_q <= sample_cnt_q + 1'b1;
            end
        end
    end

    assign dbg_sample_tick_o = sample_tick;

    logic [ADC_WIDTH-1:0] adc_data;
    logic adc_valid;

    adc_interface #(
        .WIDTH(ADC_WIDTH)
    ) u_adc (
        .clk(clk),
        .rst_n(rst_n),
        .start_i(sample_tick),
        .data_o(adc_data),
        .valid_o(adc_valid),
        .adc_sclk_o(adc_sclk_o),
        .adc_cs_n_o(adc_cs_n_o),
        .adc_mosi_o(adc_mosi_o),
        .adc_miso_i(adc_miso_i)
    );

    logic [ADC_WIDTH-1:0] filt_data;
    logic filt_valid;

    filter #(
        .WIDTH(ADC_WIDTH)
    ) u_filter (
        .clk(clk),
        .rst_n(rst_n),
        .data_i(adc_data),
        .valid_i(adc_valid),
        .data_o(filt_data),
        .valid_o(filt_valid)
    );

    typedef enum logic [1:0] {
        SEND_IDLE,
        SEND_HEADER,
        SEND_HIGH,
        SEND_LOW
    } send_state_t;

    send_state_t send_state_q;
    logic [ADC_WIDTH-1:0] sample_q;
    logic [7:0] uart_data;
    logic uart_valid;
    logic uart_busy;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            send_state_q      <= SEND_IDLE;
            sample_q          <= '0;
            uart_data         <= 8'h00;
            uart_valid        <= 1'b0;
            dbg_last_sample_o <= '0;
        end else begin
            uart_valid <= 1'b0;

            case (send_state_q)
                SEND_IDLE: begin
                    if (filt_valid) begin
                        sample_q          <= filt_data;
                        dbg_last_sample_o <= filt_data;
                        send_state_q      <= SEND_HEADER;
                    end
                end

                SEND_HEADER: begin
                    if (!uart_busy) begin
                        uart_data    <= 8'hA5;
                        uart_valid   <= 1'b1;
                        send_state_q <= SEND_HIGH;
                    end
                end

                SEND_HIGH: begin
                    if (!uart_busy) begin
                        uart_data    <= sample_q[11:4];
                        uart_valid   <= 1'b1;
                        send_state_q <= SEND_LOW;
                    end
                end

                SEND_LOW: begin
                    if (!uart_busy) begin
                        uart_data    <= {sample_q[3:0], 4'b0};
                        uart_valid   <= 1'b1;
                        send_state_q <= SEND_IDLE;
                    end
                end
            endcase
        end
    end

    uart_tx #(
        .CLK_HZ(CLK_HZ),
        .BAUD(UART_BAUD)
    ) u_uart (
        .clk(clk),
        .rst_n(rst_n),
        .data_i(uart_data),
        .valid_i(uart_valid),
        .busy_o(uart_busy),
        .tx_o(uart_tx_o)
    );

endmodule
