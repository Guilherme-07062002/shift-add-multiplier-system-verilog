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
    output logic end_count         // Indica que o contador chegou a zero (ativo alto)
);

    // Registrador interno que armazena o valor da contagem.
    logic [N-1:0] count_reg;

    // Lógica sequencial para o registrador do contador.
    // O bloco é sensível à borda de subida do clock e do reset.
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // O reset assíncrono tem a maior prioridade e zera o contador.
            count_reg <= '0;
        end else begin
            if (load) begin
                // O carregamento síncrono tem prioridade sobre a contagem.
                count_reg <= data_in;
            end else if (en) begin
                // A contagem só ocorre se 'en' estiver ativo.
                count_reg <= up_down ? (count_reg + 1) : (count_reg - 1);
            end
            // Se 'load' e 'en' estiverem inativos, o valor é mantido (hold).
        end
    end

    // Saídas combinacionais são atribuídas continuamente.
    assign data_out = count_reg;
    // Use um literal de tamanho para comparação segura
    assign end_count = (count_reg == {N{1'b0}}); // 'end_count' é 1 se o contador for zero.

endmodule