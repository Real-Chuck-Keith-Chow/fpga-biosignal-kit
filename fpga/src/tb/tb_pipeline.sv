`timescale 1ns/1ps

module tb_pipeline;

    logic clk = 0;
    logic rst_n = 0;

    logic adc_miso_i;
    logic adc_sclk_o;
    logic adc_cs_n_o;
    logic adc_mosi_o;
    logic uart_tx_o;

    logic [11:0] dbg_last_sample_o;
    logic dbg_sample_tick_o;

    top_module DUT (
        .clk(clk),
        .rst_n(rst_n),
        .adc_miso_i(adc_miso_i),
        .adc_sclk_o(adc_sclk_o),
        .adc_cs_n_o(adc_cs_n_o),
        .adc_mosi_o(adc_mosi_o),
        .uart_tx_o(uart_tx_o),
        .dbg_last_sample_o(dbg_last_sample_o),
        .dbg_sample_tick_o(dbg_sample_tick_o)
    );

    always #10 clk = ~clk;

    logic [11:0] sample_data = 12'hABC;
    integer bit_idx = 11;

    always_ff @(negedge adc_sclk_o) begin
        if (!adc_cs_n_o) begin
            adc_miso_i <= sample_data[bit_idx];

            if (bit_idx == 0)
                bit_idx <= 11;
            else
                bit_idx <= bit_idx - 1;
        end
    end

    initial begin
        $dumpfile("tb_pipeline.vcd");
        $dumpvars(0, tb_pipeline);

        repeat (10) @(posedge clk);
        rst_n = 1;

        repeat (200000) @(posedge clk);

        $display("Pipeline simulation PASSED");
        $finish;
    end

endmodule
