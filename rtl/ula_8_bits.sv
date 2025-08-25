/*
 * Módulo: ula_8_bits
 * Descrição: ULA de 8 bits que utiliza duas ULAs de 4 bits (ula_74181).
 *            Fornece a operação de soma necessária para o multiplicador.
 */
module ula_8_bits (
    input  logic [7:0] a, b,
    input  logic [3:0] s,
    input  logic       m,
    input  logic       cin,
    output logic [7:0] f,
    output logic       cout
);

    logic c4; // Carry out do primeiro estágio

    // Instância da ULA para os 4 bits menos significativos
    ula_74181 ula_low (
        .a(a[3:0]), .b(b[3:0]),
        .s(s), .m(m), .cin(cin),
        .f(f[3:0]), .cout(c4)
    );

    // Instância da ULA para os 4 bits mais significativos
    ula_74181 ula_high (
        .a(a[7:4]), .b(b[7:4]),
        .s(s), .m(m), .cin(c4),
        .f(f[7:4]), .cout(cout)
    );

endmodule