`timescale 1ns/1ps

module dense_900x1_sigmoid #(
    parameter integer INPUT_SIZE = 900
)(
    input wire clk,
    input wire rst,

    // Pairwise stream: serialized activation and its corresponding weight.
    input wire signed [15:0] x_in,    // Q2.14
    input wire signed [7:0] w_in,     // Q1.7
    input wire signed [7:0] bias_in,  // Q1.7
    input wire valid_in,

    // Single-neuron linear output.
    output reg signed [15:0] y_out,   // Q2.14
    output reg valid_out,
    output reg done
);

    localparam signed [47:0] SAT_MAX_Q2_14 = 48'sd32767;
    localparam signed [47:0] SAT_MIN_Q2_14 = -48'sd32768;

    reg [9:0] sample_count;
    reg signed [47:0] acc_q3_21;

    reg signed [23:0] product_q3_21;
    reg signed [47:0] full_sum_q3_21;
    reg signed [47:0] linear_q2_14;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sample_count <= 10'd0;
            acc_q3_21 <= 48'sd0;
            y_out <= 16'sd0;
            valid_out <= 1'b0;
            done <= 1'b0;
        end else begin
            valid_out <= 1'b0;
            done <= 1'b0;

            if (valid_in) begin
                product_q3_21 = $signed(x_in) * $signed(w_in);

                if (sample_count == INPUT_SIZE - 1) begin
                    full_sum_q3_21 = acc_q3_21
                        + $signed({{24{product_q3_21[23]}}, product_q3_21})
                        + $signed({{26{bias_in[7]}}, bias_in, 14'b0});

                    // Convert from Q3.21 to Q2.14.
                    linear_q2_14 = full_sum_q3_21 >>> 7;

                    if (linear_q2_14 > SAT_MAX_Q2_14) begin
                        y_out <= 16'sd32767;
                    end else if (linear_q2_14 < SAT_MIN_Q2_14) begin
                        y_out <= -16'sd32768;
                    end else begin
                        y_out <= linear_q2_14[15:0];
                    end
                    valid_out <= 1'b1;
                    done <= 1'b1;

                    sample_count <= 10'd0;
                    acc_q3_21 <= 48'sd0;
                end else begin
                    sample_count <= sample_count + 10'd1;
                    acc_q3_21 <= acc_q3_21 + $signed({{24{product_q3_21[23]}}, product_q3_21});
                end
            end
        end
    end

endmodule
