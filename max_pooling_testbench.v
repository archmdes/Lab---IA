module testbench_pooling;

    reg  [255:0] V1, V2, V3, V4;
    wire [63:0] Y1, Y2, Y3, Y4;
    // vetores de entrada
    reg [15:0] COL1 [0:899];
    reg [15:0] COL2 [0:899];
    reg [15:0] COL3 [0:899];
    reg [15:0] COL4 [0:899];

    integer infile, outfile;
    integer i, b, k, idx;

    reg [255:0] temp1, temp2, temp3, temp4;

    max_pooling U1 (.vector_4x4(V1), .y_out(Y1));
    max_pooling U2 (.vector_4x4(V2), .y_out(Y2));
    max_pooling U3 (.vector_4x4(V3), .y_out(Y3));
    max_pooling U4 (.vector_4x4(V4), .y_out(Y4));

    initial begin
        // abertura dos arquivos txt de entrada de saida
        infile  = $fopen("out_4_filters.txt","r");
        outfile = $fopen("out_max_pooling.txt","w");

        if (infile == 0) begin
            $stop;
        end

        // leitura do txt e associação dos valores as suas colunas
        for (i=0; i<900; i=i+1) begin
            if ($fscanf(infile,"%h %h %h %h\n",
                COL1[i], COL2[i], COL3[i], COL4[i]) != 4) begin
                $stop;
            end
        end

        #10; // atraso para dar tempo para o processo de leitura

        // processamento
        for (b=0; b<56; b=b+1) begin

            for (idx=0; idx<16; idx=idx+1) begin
                temp1[(idx+1)*16-1 -: 16] = COL1[b*16 + idx];
                temp2[(idx+1)*16-1 -: 16] = COL2[b*16 + idx];
                temp3[(idx+1)*16-1 -: 16] = COL3[b*16 + idx];
                temp4[(idx+1)*16-1 -: 16] = COL4[b*16 + idx];
            end

            V1 = temp1;
            V2 = temp2;
            V3 = temp3;
            V4 = temp4;

            #10; 

            // escreve as 4 colunas de saida (4 de 16 bits cada)
            for (k=0; k<4; k=k+1) begin
                $fwrite(outfile,"%h %h %h %h\n",
                    Y1[(k+1)*16-1 -: 16],
                    Y2[(k+1)*16-1 -: 16],
                    Y3[(k+1)*16-1 -: 16],
                    Y4[(k+1)*16-1 -: 16]);
            end

        end

        $fclose(infile);
        $fclose(outfile);
        $stop;
    end

endmodule