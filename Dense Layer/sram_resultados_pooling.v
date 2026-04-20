module sram_resultados_pooling #(
    parameter DATA_WIDTH = 16,        // Largura do dado fatiado
    parameter ADDR_WIDTH = 12         // Capacidade para armazenar todos os resultados
)(
    input clk,
    input we,                         // Write Enable: veam do Serializador
    input [ADDR_WIDTH-1:0] addr,      // Endereço gerado pelo contador
    input [DATA_WIDTH-1:0] data_in,   // Dado vindo do fatiamento do vetorzão
    output reg [DATA_WIDTH-1:0] data_out // Saída para a próxima camada da rede
);

    // Memória volátil (SRAM) - Não inicializada por arquivo
    reg [DATA_WIDTH-1:0] ram [0:(2**ADDR_WIDTH)-1];

    always @(posedge clk) begin
        if (we) begin
            ram[addr] <= data_in;     // Escrita: Salva o dado do Pooling
        end
        data_out <= ram[addr];         // Leitura: Para a próxima etapa (ex: Fully Connected)
    end

endmodule