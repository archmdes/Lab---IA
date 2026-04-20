module rom_pesos_cnn #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 10,
    parameter MIF_FILE = "pesos.hex"
)(
    input clk,
    input [ADDR_WIDTH-1:0] addr,
    output reg signed [DATA_WIDTH-1:0] q
);

    reg [DATA_WIDTH-1:0] mem [0:(2**ADDR_WIDTH)-1];

    initial begin
        $readmemh(MIF_FILE, mem);
        #1;
        if (mem[0] === 8'shx) 
            $display("--- ERRO: Ficheiro %s nao encontrado ---", MIF_FILE);
        else 
            $display("--- SUCESSO: Pesos carregados de %s ---", MIF_FILE);
    end

    always @(posedge clk) begin
        q <= mem[addr];
    end
endmodule