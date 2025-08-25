module ula_8_bits (
    input [7:0] a,
    input [7:0] b,
    input [3:0] s,
    input       m,
    input       c_in,
    output wire [7:0] f,
    output wire       a_eq_b,
    output wire       c_out,
    output wire       overflow,  // Sinal de overflow para aritmética de complemento a dois
    output wire       p,         // Propagação de carry para toda a ULA de 8 bits
    output wire       g,         // Geração de carry para toda a ULA de 8 bits
    output wire       c_intermediate // Carry entre as ULAs de 4 bits (para depuração)
);

    // Sinais internos para cascateamento das ULAs de 4 bits
    wire [3:0] f_lsb; // Saída da ULA dos 4 bits menos significativos
    // c_intermediate já foi declarado como porta de saída
    wire       a_eq_b_lsb; // A=B da ULA dos 4 bits menos significativos

    wire [3:0] f_msb; // Saída da ULA dos 4 bits mais significativos
    wire       c_out_msb; // Carry Out da ULA dos 4 bits mais significativos (não usado)
    wire       a_eq_b_msb; // A=B da ULA dos 4 bits mais significativos

    // Sinais para carry look-ahead (P e G)
    wire p_lsb, g_lsb, p_msb, g_msb;

    // Instanciação da ULA para os 4 bits menos significativos (LSB)
    ula_74181 ula_lsb (
        .a(a[3:0]),
        .b(b[3:0]),
        .s(s),
        .m(m),
        .c_in(c_in),
        .f(f_lsb),
        .a_eq_b(a_eq_b_lsb),
        .c_out(),    // c_out (datasheet) não usado para ripple
        .c_ripple(c_intermediate), // carry verdadeiro entre ULAs
        .p(p_lsb),
        .g(g_lsb)
    );

    // Conexão direta do carry_out da ULA LSB para o c_in da ULA MSB (ripple carry)
    
    // Instanciação da ULA para os 4 bits mais significativos (MSB)
    // Usando ripple carry (conexão direta do c_out do LSB ao c_in do MSB)
    ula_74181 ula_msb (
        .a(a[7:4]),
        .b(b[7:4]),
        .s(s),
        .m(m),
        .c_in(c_intermediate), // ripple carry verdadeiro
        .f(f_msb),
        .a_eq_b(a_eq_b_msb),
        .c_out(c_out),    // O carry_out do MSB é o carry_out final
        .c_ripple(),
        .p(p_msb),
        .g(g_msb)
    );

    // Conectando as saídas dos módulos de 4 bits para formar a saída de 8 bits
    assign f = {f_msb, f_lsb}; // Concatenação das saídas

    // A saída a_eq_b para 8 bits é ativa se ambos os módulos de 4 bits indicarem igualdade
    // Garantimos que seja a AND entre os dois sinais conforme solicitado
    assign a_eq_b = a_eq_b_lsb & a_eq_b_msb;
    
    // Detecção de overflow para aritmética em complemento a dois
    // Overflow ocorre quando o resultado tem sinal diferente do esperado
    // Isto é, quando os sinais dos operandos são iguais mas o sinal do resultado é diferente (para adição)
    // ou quando os sinais dos operandos são diferentes e o sinal do resultado é igual ao subtraendo (para subtração)
    
    wire is_add, is_sub;
    
    // Identificamos as operações de adição (S=1001) e subtração (S=0110)
    assign is_add = (m == 1'b0) && (s == 4'b1001);
    assign is_sub = (m == 1'b0) && (s == 4'b0110);
    
    // Para adição: overflow quando os sinais dos operandos são iguais e diferentes do resultado
    wire add_overflow = is_add && (a[7] == b[7]) && (a[7] != f[7]);
    
    // Para subtração: overflow quando os sinais dos operandos são diferentes e o resultado tem o mesmo sinal do subtraendo
    wire sub_overflow = is_sub && (a[7] != b[7]) && (f[7] == b[7]);
    
    // Overflow ocorre apenas em adição ou subtração
    assign overflow = (m == 1'b0) ? (add_overflow || sub_overflow) : 1'b0;

    // O carry out final já está conectado diretamente na instanciação da ULA MSB
    // Não é necessário fazer um assign adicional pois já foi feito na instanciação
    
    // Para os sinais de carry look-ahead P e G para a ULA de 8 bits completa
    // P para 8 bits é ativo se ambos P dos 4 bits estiverem ativos
    assign p = p_lsb & p_msb;
    
    // G para 8 bits - considera o cascateamento do carry
    // G8 = G_msb + (P_msb & G_lsb)
    assign g = g_msb | (p_msb & g_lsb);

endmodule