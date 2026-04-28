`timescale 1ns/1ps

module tb_dense_900x1_sigmoid;

    localparam integer INPUT_SIZE = 900;

    reg clk;
    reg rst;
    reg signed [15:0] x_in;
    reg signed [7:0] w_in;
    reg signed [7:0] bias_in;
    reg valid_in;

    wire signed [15:0] y_out;
    wire valid_out;
    wire done;

    reg signed [15:0] x_mem [0:INPUT_SIZE-1];
    // Um unico TXT com 901 linhas em Q1.7:
    // [0..899] = pesos, [900] = vies.
    reg signed [7:0] dense_params_q1_7 [0:INPUT_SIZE];

    integer out_hex_file;
    integer i;
    integer wait_cycles;

    task automatic send_pair;
        input signed [15:0] x_value;
        input signed [7:0] w_value;
        begin
            @(negedge clk);
            valid_in = 1'b1;
            x_in = x_value;
            w_in = w_value;
        end
    endtask

    dense_900x1_sigmoid #(
        .INPUT_SIZE(INPUT_SIZE)
    ) uut (
        .clk(clk),
        .rst(rst),
        .x_in(x_in),
        .w_in(w_in),
        .bias_in(bias_in),
        .valid_in(valid_in),
        .y_out(y_out),
        .valid_out(valid_out),
        .done(done)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst = 1'b1;
        valid_in = 1'b0;
        x_in = 16'sd0;
        w_in = 8'sd0;
        bias_in = 8'sd0;

        #20;
        rst = 1'b0;

        $readmemh("serializacao/input_dense_real.txt", x_mem);
        $readmemh("camada_densa/dense_params_q1_7.txt", dense_params_q1_7);

        bias_in = dense_params_q1_7[INPUT_SIZE];

        out_hex_file = $fopen("camada_densa/output_dense_real.txt", "w");

        if (out_hex_file == 0) begin
            $display("Erro ao abrir arquivo de saida HEX da dense.");
            $finish;
        end

        for (i = 0; i < INPUT_SIZE; i = i + 1) begin
            send_pair(x_mem[i], dense_params_q1_7[i]);
        end

        @(negedge clk);
        valid_in = 1'b0;
        x_in = 16'sd0;
        w_in = 8'sd0;

        wait_cycles = 0;
        while ((done !== 1'b1) && (wait_cycles < 64)) begin
            @(posedge clk);
            wait_cycles = wait_cycles + 1;
        end

        if (done !== 1'b1) begin
            $display("Timeout: a dense nao sinalizou done.");
        end

        repeat (4) @(posedge clk);

        $fclose(out_hex_file);

        $display("===== DENSE FINALIZADA =====");
        $stop;
    end

    always @(posedge clk) begin
        if (valid_out) begin
            $fwrite(out_hex_file, "%04X\n", y_out[15:0]);
            $display("Dense output (Q2.14) = %04X", y_out[15:0]);
        end
    end

endmodule
