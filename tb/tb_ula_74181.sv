`timescale 1ns/1ps

module tb_ula_74181;

    // Sinais de entrada
    reg [3:0] a, b, s;
    reg m, c_in;
    
    // Sinais de saída
    wire [3:0] f;
    wire a_eq_b, c_out, p, g;
    
    // Instanciação da ULA
    ula_74181 uut (
        .a(a),
        .b(b),
        .s(s),
        .m(m),
        .c_in(c_in),
        .f(f),
        .a_eq_b(a_eq_b),
        .c_out(c_out),
        .p(p),
        .g(g)
    );

    // Referência/esperados
    reg [3:0] expected_f;
    reg expected_cout, expected_p, expected_g, expected_eq;
    reg test_pass;
    integer errors, total_tests;

    function [3:0] calculate_expected_f_logic;
        input [3:0] s, a, b;
        begin
            case(s)
                4'b0000: calculate_expected_f_logic = ~a;
                4'b0001: calculate_expected_f_logic = ~(a & b);
                4'b0010: calculate_expected_f_logic = (~a) | b;
                4'b0011: calculate_expected_f_logic = 4'b1111;
                4'b0100: calculate_expected_f_logic = ~(a | b);
                4'b0101: calculate_expected_f_logic = ~b;
                4'b0110: calculate_expected_f_logic = ~(a ^ b);
                4'b0111: calculate_expected_f_logic = a | (~b);
                4'b1000: calculate_expected_f_logic = (~a) & b;
                4'b1001: calculate_expected_f_logic = a ^ b;
                4'b1010: calculate_expected_f_logic = b;
                4'b1011: calculate_expected_f_logic = a | b;
                4'b1100: calculate_expected_f_logic = 4'b0000;
                4'b1101: calculate_expected_f_logic = a | (~b);
                4'b1110: calculate_expected_f_logic = a & b;
                4'b1111: calculate_expected_f_logic = a;
                default: calculate_expected_f_logic = 4'bxxxx;
            endcase
        end
    endfunction

    function [4:0] calculate_expected_f_arith;
        input [3:0] s, a, b;
        input c_in;
        reg [4:0] temp;
        begin
            case(s)
                4'b0000: temp = {1'b0, a} + 5'b0_1111 + c_in;                         // A - 1 / A
                4'b0001: temp = {1'b0, (a & b)} + 5'b0_1111 + c_in;                   // (A&B) - 1 / (A&B)
                4'b0010: temp = {1'b0, (a & ~b)} + 5'b0_1111 + c_in;                  // (A&~B) - 1 / (A&~B)
                4'b0011: temp = 5'b0_1111 + c_in;                                     // -1 / 0
                4'b0100: temp = {1'b0, a} + {1'b0, a} + {1'b0, ~b} + c_in;            // A + (A + ~B) [+1]
                4'b0101: temp = {1'b0, (a & b)} + {1'b0, a} + {1'b0, ~b} + c_in;      // (A&B) + (A + ~B) [+1]
                4'b0110: temp = {1'b0, a} + {1'b0, ~b} + c_in;                         // A - B - 1 / A - B
                4'b0111: temp = {1'b0, a} + {1'b0, ~b} + c_in;                         // A + ~B [+1]
                4'b1000: temp = {1'b0, a} + {1'b0, a} + {1'b0, b} + c_in;              // A + (A + B) [+1]
                4'b1001: temp = {1'b0, a} + {1'b0, b} + c_in;                          // A + B [+1]
                4'b1010: temp = {1'b0, (a & ~b)} + {1'b0, a} + {1'b0, b} + c_in;       // (A&~B) + (A + B) [+1]
                4'b1011: temp = {1'b0, a} + {1'b0, b} + c_in;                          // A + B [+1]
                4'b1100: temp = {1'b0, a} + {1'b0, a} + c_in;                          // A + A [+1]
                4'b1101: temp = {1'b0, (a & b)} + {1'b0, a} + c_in;                    // (A&B) + A [+1]
                4'b1110: temp = {1'b0, (a & ~b)} + {1'b0, a} + c_in;                   // (A&~B) + A [+1]
                4'b1111: temp = {1'b0, a} + 5'b0_0000 + c_in;                          // A [+1]
                default: temp = 5'bxxxxx;
            endcase
            calculate_expected_f_arith = temp;
        end
    endfunction

    function calculate_expected_cout;
        input [3:0] s;
        input [4:0] result;
        input m;
        begin
            if (m == 1'b1) begin
                calculate_expected_cout = 1'b0; // No modo logico, cout e sempre 0
            end else begin
                case(s)
                    4'b0000, 4'b0010, 4'b0011, 4'b0110, 4'b0111, 4'b1011:
                        calculate_expected_cout = ~result[4];
                    default:
                        calculate_expected_cout = result[4];
                endcase
            end
        end
    endfunction

    function calculate_expected_p;
        input [3:0] s, a, b;
        input m;
        reg [4:0] r0, r1;
        begin
            if (m == 1'b1) calculate_expected_p = 1'b0; else begin
                r0 = calculate_expected_f_arith(s, a, b, 1'b0);
                r1 = calculate_expected_f_arith(s, a, b, 1'b1);
                calculate_expected_p = r1[4] & ~r0[4];
            end
        end
    endfunction

    function calculate_expected_g;
        input [3:0] s, a, b;
        input m;
        reg [4:0] r0;
        begin
            if (m == 1'b1) calculate_expected_g = 1'b1; else begin
                r0 = calculate_expected_f_arith(s, a, b, 1'b0);
                calculate_expected_g = r0[4];
            end
        end
    endfunction

    task verify_operation;
        input [3:0] s_val, a_val, b_val;
        input m_val, c_in_val;
    reg [4:0] result_arith;
        begin
            s = s_val; a = a_val; b = b_val; m = m_val; c_in = c_in_val;
            #5;
            total_tests = total_tests + 1;
            if (m == 1'b1) begin
                expected_f = calculate_expected_f_logic(s, a, b);
                expected_cout = 1'b0; expected_p = 1'b0; expected_g = 1'b1;
            end else begin
                result_arith = calculate_expected_f_arith(s, a, b, c_in);
                expected_f = result_arith[3:0];
                expected_cout = calculate_expected_cout(s, result_arith, m);
        expected_p = calculate_expected_p(s, a, b, m);
        expected_g = calculate_expected_g(s, a, b, m);
            end
        expected_eq = (a == b);
        test_pass = (f === expected_f) && (c_out === expected_cout) && 
            (p === expected_p) && (g === expected_g) && (a_eq_b === expected_eq);
            $display("| %s | %04b | %04b | %04b |  %b  | %04b |  %b  |  %b   | %b | %b |  %s  |", 
                    (m == 0) ? "ARI" : "LOG", s, a, b, c_in, f, a_eq_b, c_out, p, g,
                    test_pass ? "PASS" : "FAIL");
            if (!test_pass) begin
                errors = errors + 1;
        $display("  ERRO: Esperado: F=%04b, Cout=%b, P=%b, G=%b, A=B=%b", expected_f, expected_cout, expected_p, expected_g, expected_eq);
            end
        end
    endtask

    // Monitor contínuo (requisito)
    initial begin
        $monitor("t=%0t | M=%b S=%04b A=%04b B=%04b Cin=%b => F=%04b Cout=%b A=B=%b P=%b G=%b",
                 $time, m, s, a, b, c_in, f, c_out, a_eq_b, p, g);
    end

    initial begin
        $dumpfile("../sim/ula_74181.vcd");
        $dumpvars(0, tb_ula_74181);
        $display("=== Testbench de Validacao Completa da ULA 74181 ===");
        $display("Testando todos os 64 casos (16 funcoes x 2 modos x 2 valores de Cin)");

        errors = 0; total_tests = 0;
        $display("| Modo | S    |   A   |   B   | Cin |   F   | A=B | Cout | P | G | Status |");
        $display("|------|------|-------|-------|-----|-------|-----|------|---|---|--------|");

        for (int mode = 0; mode <= 1; mode = mode + 1) begin
            m = mode;
            $display("\n=== MODO %s (M=%0d) ===", (m == 0) ? "ARITMETICO" : "LOGICO", m);
            $display("| Modo | S    |   A   |   B   | Cin |   F   | A=B | Cout | P | G | Status |");
            $display("|------|------|-------|-------|-----|-------|-----|------|---|---|--------|");
            for (int func = 0; func < 16; func = func + 1) begin
                s = func[3:0];
                $display("\nFuncao S=%04b:", s);
                $display("| Modo | S    |   A   |   B   | Cin |   F   | A=B | Cout | P | G | Status |");
                $display("|------|------|-------|-------|-----|-------|-----|------|---|---|--------|");
                for (int cin_val = 0; cin_val <= 1; cin_val = cin_val + 1) begin
                    c_in = cin_val;
                    verify_operation(s, 4'h0, 4'h0, m, c_in);
                    verify_operation(s, 4'hF, 4'h0, m, c_in);
                    verify_operation(s, 4'hA, 4'h5, m, c_in);
                    verify_operation(s, 4'h3, 4'h3, m, c_in);
                    verify_operation(s, 4'h8, 4'h7, m, c_in);
                    verify_operation(s, 4'hF, 4'hF, m, c_in);
                end
            end
        end

        $display("\n=== Resultado Final ===");
        if (errors == 0) $display("=== TODOS OS TESTES PASSARAM! (%0d testes) ===", total_tests);
        else $display("=== %0d ERROS em %0d testes! ===", errors, total_tests);

        $display("\n=== Simulacao Concluida ===");
        #100; $finish;
    end

endmodule
