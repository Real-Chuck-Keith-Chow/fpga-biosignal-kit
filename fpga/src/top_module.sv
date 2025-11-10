// ============================================================================
// Project: Smart Edge Biosignal Data Platform
// File   : top_module.sv
// Author : Chad Chow (Real-Chuck-Keith-Chow)
// Desc   : Top level that orchestrates ADC sampling (via adc_interface),
//          hardware filtering (filter), and framed UART streaming (uart_tx).
//          Produces a robust 3-byte frame per sample: [0xA5][HI][LO].
//
//          - Sample cadence is generated internally (SAMPLE_HZ).
//          - Filter path is clocked/synchronous; valid handshakes included.
//          - UART framing ensures easy parsing on Python/Node-RED side.
//
// Frame format (per sample):
//   Byte0: 0xA5 (header)
//   Byte1: HI   (sample[11:4])
//   Byte2: LO   ({sample[3:0], 4'b0})  // left-aligned 12-bit value
//
// NOTE: This top assumes SINGLE clock domain.
//       adc_interface must internally handle protocol timing (e.g., SPI).
// ============================================================================

`timescale 1ns/1ps

module top_module #(
    // -------- Clocks & Rates --------
    parameter int unsigned CLK_HZ     = 50_000_000,  // System clock
    parameter int unsigned SAMPLE_HZ  = 1_000,       // Target sample rate
    // -------- Data widths & UART ----
    parameter int unsigned ADC_WIDTH  = 12,
    parameter int unsigned UART_BAUD  = 115200
)(
    // Clock / Reset
    input  logic                      clk,
    input  logic                      rst_n,

    // ---- ADC physical interface pins (to be wired on your board) ----
    // For SPI-type ADC; if parallel ADC, tie unused and adapt adc_interface.
    output logic                      adc_sclk_o,
    output logic                      adc_cs_n_o,
    output logic                      adc_mosi_o,
    input  logic                      adc_miso_i,

    // UART TX to host
    output logic                      uart_tx_o,

    // Optional debug
    output logic [ADC_WIDTH-1:0]      dbg_last_sample_o,
    output logic                      dbg_sample_tick_o
);

    // =========================================================================
    // Local parameters and sanity
    // =========================================================================
    // Sample tick divider
    localparam int unsigned SAMPLE_DIV = (SAMPLE_HZ == 0) ? 1 : (CLK_HZ / SAMPLE_HZ);
    initial begin
        // Guard against accidental 0 or too-small divider
        if (SAMPLE_DIV < 4) begin
            $warning("SAMPLE_DIV is very small (%0d). Check CLK_HZ/SAMPLE_HZ.", SAMPLE_DIV);
        end
    end

    // =========================================================================
    // Sample tick generator
    // =========================================================================
    logic [$clog2(SAMPLE_DIV)-1:0] sample_cnt_q, sample_cnt_d;
    logic                          sample_tick_d, sample_tick_q;

    always_comb begin
        sample_cnt_d   = sample_cnt_q;
        sample_tick_d  = 1'b0;
        if (sample_cnt_q == SAMPLE_DIV-1) begin
            sample_cnt_d  = '0;
            sample_tick_d = 1'b1;
        end else begin
            sample_cnt_d  = sample_cnt_q + 1'b1;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_cnt_q  <= '0;
            sample_tick_q <= 1'b0;
        end else begin
            sample_cnt_q  <= sample_cnt_d;
            sample_tick_q <= sample_tick_d;
        end
    end

    assign dbg_sample_tick_o = sample_tick_q;

    // =========================================================================
    // ADC interface
    //   - We assert 'start_i' on each sample_tick.
    //   - adc_interface returns (data_o, valid_o) when a fresh sample is ready.
    // =========================================================================
    logic [ADC_WIDTH-1:0] adc_data;
    logic                 adc_valid;

    adc_interface #(
        .CLK_HZ   (CLK_HZ),
        .WIDTH    (ADC_WIDTH)
    ) u_adc_if (
        .clk        (clk),
        .rst_n      (rst_n),
        // control
        .start_i    (sample_tick_q),
        .data_o     (adc_data),
        .valid_o    (adc_valid),
        // physical pins
        .adc_sclk_o (adc_sclk_o),
        .adc_cs_n_o (adc_cs_n_o),
        .adc_mosi_o (adc_mosi_o),
        .adc_miso_i (adc_miso_i)
    );

    // =========================================================================
    // Filtering (simple MA / IIR etc. inside filter.sv)
    //   - Handshake: valid_i -> valid_o
    // =========================================================================
    logic [ADC_WIDTH-1:0] filt_data;
    logic                 filt_valid;

    filter #(
        .WIDTH (ADC_WIDTH)
    ) u_filter (
        .clk     (clk),
        .rst_n   (rst_n),
        .data_i  (adc_data),
        .valid_i (adc_valid),
        .data_o  (filt_data),
        .valid_o (filt_valid)
    );

    // =========================================================================
    // Byte framing for UART:
    //   On each filt_valid, we enqueue 3 bytes:
    //     [0] 0xA5 header
    //     [1] HI byte  = filt_data[11:4]
    //     [2] LO byte  = {filt_data[3:0], 4'b0}
    //
    //   A tiny 4-entry byte FIFO is used (shift-register style).
    //   We pop when uart is idle (not busy) and present valid_i for one cycle.
    // =========================================================================
    localparam int unsigned FIFO_DEPTH = 4;
    logic [7:0] fifo_q [0:FIFO_DEPTH-1];
    logic [2:0] fifo_count_q, fifo_count_d;  // can hold up to 4 bytes
    logic       fifo_pop, fifo_push_3;       // push 3 bytes as a burst

    // Prepare bytes from latest sample
    logic [7:0] byte_hdr, byte_hi, byte_lo;
    assign byte_hdr = 8'hA5;
    assign byte_hi  = {filt_data[ADC_WIDTH-1 -: 8]}; // take upper 8 bits (for WIDTH>=12 this maps to [11:4])
    assign byte_lo  = {filt_data[3:0], 4'b0};

    // FIFO push on filt_valid if space allows (need space for 3 bytes)
    wire fifo_has_room_for_3 = (fifo_count_q <= (FIFO_DEPTH-3));

    // FIFO next-state logic
    integer i;
    always_comb begin
        // default
        for (i = 0; i < FIFO_DEPTH; i++) begin
            fifo_q[i] = fifo_q[i];
        end
        fifo_count_d = fifo_count_q;

        // Push burst (3 bytes) at filt_valid
        if (filt_valid && fifo_has_room_for_3) begin
            // push at the tail
            fifo_q[fifo_count_q + 0] = byte_hdr;
            fifo_q[fifo_count_q + 1] = byte_hi;
            fifo_q[fifo_count_q + 2] = byte_lo;
            fifo_count_d             = fifo_count_q + 3;
        end

        // Pop one when UART takes a byte (signaled via fifo_pop)
        if (fifo_pop && (fifo_count_d != 0)) begin
            // shift down
            for (i = 0; i < FIFO_DEPTH-1; i++) begin
                fifo_q[i] = fifo_q[i+1];
            end
            fifo_q[FIFO_DEPTH-1] = 8'h00;
            fifo_count_d         = fifo_count_d - 1;
        end
    end

    // FIFO registers
    logic [7:0] fifo_r [0:FIFO_DEPTH-1];
    logic [2:0] fifo_count_r;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int k = 0; k < FIFO_DEPTH; k++) begin
                fifo_r[k] <= 8'h00;
            end
            fifo_count_r <= '0;
        end else begin
            for (int k = 0; k < FIFO_DEPTH; k++) begin
                fifo_r[k] <= fifo_q[k];
            end
            fifo_count_r <= fifo_count_d;
        end
    end

    // =========================================================================
    // UART transmitter handshake
    //   - We assert valid_i for one cycle when UART not busy and FIFO has data.
    // =========================================================================
    logic       uart_busy;
    logic [7:0] uart_data_i;
    logic       uart_valid_i;

    assign uart_data_i  = (fifo_count_r != 0) ? fifo_r[0] : 8'h00;
    assign uart_valid_i = (fifo_count_r != 0) && !uart_busy;

    // Generate one-cycle fifo_pop when we successfully launched a byte
    assign fifo_pop = uart_valid_i; // uart will accept when !uart_busy

    uart_tx #(
        .CLK_HZ   (CLK_HZ),
        .BAUD     (UART_BAUD)
    ) u_uart_tx (
        .clk      (clk),
        .rst_n    (rst_n),
        .data_i   (uart_data_i),
        .valid_i  (uart_valid_i),
        .busy_o   (uart_busy),
        .tx_o     (uart_tx_o)
    );

    // =========================================================================
    // Debug
    // =========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dbg_last_sample_o <= '0;
        end else if (filt_valid) begin
            dbg_last_sample_o <= filt_data;
        end
    end

endmodule
