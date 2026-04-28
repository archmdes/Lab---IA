module flatten #(
    parameter DATA_WIDTH = 16,
    parameter CHANNELS = 4,
    parameter HEIGHT = 15,
    parameter WIDTH = 15
)(
    input wire clk,
    input wire rst,

    // Input data stream
    input wire [DATA_WIDTH-1:0] data_in,
    input wire valid_in,

    // Flatten output stream
    output reg [DATA_WIDTH-1:0] data_out,
    output reg valid_out,

    // Pulses high for one cycle on the final flattened element
    output reg done
);

    localparam integer TOTAL_SIZE = CHANNELS * HEIGHT * WIDTH;
    localparam integer COUNTER_WIDTH = (TOTAL_SIZE > 1) ? $clog2(TOTAL_SIZE) : 1;

    reg [COUNTER_WIDTH-1:0] counter;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter   <= {COUNTER_WIDTH{1'b0}};
            data_out  <= {DATA_WIDTH{1'b0}};
            valid_out <= 1'b0;
            done      <= 1'b0;
        end else begin
            done <= 1'b0;

            if (valid_in) begin
                data_out  <= data_in;
                valid_out <= 1'b1;

                if (counter == TOTAL_SIZE - 1) begin
                    counter <= {COUNTER_WIDTH{1'b0}};
                    done    <= 1'b1;
                end else begin
                    counter <= counter + 1'b1;
                end
            end else begin
                valid_out <= 1'b0;
            end
        end
    end

endmodule

// Backward-compatible wrapper preserving legacy module name.
module Flat #(
    parameter DATA_WIDTH = 16,
    parameter CHANNELS = 4,
    parameter HEIGHT = 15,
    parameter WIDTH = 15
)(
    input wire clk,
    input wire rst,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire valid_in,
    output wire [DATA_WIDTH-1:0] data_out,
    output wire valid_out,
    output wire done
);
    flatten #(
        .DATA_WIDTH(DATA_WIDTH),
        .CHANNELS(CHANNELS),
        .HEIGHT(HEIGHT),
        .WIDTH(WIDTH)
    ) u_flatten (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .valid_in(valid_in),
        .data_out(data_out),
        .valid_out(valid_out),
        .done(done)
    );
endmodule
