module Flat #(
    parameter DATA_WIDTH = 8,
    parameter CHANNELS = 4,
    parameter HEIGHT = 4,
    parameter WIDTH = 4
)(
    input wire clk,
    input wire rst,

    // Entrada (stream de dados do pooling)
    input wire [DATA_WIDTH-1:0] data_in,
    input wire valid_in,

    // Saída flatten
    output reg [DATA_WIDTH-1:0] data_out,
    output reg valid_out,

    // Controle
    output reg done
);

    localparam TOTAL_SIZE = CHANNELS * HEIGHT * WIDTH;

    reg [$clog2(TOTAL_SIZE):0] counter;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter   <= 0;
            valid_out <= 0;
            done      <= 0;
        end else begin
            if (valid_in) begin
                data_out  <= data_in;
                valid_out <= 1;

                if (counter == TOTAL_SIZE - 1) begin
                    counter <= 0;
                    done    <= 1;
                end else begin
                    counter <= counter + 1;
                    done    <= 0;
                end
            end else begin
                valid_out <= 0;
                done      <= 0;
            end
        end
    end

endmodule
