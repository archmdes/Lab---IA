module max_pooling (
    input  signed [15:0] p00,
    input  signed [15:0] p01,
    input  signed [15:0] p10,
    input  signed [15:0] p11,
    output signed [15:0] y_out
);

    // Bloco combinacional de maxpool 2x2.
    function signed [15:0] pooling;
        input signed [15:0] a, b, c, d;
        reg signed [15:0] m1, m2;
        begin
            m1 = (a > b) ? a : b;
            m2 = (c > d) ? c : d;
            pooling = (m1 > m2) ? m1 : m2;
        end
    endfunction

    assign y_out = pooling(p00, p01, p10, p11);

endmodule