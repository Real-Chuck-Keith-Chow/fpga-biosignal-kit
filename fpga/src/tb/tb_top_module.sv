`timescale 1ns/1ps

module tb_top_module;

    logic clk = 1'b0;
    logic rst_n = 1'b0;

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

    always #10 clk = ~clk; // 50 MHz

    always_ff @(posedge adc_sclk_o or posedge adc_cs_n_o) begin
        if (adc_cs_n_o)
            adc_miso_i <= 1'b0;
        else
            adc_miso_i <= $urandom_range(0, 1);
    end

    initial begin
        $dumpfile("tb_top_module.vcd");
        $dumpvars(0, tb_top_module);

        repeat (10) @(posedge clk);
        rst_n = 1'b1;

        repeat (200_000) @(posedge clk);

        $display("Simulation complete");
        $finish;
    end

endmodule
