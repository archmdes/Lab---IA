`timescale 1ns/1ps

module Test_Flat;

    parameter DATA_WIDTH = 16;
    parameter CHANNELS = 4;
    parameter HEIGHT = 15;
    parameter WIDTH = 15;

    localparam integer LINES_IN_FILE = HEIGHT * WIDTH;
    localparam integer TOTAL_SIZE = CHANNELS * HEIGHT * WIDTH;

    reg clk;
    reg rst;

    reg [DATA_WIDTH-1:0] data_in;
    reg valid_in;

    wire [DATA_WIDTH-1:0] data_out;
    wire valid_out;
    wire done;

    integer infile;
    integer outfile;
    integer line_idx;
    integer count_out;

    reg [15:0] ch0;
    reg [15:0] ch1;
    reg [15:0] ch2;
    reg [15:0] ch3;

    task automatic send_word;
        input [DATA_WIDTH-1:0] value;
        begin
            @(negedge clk);
            data_in = value;
            valid_in = 1'b1;
        end
    endtask

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
    // Simulacao
    // =========================
    initial begin
        clk = 0;
        rst = 1;
        valid_in = 0;
        data_in = 0;
        count_out = 0;

        #20;
        rst = 0;

        infile  = $fopen("max_pooling/out_max_pooling_real.txt", "r");
        outfile = $fopen("serializacao/input_dense_real.txt", "w");

        if (infile == 0) begin
            $display("Erro ao abrir arquivo de entrada do flatten.");
            $finish;
        end

        if (outfile == 0) begin
            $display("Erro ao abrir arquivo de saida do flatten.");
            $finish;
        end

        // Cada linha tem 4 canais da mesma posicao espacial (row, col).
        // O stream enviado fica em ordem row-col-channel, compativel com NHWC flatten.
        for (line_idx = 0; line_idx < LINES_IN_FILE; line_idx = line_idx + 1) begin
            if ($fscanf(infile, "%h %h %h %h\n", ch0, ch1, ch2, ch3) != 4) begin
                $display("Erro de leitura no maxpool na linha %0d.", line_idx);
                $finish;
            end

            send_word(ch0);
            send_word(ch1);
            send_word(ch2);
            send_word(ch3);
        end

        @(negedge clk);
        valid_in = 1'b0;
        data_in = {DATA_WIDTH{1'b0}};

        repeat (4) @(posedge clk);

        $fclose(infile);
        $fclose(outfile);

        $display("\n===== FLATTEN FINALIZADO =====");
        $display("Total de elementos enviados: %0d", TOTAL_SIZE);
        $display("Total de elementos capturados: %0d\n", count_out);

        $stop;
    end

    // =========================
    // Monitoramento da saida
    // =========================
    always @(posedge clk) begin
        if (valid_out) begin
            $fwrite(outfile, "%04H\n", data_out);
            count_out <= count_out + 1;
        end

        if (done) begin
            $display("Pulse done detectado em count_out=%0d", count_out);
        end
    end

endmodule
