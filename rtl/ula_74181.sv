`timescale 1ns/1ps

module ula_74181 (
    input  wire [3:0] a, b,
    input  wire [3:0] s,      // s = {S3,S2,S1,S0}
    input  wire       m,      // M = 1 -> Lógico; 0 -> Aritmético
    input  wire       c_in,   // Carry-in ≡ Cn
    output reg  [3:0] f,
    output wire       a_eq_b,
    output reg        c_out,  // Carry-out ≡ Cn+4
    output reg        c_ripple, // Carry-out verdadeiro (para ripple carry de 8 bits)
    output wire       p,      // Propagate (para carry look-ahead)
    output wire       g       // Generate (para carry look-ahead)
);

    // Comparador A = B (implementação correta)
    assign a_eq_b = (a == b);

    // Função auxiliar: soma aritmética conforme tabela do datasheet (M=0)
    function automatic [4:0] arith_sum;
        input [3:0] s_local;
        input [3:0] a_local, b_local;
        input       cin_local;
        reg   [4:0] acc;
        begin
            case (s_local)
                4'b0000: acc = {1'b0, a_local} + 5'b0_1111 + cin_local;                         // A - 1 / A
                4'b0001: acc = {1'b0, (a_local & b_local)} + 5'b0_1111 + cin_local;             // (A&B) - 1 / (A&B)
                4'b0010: acc = {1'b0, (a_local & ~b_local)} + 5'b0_1111 + cin_local;            // (A&~B) - 1 / (A&~B)
                4'b0011: acc = 5'b0_0000 + 5'b0_1111 + cin_local;                               // -1 / 0
                4'b0100: acc = {1'b0, a_local} + {1'b0, a_local} + {1'b0, ~b_local} + cin_local; // A + (A + ~B) [+1]
                4'b0101: acc = {1'b0, (a_local & b_local)} + {1'b0, a_local} + {1'b0, ~b_local} + cin_local; // (A&B) + (A + ~B) [+1]
                4'b0110: acc = {1'b0, a_local} + {1'b0, ~b_local} + cin_local;                   // A - B - 1 / A - B
                4'b0111: acc = {1'b0, a_local} + {1'b0, ~b_local} + cin_local;                   // A + ~B [+1]
                4'b1000: acc = {1'b0, a_local} + {1'b0, a_local} + {1'b0, b_local} + cin_local;  // A + (A + B) [+1]
                4'b1001: acc = {1'b0, a_local} + {1'b0, b_local} + cin_local;                    // A + B [+1]
                4'b1010: acc = {1'b0, (a_local & ~b_local)} + {1'b0, a_local} + {1'b0, b_local} + cin_local; // (A&~B) + (A + B) [+1]
                4'b1011: acc = {1'b0, a_local} + {1'b0, b_local} + cin_local;                    // A + B [+1]
                4'b1100: acc = {1'b0, a_local} + {1'b0, a_local} + cin_local;                    // A + A [+1]
                4'b1101: acc = {1'b0, (a_local & b_local)} + {1'b0, a_local} + cin_local;        // (A&B) + A [+1]
                4'b1110: acc = {1'b0, (a_local & ~b_local)} + {1'b0, a_local} + cin_local;       // (A&~B) + A [+1]
                4'b1111: acc = {1'b0, a_local} + 5'b0_0000 + cin_local;                          // A [+1]
                default: acc = 5'bx_xxxx;
            endcase
            arith_sum = acc;
        end
    endfunction

    // Pré-cálculo de P/G por carry verdadeiro (somente em M=0)
    wire [4:0] sum0 = arith_sum(s, a, b, 1'b0);
    wire [4:0] sum1 = arith_sum(s, a, b, 1'b1);
    assign g = (m == 1'b0) ? sum0[4] : 1'b1;            // G = Cout com Cin=0
    assign p = (m == 1'b0) ? (sum1[4] & ~sum0[4]) : 1'b0; // P tal que Cout = G | (P & Cin)

    // Registrador de 5 bits para soma aritmética
    reg [4:0] sum_arith;

    // Funções lógicas e aritméticas
    always @* begin
    if (m) begin
            // Modo lógico (m = 1) - `c_out` é sempre 0
            case (s)
                4'b0000: f = ~a;              // ~A
                4'b0001: f = ~(a & b);        // NAND
                4'b0010: f = (~a) | b;        // ~A + B
                4'b0011: f = 4'b1111;         // 1
                4'b0100: f = ~(a | b);        // NOR
                4'b0101: f = ~b;              // ~B
                4'b0110: f = ~(a ^ b);        // XNOR
                4'b0111: f = a | (~b);        // A + ~B
                4'b1000: f = (~a) & b;        // ~A & B
                4'b1001: f = a ^ b;           // XOR
                4'b1010: f = b;               // B
                4'b1011: f = a | b;           // OR
                4'b1100: f = 4'b0000;         // 0
                4'b1101: f = a | (~b);        // A + ~B
                4'b1110: f = a & b;           // AND
                4'b1111: f = a;               // A
            endcase
            c_out    = 1'b0;
            c_ripple = 1'b0;
        end else begin
            // Modo aritmético (m = 0) - Operações conforme datasheet SN74LS181
            case (s)
                4'b0000: sum_arith = arith_sum(s, a, b, c_in);
                4'b0001: sum_arith = arith_sum(s, a, b, c_in);
                4'b0010: sum_arith = arith_sum(s, a, b, c_in);
                4'b0011: sum_arith = arith_sum(s, a, b, c_in);
                4'b0100: sum_arith = arith_sum(s, a, b, c_in);
                4'b0101: sum_arith = arith_sum(s, a, b, c_in);
                4'b0110: sum_arith = arith_sum(s, a, b, c_in);
                4'b0111: sum_arith = arith_sum(s, a, b, c_in);
                4'b1000: sum_arith = arith_sum(s, a, b, c_in);
                4'b1001: sum_arith = arith_sum(s, a, b, c_in);
                4'b1010: sum_arith = arith_sum(s, a, b, c_in);
                4'b1011: sum_arith = arith_sum(s, a, b, c_in);
                4'b1100: sum_arith = arith_sum(s, a, b, c_in);
                4'b1101: sum_arith = arith_sum(s, a, b, c_in);
                4'b1110: sum_arith = arith_sum(s, a, b, c_in);
                4'b1111: sum_arith = arith_sum(s, a, b, c_in);
                default: sum_arith = 5'bx_xxxx;
            endcase

            f = sum_arith[3:0];
            // Carry-out conforme convenção da 74181:
            // Em algumas funções aritméticas (relacionadas a decremento/subtração), o Cn+4
            // é apresentado de forma complementada em relação ao carry da soma interna.
            // S = {0000, 0010, 0011, 0110, 0111, 1011} -> carry complementado.
            // Demais funções -> carry direto.
            unique case (s)
                4'b0000, // A - 1
                4'b0010, // (A & ~B) - 1
                4'b0011, // -1
                4'b0110, // A - B - 1 (A + ~B + Cin)
                4'b0111, // A + ~B (+1 com Cin=1) -> datasheet apresenta Cout complementado
                4'b1011: // (A + B) (+1 com Cin=1) com Cout apresentado complementado no ds
                    c_out = ~sum_arith[4];
                default:
                    c_out = sum_arith[4];
            endcase
            // Carry verdadeiro para ripple entre ULAs (sempre carry direto da soma aritmética)
            c_ripple = sum_arith[4];
        end
    end
endmodule