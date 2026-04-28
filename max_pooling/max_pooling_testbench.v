module testbench_pooling;

    reg signed [15:0] p00_1, p01_1, p10_1, p11_1;
    reg signed [15:0] p00_2, p01_2, p10_2, p11_2;
    reg signed [15:0] p00_3, p01_3, p10_3, p11_3;
    reg signed [15:0] p00_4, p01_4, p10_4, p11_4;

    wire signed [15:0] Y1, Y2, Y3, Y4;
    // vetores de entrada
    reg signed [15:0] COL1 [0:899];
    reg signed [15:0] COL2 [0:899];
    reg signed [15:0] COL3 [0:899];
    reg signed [15:0] COL4 [0:899];

    integer infile, outfile;
    integer i, row_out, col_out, base_idx;

    max_pooling U1 (.p00(p00_1), .p01(p01_1), .p10(p10_1), .p11(p11_1), .y_out(Y1));
    max_pooling U2 (.p00(p00_2), .p01(p01_2), .p10(p10_2), .p11(p11_2), .y_out(Y2));
    max_pooling U3 (.p00(p00_3), .p01(p01_3), .p10(p10_3), .p11(p11_3), .y_out(Y3));
    max_pooling U4 (.p00(p00_4), .p01(p01_4), .p10(p10_4), .p11(p11_4), .y_out(Y4));

    initial begin
        // abertura dos arquivos txt de entrada de saida
        infile  = $fopen("convolucao/output_conv_real.txt","r");
        outfile = $fopen("max_pooling/out_max_pooling_real.txt","w");

        if (infile == 0) begin
            $display("Erro ao abrir arquivo de entrada.");
            $finish;
        end

        if (outfile == 0) begin
            $display("Erro ao abrir arquivo de saida.");
            $finish;
        end

        // leitura do txt e associação dos valores as suas colunas
        for (i=0; i<900; i=i+1) begin
            if ($fscanf(infile,"%h %h %h %h\n",
                COL1[i], COL2[i], COL3[i], COL4[i]) != 4) begin
                $display("Erro de leitura na linha %0d.", i);
                $finish;
            end
        end

        #10; // atraso para dar tempo para o processo de leitura

        // Processa as 4 colunas como matrizes 30x30 em ordem raster.
        // Cada saida pooled usa uma janela 2x2 com stride 2, gerando 15x15 linhas.
        for (row_out=0; row_out<15; row_out=row_out+1) begin
            for (col_out=0; col_out<15; col_out=col_out+1) begin
                base_idx = (row_out*2)*30 + (col_out*2);

                p00_1 = COL1[base_idx];
                p01_1 = COL1[base_idx + 1];
                p10_1 = COL1[base_idx + 30];
                p11_1 = COL1[base_idx + 31];

                p00_2 = COL2[base_idx];
                p01_2 = COL2[base_idx + 1];
                p10_2 = COL2[base_idx + 30];
                p11_2 = COL2[base_idx + 31];

                p00_3 = COL3[base_idx];
                p01_3 = COL3[base_idx + 1];
                p10_3 = COL3[base_idx + 30];
                p11_3 = COL3[base_idx + 31];

                p00_4 = COL4[base_idx];
                p01_4 = COL4[base_idx + 1];
                p10_4 = COL4[base_idx + 30];
                p11_4 = COL4[base_idx + 31];

                #1;

                $fwrite(outfile,"%h %h %h %h\n", Y1, Y2, Y3, Y4);
            end
        end

        $fclose(infile);
        $fclose(outfile);
        $stop;
    end

endmodule