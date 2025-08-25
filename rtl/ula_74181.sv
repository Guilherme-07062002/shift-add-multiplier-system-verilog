/*
 * Módulo: ula_74181
 * Descrição: ULA de 4 bits baseada no CI 74181.
 *            Implementa operações lógicas e aritméticas.
 */
/*
 * Módulo: ula_74181
 * Descrição: ULA de 4 bits (simplificado para uso no projeto).
 *            Quando m==0 realiza soma de 4 bits com carry in/out.
 *            Quando m==1 realiza uma operação lógica simples (XOR) como fallback.
 * Observação: projetado para ser compatível com o wrapper `ula_8_bits.sv` que
 *             instancia duas cópias deste módulo e usa as portas (a,b,s,m,cin,f,cout).
 */
module ula_74181 (
    input  logic [3:0] a,
    input  logic [3:0] b,
    input  logic [3:0] s,
    input  logic       m,
    input  logic       cin,
    output logic [3:0] f,
    output logic       cout
);

    // For the multiplier we only need arithmetic mode (m==0). Implement a clean
    // 4-bit adder with carry out. For m==1 (logical mode) provide a simple XOR
    // as a safe fallback so the module is well-defined for all inputs.
    logic [4:0] sum;

    // Arithmetic calculation
    assign sum = {1'b0, a} + {1'b0, b} + (cin ? 1'b1 : 1'b0);
    
    // Output assignments based on mode
    assign f = (m == 1'b0) ? sum[3:0] : (a ^ b);
    assign cout = (m == 1'b0) ? sum[4] : 1'b0;

endmodule