`timescale 1ns/1ps

module Test_Flat;

    parameter DATA_WIDTH = 8;
    parameter CHANNELS = 4;
    parameter HEIGHT = 4;
    parameter WIDTH = 4;

    reg clk;
    reg rst;

    reg [DATA_WIDTH-1:0] data_in;
    reg valid_in;

    wire [DATA_WIDTH-1:0] data_out;
    wire valid_out;
    wire done;

    // =========================
    // Instancia o Flatten
    // =========================
    flatten #(
        .DATA_WIDTH(DATA_WIDTH),
        .CHANNELS(CHANNELS),
        .HEIGHT(HEIGHT),
        .WIDTH(WIDTH)
    ) uut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .valid_in(valid_in),
        .data_out(data_out),
        .valid_out(valid_out),
        .done(done)
    );

    // =========================
    // Clock (10ns)
    // =========================
    always #5 clk = ~clk;

    // =========================
    // Matriz 3D
    // =========================
    integer c, h, w;
    reg [7:0] matriz [0:CHANNELS-1][0:HEIGHT-1][0:WIDTH-1];

    // =========================
    // Simulação
    // =========================
    initial begin
        clk = 0;
        rst = 1;
        valid_in = 0;
        data_in = 0;

        #20;
        rst = 0;

        // =========================
        // Preenchendo matriz
        // =========================
        for (c = 0; c < CHANNELS; c = c + 1) begin
            for (h = 0; h < HEIGHT; h = h + 1) begin
                for (w = 0; w < WIDTH; w = w + 1) begin
                    matriz[c][h][w] = c*16 + h*4 + w;
                end
            end
        end

        // =========================
        // PRINT DA MATRIZ
        // =========================
        $display("\n===== MATRIZ ORIGINAL =====");

        for (c = 0; c < CHANNELS; c = c + 1) begin
            $display("\nCanal %0d:", c);
            for (h = 0; h < HEIGHT; h = h + 1) begin
                $write("[ ");
                for (w = 0; w < WIDTH; w = w + 1) begin
                    $write("%02h ", matriz[c][h][w]);
                end
                $write("]\n");
            end
        end

        // =========================
        // ENVIO DOS DADOS
        // =========================
        $display("\n===== ENVIANDO DADOS =====");

        for (c = 0; c < CHANNELS; c = c + 1) begin
            for (h = 0; h < HEIGHT; h = h + 1) begin
                for (w = 0; w < WIDTH; w = w + 1) begin
                    @(posedge clk);
                    data_in  <= matriz[c][h][w];
                    valid_in <= 1;

                    $display("Enviado -> C:%0d H:%0d W:%0d | Valor: %02h",
                              c, h, w, matriz[c][h][w]);
                end
            end
        end

        // Finaliza envio
        @(posedge clk);
        valid_in <= 0;

        #100;
        $stop;
    end

    // =========================
    // MONITORAMENTO DA SAÍDA
    // =========================
    integer count_out = 0;

    always @(posedge clk) begin
        if (valid_out) begin
            $display(">>> FLATTEN[%0d] = %02h", count_out, data_out);
            count_out = count_out + 1;
        end

        if (done) begin
            $display("\n===== FLATTEN FINALIZADO =====");
            $display("Total de elementos: %0d\n", count_out);
        end
    end

endmodule
