`timescale 1ns/1ps

module tb_conv_4_filters_relu;

    reg clk;
    reg rst;
    
    // Testbench Variables
    reg signed [7:0] stream_in;
    reg valid_in;
    
    // Outputs from the module
    wire signed [15:0] out_0, out_1, out_2, out_3;
    wire out_valid;

    // Arquivos
    reg [7:0] pixels_1024_vec [0:1023];
    integer out_4_filters_file;
    
    // Instanciando o módulo de convolução
    conv_4_filters_relu #(.IMG_WIDTH(32)) uut (
        .clk(clk), .rst(rst),
        .pixel_in(stream_in), .valid_in(valid_in),

        // --- Filtro 0 ---
        .f0_w00(8'h5A), .f0_w01(8'h14), .f0_w02(8'h11),
        .f0_w10(8'h20), .f0_w11(8'h0D), .f0_w12(8'hED),
        .f0_w20(8'hBE), .f0_w21(8'hBE), .f0_w22(8'hDF),
        .f0_bias(8'h08),

        // --- Filtro 1 ---
        .f1_w00(8'h14), .f1_w01(8'h0E), .f1_w02(8'hB8),
        .f1_w10(8'hFB), .f1_w11(8'h13), .f1_w12(8'hAA),
        .f1_w20(8'h39), .f1_w21(8'h26), .f1_w22(8'hE4),
        .f1_bias(8'h03),

        // --- Filtro 2 ---
        .f2_w00(8'hEE), .f2_w01(8'hB6), .f2_w02(8'hF1),
        .f2_w10(8'h04), .f2_w11(8'hD1), .f2_w12(8'h22),
        .f2_w20(8'h2A), .f2_w21(8'h06), .f2_w22(8'h42),
        .f2_bias(8'hFC),

        // --- Filtro 3 ---
        .f3_w00(8'hF8), .f3_w01(8'h07), .f3_w02(8'h1D),
        .f3_w10(8'hEA), .f3_w11(8'h1E), .f3_w12(8'h1D),
        .f3_w20(8'hF2), .f3_w21(8'h00), .f3_w22(8'h05),
        .f3_bias(8'hD8),

        // --- Saídas ---
        .out_f0(out_0), .out_f1(out_1), .out_f2(out_2), .out_f3(out_3),
        .valid_out(out_valid)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk; //clock de 100MHz
    end

    // Input Stimulus Block
    integer p;
    initial begin
        // Resetando registradores
        rst = 1;
        valid_in = 0;
        stream_in = 0;
        
        #20;
        rst = 0;
        #10;
        
        $display("====================================================");
        $display("   INICIANDO TESTE DA CONVOLUCAO (32x32)");
        $display("====================================================");

        //Inicializando o arquivo de saída
        out_4_filters_file = $fopen("convolucao/output_conv_real.txt", "w");

        // Carregando os dados da imagem no vetor
        $readmemh("convolucao/input_img.txt", pixels_1024_vec);

        //Alimentando a convolução com um pixel por vez
        for (p = 0; p < 1024; p = p + 1) begin
            @(posedge clk);
            valid_in <= 1'b1;
            stream_in <= pixels_1024_vec[p];
        end
        
        // Completando o ciclo
        for (p = 0; p < 2; p = p + 1) begin
            @(posedge clk);
            valid_in <= 1'b0; 
        end
        
        @(posedge clk);
        valid_in <= 1'b0; // Finalizando
        
        #100;
        $display("====================================================");
        $display("   SIMULACAO FINALIZADA");
        $display("====================================================");

        $fclose(out_4_filters_file);
        $stop;
    end
    
    // Salvando dados no arquivo de saída
    always @(posedge clk) begin
        if (out_valid) begin
            $fdisplay(out_4_filters_file, "%H %H %H %H", out_0, out_1, out_2, out_3);
        end
    end

endmodule