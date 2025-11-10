`timescale 1ns/1ps

module filter #(
    parameter int unsigned WIDTH = 12
)(
    input  logic clk,
    input  logic rst_n,
    input  logic [WIDTH-1:0] data_i,
    input  logic valid_i,
    output logic [WIDTH-1:0] data_o,
    output logic valid_o
);

    logic [WIDTH-1:0] prev_q, prev_d;
    logic [WIDTH-1:0] filt_q, filt_d;
    logic valid_d, valid_q;

    always_comb begin
        filt_d  = filt_q;
        prev_d  = prev_q;
        valid_d = 1'b0;

        if (valid_i) begin
            filt_d  = (data_i + prev_q) >> 1;
            prev_d  = data_i;
            valid_d = 1'b1;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_q  <= '0;
            filt_q  <= '0;
            valid_q <= 1'b0;
        end else begin
            prev_q  <= prev_d;
            filt_q  <= filt_d;
            valid_q <= valid_d;
        end
    end

    assign data_o  = filt_q;
    assign valid_o = valid_q;

endmodule
