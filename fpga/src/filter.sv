`timescale 1ns/1ps

module filter #(
    parameter int unsigned WIDTH = 12
)(
    input  logic             clk,
    input  logic             rst_n,
    input  logic [WIDTH-1:0] data_i,
    input  logic             valid_i,

    output logic [WIDTH-1:0] data_o,
    output logic             valid_o
);

    logic [WIDTH-1:0] prev_q;
    logic [WIDTH:0]   sum;

    assign sum = {1'b0, data_i} + {1'b0, prev_q};

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_q  <= '0;
            data_o  <= '0;
            valid_o <= 1'b0;
        end else begin
            valid_o <= 1'b0;

            if (valid_i) begin
                data_o  <= sum[WIDTH:1];
                prev_q  <= data_i;
                valid_o <= 1'b1;
            end
        end
    end

endmodule
