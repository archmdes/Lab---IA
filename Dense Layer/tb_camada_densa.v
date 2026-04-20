`timescale 1ns/1ps

module tb_camada_densa;
    parameter TOTAL_LINHAS = 502; 

    reg clk, reset, we_sram, en_acc, en_bias, clk_clear;
    reg [11:0] addr_escrita, addr_leitura;
    reg [9:0] addr_peso;
    reg [7:0] reg_dado_sram;
    wire signed [15:0] score_final;
    
    reg [7:0] buffer_dados [0:TOTAL_LINHAS-1];
    integer i, j, f; // 'f' é o manipulador do arquivo .txt

    // Instância do seu Módulo Top (Garanta que o arquivo camada_densa_top.v esteja limpo)
    camada_densa_top uut (
        .clk(clk), .reset(reset), .we_sram(we_sram),
        .addr_escrita_sram(addr_escrita), .dado_escrita_sram(reg_dado_sram),
        .addr_leitura_sram(addr_leitura), .addr_rom_peso(addr_peso),
        .en_acc(en_acc), .en_bias(en_bias), .clk_clear(clk_clear),
        .score_final(score_final)
    );

    // Geração do Clock (Período de 10ns)
    always #5 clk = ~clk;

    initial begin
        // Abre o arquivo para escrita
        f = $fopen("saida_final.txt", "w");
        
        // Carrega o dataset do pooling
        $readmemh("dados_limpos.hex", buffer_dados);

        // --- Inicialização e Reset ---
        clk = 0; reset = 1; we_sram = 0; en_acc = 0; en_bias = 0; clk_clear = 0;
        #20 reset = 0;

        // --- FASE 1: Gravação na SRAM (Usa borda de descida para evitar erros) ---
        for (i = 0; i < TOTAL_LINHAS; i = i + 1) begin
            @(negedge clk);
            we_sram = 1; 
            addr_escrita = i; 
            reg_dado_sram = buffer_dados[i];
        end
        @(negedge clk) we_sram = 0;

        // --- FASE 2: Processamento e Log Detalhado ---
        @(negedge clk) clk_clear = 1; 
        @(negedge clk) clk_clear = 0;

        $fdisplay(f, "--- INICIO DO CALCULO DO NEURONIO ---");
        $fdisplay(f, "Tempo (ps) | Endereco | Dado (hex) | Peso (hex) | Acumulador");

        for (j = 0; j < TOTAL_LINHAS; j = j + 1) begin
            @(negedge clk);
            addr_leitura = j; 
            addr_peso = j;
            
            @(negedge clk); // Espera a latência da memória (Sincronia)
            
            en_acc = 1; // Habilita a conta
            
            // Grava no arquivo .txt o estado atual
            $fdisplay(f, "%10t | %8d | %10h | %10h | %d", 
                      $time, j, uut.sram_data_out, uut.peso_out, uut.processador.acc);
            
            @(negedge clk) en_acc = 0;
        end

        // --- FASE 3: Bias e Finalização ---
        @(negedge clk) en_bias = 1;
        @(negedge clk);
        en_bias = 0;

        #20;
        // Registro do Score Final
        $fdisplay(f, "--------------------------------------------------");
        $fdisplay(f, "SCORE FINAL APOS BIAS: %d", score_final);
        $fdisplay(f, "--------------------------------------------------");
        
        $display("Simulacao concluida. Verifique o arquivo 'saida_final.txt'.");
        
        $fclose(f); // Fecha o arquivo com segurança
        $finish;
    end
endmodule