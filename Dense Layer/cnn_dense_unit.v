module cnn_dense_unit (
    input clk,
    input reset,
    input signed [7:0] data_in,
    input signed [7:0] weight_in,
    input signed [7:0] bias_in,
    input en_acc,
    input en_bias,
    input clk_clear,
    output reg signed [15:0] score_out
);

    reg signed [15:0] acc;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            acc <= 16'sd0;
            score_out <= 16'sd0;
        end else begin
            if (clk_clear) begin
                acc <= 16'sd0;
            end else if (en_acc) begin
                // Operação MAC: Acumulador = Acc + (Dado * Peso)
                acc <= acc + (data_in * weight_in);
            end else if (en_bias) begin
                // Soma o bias (com extensão de sinal) ao total acumulado
                score_out <= acc + {{8{bias_in[7]}}, bias_in};
            end
        end
    end
endmodule