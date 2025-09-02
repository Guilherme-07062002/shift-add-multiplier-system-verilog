/*
 * Módulo: counter
 * Descrição: Implementa um contador síncrono de N bits com reset assíncrono,
 *            carregamento paralelo, habilitação e controle de direção (up/down).
 *            Este módulo atende às especificações da Tarefa 03.
 */
module counter #(
    parameter N = 8
) (
    // --- Entradas ---
    input  logic clk,       // Clock do sistema
    input  logic rst,       // Reset assíncrono (ativo alto)
    input  logic load,      // Carregamento síncrono do valor de data_in
    input  logic en,        // Habilita a contagem
    input  logic up_down,   // Direção: 1 para incrementar (up), 0 para decrementar (down)
    input  logic [N-1:0] data_in, // Valor para carregamento paralelo

    // --- Saídas ---
    output logic [N-1:0] data_out, // Valor atual do contador
    output logic end_flag,         // Sinal de fim (equivalente ao requisito "end")
    // Porta adicional opcional com identificador escapado para corresponder ao nome do enunciado.
    // Pode ser ignorada em instâncias se não for necessária.
    output logic \end              // (escaped identifier) Indica fim da contagem (1 quando valor == 0)
);

    // Registrador interno que armazena o valor da contagem.
    logic [N-1:0] count_reg;

    // Lógica sequencial para o registrador do contador.
    // O bloco é sensível à borda de subida do clock e do reset.
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset assíncrono zera o contador.
            count_reg <= '0;
        end else begin
            if (load) begin
                // Carregamento paralelo tem prioridade.
                count_reg <= data_in;
            end else if (en) begin
                if (up_down) begin
                    // Contagem crescente (não usada neste projeto, mantida para completude)
                    count_reg <= count_reg + 1'b1;
                end else begin
                    // Contagem decrescente com saturação em zero para evitar wrap (atende melhor a ideia de fim fixo)
                    if (count_reg != {N{1'b0}})
                        count_reg <= count_reg - 1'b1;
                    else
                        count_reg <= count_reg; // mantém zero
                end
            end
        end
    end

    // Saídas combinacionais são atribuídas continuamente.
    assign data_out  = count_reg;
    assign end_flag  = (count_reg == {N{1'b0}}); // 'end_flag' é 1 se o contador for zero.
    assign \end      = end_flag;                 // Alias para o nome solicitado no enunciado.

endmodule