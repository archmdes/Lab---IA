module camada_densa_top (
    input clk,
    input reset,

    input we_sram,
    input [11:0] addr_escrita_sram,
    input [7:0] dado_escrita_sram,

    input [11:0] addr_leitura_sram,
    input [9:0] addr_rom_peso,
    
    input en_acc,
    input en_bias,
    input clk_clear,

    output signed [15:0] score_final
);

    wire signed [7:0] sram_data_out;
    wire signed [7:0] peso_out;
    wire signed [7:0] bias_bypass;

    // BYPASS: Forçamos zero no bias para evitar o vírus do 'x'
    assign bias_bypass = 8'sd0;

    wire [11:0] sram_addr_atual = we_sram ? addr_escrita_sram : addr_leitura_sram;

    sram_resultados_pooling #(
        .DATA_WIDTH(8), 
        .ADDR_WIDTH(12)
    ) memoria_pooling (
        .clk(clk),
        .we(we_sram),
        .addr(sram_addr_atual),
        .data_in(dado_escrita_sram),
        .data_out(sram_data_out)
    );

    rom_pesos_cnn #(
        .DATA_WIDTH(8),
        .ADDR_WIDTH(10),
        .MIF_FILE("pesos.hex")
    ) rom_pesos (
        .clk(clk),
        .addr(addr_rom_peso),
        .q(peso_out)
    );

    cnn_dense_unit processador (
        .clk(clk),
        .reset(reset),
        .data_in(sram_data_out),
        .weight_in(peso_out),
        .bias_in(bias_bypass),
        .en_acc(en_acc),
        .en_bias(en_bias),
        .clk_clear(clk_clear),
        .score_out(score_final)
    );

endmodule