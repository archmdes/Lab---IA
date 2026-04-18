module cnn_dense_unit (
    input clk,
    input reset,
    
    // Dados vindo dos seus arquivos .mif e do Pooling
    input signed [7:0] data_in,    // Dado da Max-Pooling
  input signed [7:0] weight_in,  // Peso vindo da SRAM
  input signed [7:0] bias_in,    // Bias vindo da SRAM
    
    // Sinais de controle vindos da FSM da outra equipe
    input en_acc,                  // Habilita a acumulação (Multiplica e Soma)
    input en_bias,                 // Comando para somar o Bias ao final
    input clk_clear,               // Zera o acumulador para o próximo neurônio
    
    // Resultado para a FSM processar o ArgMax
    output reg signed [15:0] score_out
);

    reg signed [15:0] acc; // Acumulador de 16 bits para evitar overflow de 8x8

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            acc <= 16'd0;
            score_out <= 16'd0;
        end else begin
            if (clk_clear) begin
                acc <= 16'd0;
            end else if (en_acc) begin
                // Operação MAC: Acumulador = Acumulador + (Dado * Peso)
                acc <= acc + (data_in * weight_in);
            end else if (en_bias) begin
                // Soma final do Bias (ajustado para 16 bits)
                score_out <= acc + {{8{bias_in[7]}}, bias_in}; 
            end
        end
    end

endmodule
