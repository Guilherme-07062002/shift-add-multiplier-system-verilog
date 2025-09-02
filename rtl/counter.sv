// Contador síncrono parametrizável.
module counter #(
    parameter N = 8
) (
    input  logic clk,       // Clock do sistema
    input  logic rst,       // Reset assíncrono (ativo alto)
    input  logic load,      // Carregamento síncrono do valor de data_in
    input  logic en,        // Habilita a contagem
    input  logic up_down,   // Direção: 1 para incrementar (up), 0 para decrementar (down)
    input  logic [N-1:0] data_in, // Valor para carregamento paralelo
    output logic [N-1:0] data_out, // Valor atual do contador
    output logic end_flag,         // Sinal de fim (equivalente ao requisito "end")
    output logic \end              // (escaped identifier) Indica fim da contagem (1 quando valor == 0)
);

    logic [N-1:0] count_reg;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            count_reg <= '0;
        end else begin
            if (load) begin
                count_reg <= data_in;
            end else if (en) begin
                if (up_down) begin
                    count_reg <= count_reg + 1'b1;
                end else begin
                    if (count_reg != {N{1'b0}})
                        count_reg <= count_reg - 1'b1;
                    else
                        count_reg <= count_reg; // zero
                end
            end
        end
    end

    assign data_out  = count_reg;
    assign end_flag  = (count_reg == {N{1'b0}});
    assign \end      = end_flag;

endmodule