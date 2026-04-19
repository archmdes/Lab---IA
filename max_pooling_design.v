module max_pooling (
    input  [255:0] vector_4x4,   // ebtrada de 16 pixels de 16 bits cada
    output [63:0] y_out         // saidad de 4 pixels de 16 bits cada
);

    // função de pooling de fato
    function [15:0] pooling;
        input [15:0] a,b,c,d;
        reg [15:0] m1,m2;
        begin
            m1 = (a>b)?a:b;
            m2 = (c>d)?c:d;
            pooling = (m1>m2)?m1:m2;
        end
    endfunction

    genvar i,j; // variaveis de controle para o loop

    generate // loop das janelas 2x2 (já com saida)
        for (i=0; i<2; i=i+1) begin : LINHAS
            for (j=0; j<2; j=j+1) begin : COLUNAS

                localparam integer id = i*2 + j;

                assign y_out[(id+1)*16-1 -: 16] =
                    pooling(
                        vector_4x4[((i*2)*4 + (j*2) +1)*16-1 -: 16],
                        vector_4x4[((i*2)*4 + (j*2 +1) +1)*16-1 -: 16],
                        vector_4x4[((i*2 +1)*4 + (j*2)+1)*16-1 -: 16],
                        vector_4x4[((i*2 +1)*4 + (j*2+1)+1)*16-1 -: 16]
                    );

            end
        end
    endgenerate

endmodule