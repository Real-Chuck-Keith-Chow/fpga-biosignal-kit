`timescale 1ns/1ps

module tb_top_module;

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

    initial begin
        $dumpfile("tb_top_module.vcd");
        $dumpvars(0, tb_top_module);

        rst_n = 0;
        adc_miso_i = 0;
        #200;
        rst_n = 1;

        repeat (5000) begin
            adc_miso_i = $random;
            #20;
        end

        #2000;
        $display("Simulation complete");
        $finish;
    end

endmodule
